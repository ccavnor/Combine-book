//
//  ChapterSixTests.swift
//
//
//  Created by Christopher Charles Cavnor on 3/29/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

final class ChapterSixTests: XCTestCase {

    // the delay operator time-shifts a sequence of values by the specified amount.
    func test_delay() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var source = [Date]()
        var delay = [Date]()

        let valuesPerSecond = 1.0
        let delayInSeconds = 1.5

        // subject that gets fed values from Timer events.
        let sourcePublisher = PassthroughSubject<Date, Never>()

        // delays values from sourcePublisher and emit them on main scheduler.
        let delayedPublisher = sourcePublisher.delay(for: .seconds(delayInSeconds), scheduler: DispatchQueue.main)

        // delivers an event (one per second) on main thread and autoconnects.
        // Feed the values to sourcePublisher.
        let subscription: () = Timer
            .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
            .autoconnect()
            .subscribe(sourcePublisher)
            .store(in: &subscriptions)

        sourcePublisher
            .sink(
                receiveValue: {
                    print("source ==> \($0)")
                    source.append(Date.now)
                })
            .store(in: &subscriptions)

        delayedPublisher
            .sink(
                receiveCompletion: {
                    print("Completed with: \($0)")
                    expectation.fulfill()
                },
                receiveValue: {
                    print("delay ==> \($0)")
                    delay.append(Date.now)
                    // complete after initial send
                    sourcePublisher.send(completion: .finished)
                })
            .store(in: &subscriptions)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        // check that delay was (close to) 1.5 seconds
        XCTAssertEqual(delay[0] - source[0], 1.5, accuracy: 0.1)
    }

    // collect values from a publisher at a specified time interval.
    // we test that the expected number of events in collectTimeStride
    // are grouped by the collect operator.
    func test_collect() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var collected = [Date]()

        // one event per second is emitted, so we should collect four
        // events in collectTimeStride=4
        let valuesPerSecond = 1.0
        let collectTimeStride = 4

        // source publisher emits values from timer
        let sourcePublisher = PassthroughSubject<Date, Never>()

        // collect received values during strides of collectTimeStride and
        // emit as an array of grouped values on DispatchQueue.main
        let collectedPublisher = sourcePublisher
            .print("collectedPublisher")
        // collect by time using .byTime variant
            .collect(.byTime(DispatchQueue.main, .seconds(collectTimeStride)))
        // collect collects an array of dates. We use the built-in
        // collection (array) publisher to publish to flatMap
            .flatMap { dates in dates.publisher }

        collectedPublisher
            .sink(
                receiveCompletion: {
                    print("Completed with: \($0)")
                    expectation.fulfill()
                },
                receiveValue: {
                    print("collect ==> \($0)")
                    collected.append($0)
                    // complete after initial send
                    sourcePublisher.send(completion: .finished)
                })
            .store(in: &subscriptions)

        let subscription = Timer
            .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
            .autoconnect()
            .subscribe(sourcePublisher)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(collected.count, collectTimeStride, "we should collect the number of events in a single stride")
    }


    // same as above, but here we let collectMaxCount limit the number of collected
    // events per stride to 2.
    func test_collect2() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var collected = [Date]()

        let valuesPerSecond = 1.0
        let collectTimeStride = 4
        let collectMaxCount = 2

        let sourcePublisher = PassthroughSubject<Date, Never>()

        let collectedPublisher = sourcePublisher
        // uses the .byTimeOrCount variant with max count of collectMaxCount
            .collect(.byTimeOrCount(DispatchQueue.main, .seconds(collectTimeStride), collectMaxCount))
            .flatMap { dates in dates.publisher }

        collectedPublisher
            .print("collectedPublisher")
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    collected.append($0)
                    // complete after first collection of two events.
                    // NOTE: there are actually two values in this call;
                    // they are implicitly flatMapped for receiveValue
                    sourcePublisher.send(completion: .finished)
                })
            .store(in: &subscriptions)

        Timer
            .publish(every: 1.0 / valuesPerSecond, on: .main, in: .common)
            .autoconnect()
            .subscribe(sourcePublisher)
            .store(in: &subscriptions)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(collected.count, collectMaxCount, "the number of captured events per stride is limited by collectMaxCount")
    }

    // debounce works like collect, but over a set time interval.
    // this tests the collection of a string with simulated user
    // typing.
    func test_debounce() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var timesCalled = 0
        var result = ""

        // source publisher that emits strings
        let subject = PassthroughSubject<String, Never>()

        // tell debounce to wait for one second after emission of subject
        let debounced = subject
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
        // share ensures that multiple subscribers get exactly the same
        // values at the same time
            .share()

        // the letters as they are typed
        subject
            .sink { string in
                print("+\(deltaTime)s: Subject emitted: \(string)")
            }
            .store(in: &subscriptions)

        // the debounced input
        debounced
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    print("+\(deltaTime)s: Debounced emitted: \($0)")
                    timesCalled += 1
                    result = $0
                })
            .store(in: &subscriptions)

        // feeds subject at an interval specified by typingHelloWorld.
        // it sends a completion event, so this test won't
        subject.feed(with: typingHelloWorld)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(timesCalled, 2, "debounced receiveValue only called per word (letters collected in 1 second), not letter")
        XCTAssertEqual(result, "Hello World")
    }


    // test throttle with lastest = false
    // throttle sends the first value since the last throttle interval.
    // throttle begins throttling after the first emitted value.
    // if no value is received since the last throttle, throttle emits no values
    func test_throttleLatestFalse() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""
        var timesCalled = 0

        let throttleDelay = 1.0

        // source publisher emits strings
        let subject = PassthroughSubject<String, Never>()

        // if latest == false: emits the earlies value from subject during interval (throttleDelay).
        // if latest == true: emits the latest value from subject during interval (throttleDelay).
        let throttled = subject
            .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: false)
            .share()

        // the letters as they are typed
        subject
            .sink { string in
                print("+\(deltaTime)s: Subject emitted: \(string)")
            }
            .store(in: &subscriptions)

        // the throttled input
        throttled
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    print("+\(deltaTime)s: Throttled emitted: \($0)")
                    timesCalled += 1
                    result = $0
                })
            .store(in: &subscriptions)

        // feeds subject at an interval specified by typingHelloWorld (last event sent at 2.5s).
        // it sends a completion event, so this test won't
        subject.feed(with: typingHelloWorld)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(timesCalled, 4, "throttle called after initial value, then once per second")
        XCTAssertEqual(result, "Hello Wo", "this was the opening value in the last throttle window")
    }

    // test throttle with lastest = true
    // throttle sends the first value since the last throttle interval.
    // throttle begins throttling after the first emitted value.
    // if no value is received since the last throttle, throttle emits no values
    func test_throttleLatestTrue() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""
        var timesCalled = 0

        let throttleDelay = 1.0

        // source publisher emits strings
        let subject = PassthroughSubject<String, Never>()

        // if latest == false: emits the earlies value from subject during interval (throttleDelay).
        // if latest == true: emits the latest value from subject during interval (throttleDelay).
        let throttled = subject
            .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
            .share()

        // the letters as they are typed
        subject
            .sink { string in
                print("+\(deltaTime)s: Subject emitted: \(string)")
            }
            .store(in: &subscriptions)

        // the throttled input
        throttled
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    print("+\(deltaTime)s: Throttled emitted: \($0)")
                    timesCalled += 1
                    result = $0
                })
            .store(in: &subscriptions)

        // feeds subject at an interval specified by typingHelloWorld (last event sent at 2.5s).
        // it sends a completion event, so this test won't
        subject.feed(with: typingHelloWorld)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(timesCalled, 4, "throttle called after initial value, then once per second")
        XCTAssertEqual(result, "Hello World", "this was the closing value in the last throttle window")
    }

    // timeout will send a completion event (.finished or .failure) if it receives no events
    // within its time out threshold
    func test_timeout() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        let timeoutThreshold = 2
        var eventCount = 0
        var timeoutCount = 0

        // the timeout error to throw
        enum TimeoutError: Error {
            case timedOut
        }

        // source publisher that emits nothing
        let subject = PassthroughSubject<Void, TimeoutError>()

        // time out within timeoutThreshold without the upsteam publisher publishing any value
        let timedOutSubject = subject.timeout(.seconds(timeoutThreshold), scheduler: DispatchQueue.main, customError: { .timedOut })

        // the throttled input
        timedOutSubject
            .sink(
                receiveCompletion: {
                    if $0 == .failure(.timedOut) {
                        print("timeout occurred at \(Date.now)")
                        timeoutCount += 1
                        expectation.fulfill()
                    }
                    // if timedOutSubject didn't use a customError it would just get a completion event
                    else if $0 == .finished {
                        print("timeout occurred at \(Date.now)")
                    }
                },
                receiveValue: {
                    print("event received at \(Date.now)")
                    eventCount += 1
                })
            .store(in: &subscriptions)

        // send three events, one second apart (below timeoutThreshold)
        var hold = 0.0
        for _ in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                subject.send()
            }
            hold += 1.0
        }

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(eventCount, 3, "three events called within timeout interval")
        XCTAssertEqual(timeoutCount, 1, "timeout interval hit")
    }

    // measureInterval simply measures the time between two consecutive events that a publisher emits
    func test_MeasureInterval() {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var measureSubjectTime = 0.0
        var measureSubject2Time = 0.0

        let subject = PassthroughSubject<String, Never>()

        let measureSubject = subject.measureInterval(using: DispatchQueue.main)
        let measureSubject2 = subject.measureInterval(using: RunLoop.main)

        subject.sink {
            print("+\(deltaTime)s: Subject emitted: \($0)")
            if $0 == "Hello World" {
                expectation.fulfill()
            }
        }
        .store(in: &subscriptions)

        measureSubject.sink {
            let t = Double($0.magnitude) / 1_000_000_000.0
            print("+\(deltaTime)s: Measure emitted: \(t)")
            measureSubjectTime = t
        }
        .store(in: &subscriptions)

        measureSubject2.sink {
            print("+\(deltaTime)s: Measure2 emitted: \($0)")
            measureSubject2Time = $0.magnitude
        }
        .store(in: &subscriptions)

        subject.feed(with: typingHelloWorld)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        // assert that measureInterval is same within tolerance
        XCTAssertEqual(measureSubjectTime, measureSubject2Time, accuracy: 0.01)
    }
}
