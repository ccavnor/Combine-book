import XCTest
import Combine
@testable import CombineProgrammingBook

final class CombineProgrammingBookTests: XCTestCase {

    func testNotificationCenterPublisher() throws {
        // set up an expectation for async response
        let expectation = XCTestExpectation(description: "wait for notification")

        example(of: "Publisher") {
            let myNotification = Notification.Name("MyNotification")

            let publisher = NotificationCenter.default
                .publisher(for: myNotification, object: nil)

            let center = NotificationCenter.default

            let observer = center.addObserver(
                forName: myNotification,
                object: nil,
                queue: nil) { notification in
                    // Fulfill the expectation.
                    expectation.fulfill()
                    print("Notification received!")
                }

            center.post(name: myNotification, object: nil)
            center.removeObserver(observer)
        }
        // Wait for the expectation to fulfill or time out.
        wait(for: [expectation], timeout: 1.0)
    }

    func testNotificationCenterSubscriber() throws {
        let expectation = XCTestExpectation(description: "wait for notification")
        example(of: "Subscriber") {
            let myNotification = Notification.Name("MyNotification")
            let center = NotificationCenter.default
            let publisher = center.publisher(for: myNotification, object: nil)

            let subscription = publisher
                .sink { _ in
                    expectation.fulfill()
                    print("Notification received from a publisher!")
                }

            center.post(name: myNotification, object: nil)
            subscription.cancel()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // Just outputs a single value and a completion notice
    func testJust() throws {
        var count = 0
        let expectation = XCTestExpectation(description: "wait for both subscribers")
        example(of: "Just") {
            // create a publisher with just one value
            let just = Just("Hello world!")

            // create a subscription to the publisher and receive value
            _ = just
                .sink(
                    receiveCompletion: {
                        print("Received completion", $0)
                        count += 1
                    },
                    receiveValue: {
                        print("Received value", $0)
                    })

            // create another subscription to the publisher and receive value
            _ = just
                .sink(
                    receiveCompletion: {
                        print("Received completion (another)", $0)
                        count += 1
                    },
                    receiveValue: {
                        print("Received value (another)", $0)
                    })
        }
        if count == 2 {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // test assign(to:on:) to bind an object via KeyPath
    func test_assign_to_on() throws {
        let expectation = XCTestExpectation(description: "assign via keypath")

        example(of: "assign(to:on:)") {
            // will assign to value in SomeObject
            class SomeObject {
                var values = [String]()
                var value: String = "" {
                    didSet {
                        //print(value)
                        values.append(value)
                    }
                }
            }

            let object = SomeObject()
            let publisher = ["Hello", "world!"].publisher

            // assign via keypath
            _ = publisher
                .assign(to: \.value, on: object)

            print(object.values)
            if object.values.contains("Hello") && object.values.contains("world!") {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // republishing with assign(to:)
    func test_assign_to() throws {
        let expectation = XCTestExpectation(description: "")
        example(of: "assign(to:)") {
            // using the @Published property wrapper creates a publisher
            class SomeObject {
                @Published var value = 0
            }

            let object = SomeObject()

            // using $ gains access to underlying publisher and subscribes to it.
            // NOTE: if we don't assign to a var, this subscriber goes out of scope
            // immediately and prints only the initial assigned value.
            let f = object.$value
                .sink {
                    print($0)
                }

            // create publisher of numbers and assign each value value publisher as inOut
            (0..<10).publisher
                .assign(to: &object.$value)

            // test for last in series
            if object.value == 9 {
                expectation.fulfill()
                f.cancel()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // test custom subscriber
    func test_CustomSubsriber() throws {
        example(of: "Custom Subscriber") {
            // create a publisher of ints
            let publisher = (1...6).publisher

            // a custom subscriber - implements the Subscriber protocol
            final class IntSubscriber: Subscriber {
                typealias Input = Int // receives Int values
                typealias Failure = Never // never receives a failure

                // called by publisher
                func receive(subscription: Subscription) {
                    // subscriber is willing to receive up to three values upon subscription
                    subscription.request(.max(3))
                }

                // print each value as it is received
                func receive(_ input: Int) -> Subscribers.Demand {
                    print("Received value", input)
                    //return .none // equivalent to max(0) - indicates that subscriber will not adjust its demand
                    //return .unlimited // send all events, followed by completion event
                    return .max(1) // increase the max by one each time an event is received
                }

                // receive completion event
                func receive(completion: Subscribers.Completion<Never>) {
                    print("Received completion", completion)
                }
            }

            // the publisher won't publish anything without a subscriber
            let subscriber = IntSubscriber()
            publisher.subscribe(subscriber)
        }
    }

    // Futures greedily return a promise, which is executed as a closure
    // NOTE: This test takes 3 seconds to complete.
    func test_Future() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()

        example(of: "Future") {
            func futureIncrement(
                integer: Int,
                afterDelay delay: TimeInterval) -> Future<Int, Never> {

                    Future<Int, Never> { promise in
                        print("This is printed greedily")
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            promise(.success(integer + 1))
                        }
                    }
                }

            // 1
            let future = futureIncrement(integer: 1, afterDelay: 3)

            // 2
            future
                .sink(receiveCompletion: {
                    print("First completion:", $0)
                    expectation.fulfill()
                },
                      receiveValue: { print("First value:", $0) })
                .store(in: &subscriptions)

            //            // the future keeps no state, so running this will return the same value
            //            future
            //                .sink(receiveCompletion: { print("Second completion:", $0) },
            //                      receiveValue: { print("Second value:", $0) })
            //                .store(in: &subscriptions)
        }
        wait(for: [expectation], timeout: 5.0)
    }

    // A Subject is a go-between to allow non-Combine code to send
    // values to Combine subscribers. Subjects are publishers AND
    // subscribers.
    func test_PassThroughSubject() throws {
        example(of: "PassthroughSubject") {
            // define custom error type
            enum MyError: Error {
                case test
            }

            // custom subscriber that receives Strings and MyError error type
            final class StringSubscriber: Subscriber {
                typealias Input = String
                typealias Failure = MyError

                func receive(subscription: Subscription) {
                    subscription.request(.max(2))
                }

                func receive(_ input: String) -> Subscribers.Demand {
                    print("Received value", input)
                    // adjust the demand dynamically
                    return input == "World" ? .max(1) : .none // new max is 3
                }

                func receive(completion: Subscribers.Completion<MyError>) {
                    print("Received completion", completion)
                }
            }

            // create an instance of the custom subscriber
            let subscriber = StringSubscriber()

            // create a PassthroughSubject with same types
            let subject = PassthroughSubject<String, MyError>()

            // publish the subscriber to the subject
            subject.subscribe(subscriber)

            // create another subscription using sink
            let secondSubscription = subject
                .sink(
                    receiveCompletion: { completion in
                        print("Received completion (sink)", completion)
                    },
                    receiveValue: { value in
                        print("Received value (sink)", value)
                    }
                )

            // both subscribers get this
            subject.send("Hello")
            subject.send("World")

            // cancel second (sink) subscriber
            secondSubscription.cancel()

            // only first subscriber picks this up
            subject.send("Still there?")

            // cancel first subscriber
            subject.send(completion: .failure(MyError.test))
            subject.send(completion: .finished)
            // neither subscriber gets this
            subject.send("How about another one?")
        }

    }

    // Another way to bridge imperative code with Combine declarative
    // code. This stores multiple subscriptions in a collection of
    // type AnyCancellable. New subscribers immediately get the latest
    // value that was published.
    func test_CurrentValueSubject() throws {
        example(of: "CurrentValueSubject") {
            // create a subscription set
            var subscriptions = Set<AnyCancellable>()

            // push Ints, starting with zero.
            let subject = CurrentValueSubject<Int, Never>(0)

            // create a subscription to the subject
            subject
            //.print() // prints events to STDOUT
                .sink(
                    receiveCompletion: { completion in
                        print("First subscription completion ->", completion)
                    },
                    receiveValue: { print("First subscription: \($0)") })
            // store each subscription in the subscription set
                .store(in: &subscriptions)

            subject.send(1)
            subject.send(2)

            // you can ask a CurrentValueSubject for its
            // value at any time
            print("the current value is \(subject.value)")
            XCTAssertEqual(subject.value, 2)

            // in addition to calling send, you can assign
            subject.value = 3
            //print(subject.value)
            XCTAssertEqual(subject.value, 3)

            // a second subscription gets the last added value
            // as its first received value
            subject
            //.print() // prints events to STDOUT
                .sink(
                    receiveCompletion: { completion in
                        print("Second subscription completion ->", completion)
                    },
                    receiveValue: {
                        print("Second subscription:", $0)
                        XCTAssertEqual(subject.value, 3)
                    })
                .store(in: &subscriptions)

            // NOTE: since Set<AnyCancellable> is in scope, a cancel
            // event will automatically be sent to CurrentValueSubject.
            // However, we can still send a completion event if we want
            // the Subject's receiveCompletion closure to be executed:
            subject.send(completion: .finished)
        }
    }

    // Adjusting the demand in Subscriber.receive(_:) is additive
    func test_DynamicallyAdjustDemand() throws {
        //let expectation = XCTestExpectation(description: "Dynamically adjusting Demand")

        example(of: "Dynamically adjusting Demand") {
            final class IntSubscriber: Subscriber {
                typealias Input = Int
                typealias Failure = Never
                let expectation = XCTestExpectation(description: "Dynamically adjusting Demand")
                var values = [Int]()

                func receive(subscription: Subscription) {
                    subscription.request(.max(2))
                }

                func receive(_ input: Int) -> Subscribers.Demand {
                    print("Received value", input)
                    values.append(input)

                    switch input {
                    case 1:
                        return .max(2) // the new max is 4 (previous was 2)
                    case 3:
                        return .max(1) // the new max is 5
                    default:
                        return .none // more than 5 events is prevented
                    }
                }

                func receive(completion: Subscribers.Completion<Never>) {
                    print("Received completion", completion)
                    expectation.fulfill()
                }
            }

            let subscriber = IntSubscriber()
            let subject = PassthroughSubject<Int, Never>()
            subject.subscribe(subscriber)

            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(4)
            subject.send(5)
            subject.send(6) // will not be received due to Subscribers.Demand == .none

            // this will call expectation.fulfill()
            subject.send(completion: .finished)
            XCTAssertTrue(subscriber.values.count == 5)
            XCTAssertFalse(subscriber.values.contains(6), "Subscriber should be choked before this value is received")

            wait(for: [subscriber.expectation], timeout: 1.0)
        }
    }

    // Type erasure uses the Publisher protocol
    // (https://developer.apple.com/documentation/combine/publisher)
    // to limit a subscriber to only receiving events without being able to send events.
    // A publisher delivers elements to one or more Subscriber instances.
    func test_TypeErasure() throws {
        example(of: "Type erasure") {
            // create a subscription set
            var subscriptions = Set<AnyCancellable>()

            // create a passthrough subject
            let subject = PassthroughSubject<Int, Never>()

            // create a type-erased publisher from that subject:
            // type is: AnyPublisher<Int, Never>
            // AnyPublisher is a type-erased struct that conforms to the Publisher protocol.
            let publisher = subject.eraseToAnyPublisher()

            // subscribe to type-erased publisher
            publisher
                .sink(receiveValue: { print($0) })
                .store(in: &subscriptions)

            // we can still send values through the passthrough subject
            subject.send(0)
            //publisher.send(1) // AnyPublisher does not support send
        }
    }


    // This example does not work as the book specifies. I think that
    // Task goes out of scope before subject?
    func test_AsyncAwait() throws {
        let expectation = XCTestExpectation(description: "")

        example(of: "async/await") {
            // create the subject
            let subject = CurrentValueSubject<Int, Never>(0)

            // uncomment this to show that values are actually published
            //let f = subject.sink(receiveValue: {print($0)})

            // create an asynchronous task to await subject values
            Task {
                for await element in subject.values {
                    print("Element: \(element)")
                }
                print("Completed.")
                expectation.fulfill()
            }

            // send values to the subject
            subject.send(1)
            subject.send(2)
            subject.send(3)
            subject.send(completion: .finished)

            wait(for: [expectation], timeout: 1.0)
        }
    }

    //    func test_() throws {
    //        let expectation = XCTestExpectation(description: "")
    //        expectation.fulfill()
    //        wait(for: [expectation], timeout: 1.0)
    //    }
}

