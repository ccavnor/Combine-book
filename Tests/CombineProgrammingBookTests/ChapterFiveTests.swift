//
//  ChapterFiveTests.swift
//
//
//  Created by Christopher Charles Cavnor on 3/29/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

final class ChapterFiveTests: XCTestCase {

    // prepend takes a variadic list of values and prepends
    // them to the publisher output.
    func test_prepend() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prepend(Output...)") {
            // int publisher - emits 3, 4
            let publisher = [3, 4].publisher

            // note that the output is not sorted, it prepends the last
            // prepend first; so that (-1, 0) is prepended before (1, 2)
            // because that is the call order
            publisher
                .prepend(1, 2)
                .prepend(-1, 0)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 6)
        // second prepend
        XCTAssertEqual(result[0], -1)
        XCTAssertEqual(result[1], 0)
        // first pretent
        XCTAssertEqual(result[2], 1)
        XCTAssertEqual(result[3], 2)
        // publisher values
        XCTAssertEqual(result[4], 3)
        XCTAssertEqual(result[5], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // use prepend(Sequence) to prepend any sequence to a publisher
    func test_prependSequence() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prepend(Sequence)") {
            // int publisher of 5, 6, 7
            let publisher = [5, 6, 7].publisher

            // prepend stride (6, 8, 10) then (unordered) set (1, 2) then array (3, 4)
            publisher
                .prepend([3, 4])
                .prepend(Set(1...2))
                .prepend(stride(from: 6, to: 11, by: 2))
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 10)
        // third prepend
        XCTAssertEqual(result[0], 6)
        XCTAssertEqual(result[1], 8)
        XCTAssertEqual(result[2], 10)
        // second prepend - the set values might be in order (1, 2) or (2, 1)
        XCTAssertTrue(result[3] == 1 || result[3] == 2)
        XCTAssertTrue(result[4] == 1 || result[3] == 2)
        // first pretend
        XCTAssertEqual(result[5], 3)
        XCTAssertEqual(result[6], 4)
        // publisher values
        XCTAssertEqual(result[7], 5)
        XCTAssertEqual(result[8], 6)
        XCTAssertEqual(result[9], 7)

        wait(for: [expectation], timeout: 1.0)
    }


    // prepend(Publisher) prepends the result of the first publisher
    // to the output of the second publisher.
    func test_prependPublisher() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prepend(Publisher)") {
            // create two int publishers
            let publisher1 = [3, 4].publisher
            let publisher2 = [1, 2].publisher

            // prepend publisher2 to publisher1 output
            publisher1
                .prepend(publisher2)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        XCTAssertEqual(result[3], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // this is similar to the last example, except that we are
    // going to send our input manually.
    func test_prependPublisher2() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prepend(Publisher) #2") {
            // create two int publishers, the second one we will send events to
            let publisher1 = [3, 4].publisher
            let publisher2 = PassthroughSubject<Int, Never>()

            // prepend publisher2 values to the publisher1 stream
            publisher1
                .prepend(publisher2)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)

            // manually send events
            publisher2.send(1)
            publisher2.send(2)
            // NOTE: unless you send completion, publisher1 will not emit
            // (since it cannot know that publisher2 is done sending values)
            publisher2.send(completion: .finished)
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        XCTAssertEqual(result[3], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // append takes a variadic list of values and appends them
    // to the end of the original publisher's output stream.
    func test_append() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "append(Output...)") {
            // create publisher of one value
            let publisher = [1].publisher

            // append (in order) (2, 3) then (4)
            publisher
                .append(2, 3)
                .append(4)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        XCTAssertEqual(result[3], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // like the example above, but uses a PassthroughSubject as
    // the publisher so that we will send events manually.
    func test_append2() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "append(Output...) #2") {
            // create a PassthroughSubject publisher
            let publisher = PassthroughSubject<Int, Never>()

            publisher
                .append(3, 4)
                .append(5)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)

            // NOTE: unless a completion event is sent, we only
            // get output from the sent values (nothing is appended,
            // since the publisher has no way to know that we are done
            // sending values)
            publisher.send(1)
            publisher.send(2)
            publisher.send(completion: .finished)
        }

        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        XCTAssertEqual(result[3], 4)
        XCTAssertEqual(result[4], 5)

        wait(for: [expectation], timeout: 1.0)
    }

    // append(Sequence) takes a sequence and appends it to the end
    // of the origical publisher stream
    func test_appendSequence() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "append(Sequence)") {
            // create an Int publisher of values (1, 2, 3)
            let publisher = [1, 2, 3].publisher

            publisher
                .append([4, 5]) // append (4, 5)
                .append(Set([6, 7])) // append set(6, 7)
                .append(stride(from: 8, to: 11, by: 2)) // append (8, 10)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 9)
        // original publisher values
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        // append (4, 5)
        XCTAssertTrue(result[3] == 4 || result[3] == 5)
        XCTAssertTrue(result[4] == 4 || result[4] == 5)
        // append set values (unordered) of (6, 7)
        XCTAssertEqual(result[5], 6)
        XCTAssertEqual(result[6], 7)
        // append stride values of (8, 10)
        XCTAssertEqual(result[7], 8)
        XCTAssertEqual(result[8], 10)

        wait(for: [expectation], timeout: 1.0)
    }

    // append(Publisher) takes a publisher and appends any output
    // of it to the end of the original publisher stream.
    func test_appendPublisher() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "append(Publisher)") {
            // create two Int publishers
            let publisher1 = [1, 2].publisher
            let publisher2 = [3, 4].publisher

            // append the output of publisher2 to the end of publisher1 output
            publisher1
                .append(publisher2)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        XCTAssertEqual(result[2], 3)
        XCTAssertEqual(result[3], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // switchToLatest allows you to switch publishers on the fly -
    // cancelling the pending publisher subscription.
    // It can only be used on publishers that themselves emit publishers.
    func test_switchToLatest() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "switchToLatest") {
            // create three Int publishers
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<Int, Never>()
            let publisher3 = PassthroughSubject<Int, Never>()

            // a publisher that emits a publisher: publisher1-3 can be sent through.
            let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()

            // each time the publisher changes, the previous publisher is cancelled:
            publishers
                .switchToLatest()
                .print()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)

            // send values to publisher1
            publishers.send(publisher1)
            publisher1.send(1)
            publisher1.send(2)

            // this cancels subscription to publisher1
            publishers.send(publisher2)
            publisher1.send(3) // value not emitted
            // send values to publisher2
            publisher2.send(4)
            publisher2.send(5)

            // this cancels the subscription to publisher2
            publishers.send(publisher3)
            publisher2.send(6) // value not emitted
            // send values to publisher3
            publisher3.send(7)
            publisher3.send(8)
            publisher3.send(9)

            // complete active publishers
            publisher3.send(completion: .finished)
            publishers.send(completion: .finished)

        }

        // expect [1,2,4,5,7,8,9]
        XCTAssertEqual(subscriptions.count, 1, "only one publisher is active")
        XCTAssertEqual(result.count, 7)
        // from publisher1
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)
        // from publisher2
        XCTAssertEqual(result[2], 4)
        XCTAssertEqual(result[3], 5)
        // from publisher3
        XCTAssertEqual(result[4], 7)
        XCTAssertEqual(result[5], 8)
        XCTAssertEqual(result[6], 9)

        wait(for: [expectation], timeout: 1.0)
    }

    // merge(with:) interleaves emissions from different publishers of the same type
    func test_mergeWith() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "merge(with:)") {
            // create two Int publishers
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<Int, Never>()

            // interleave publisher1 and publisher2 events as they occur
            publisher1
                .merge(with: publisher2)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    })
                .store(in: &subscriptions)

            // interleave the events between publishers
            publisher1.send(1)
            publisher1.send(2)

            publisher2.send(3)

            publisher1.send(4)

            publisher2.send(5)

            // complete the publishers else they will listen for the other
            publisher1.send(completion: .finished)
            publisher2.send(completion: .finished)
        }

        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result[0], 1, "from publisher1")
        XCTAssertEqual(result[1], 2, "from publisher1")
        XCTAssertEqual(result[2], 3, "from publisher2")
        XCTAssertEqual(result[3], 4, "from publisher1")
        XCTAssertEqual(result[4], 5, "from publisher2")

        wait(for: [expectation], timeout: 1.0)
    }

    // combineLatest allows two different event streams (of potentially
    // different types) to be emitted together. It emits a tuple of one
    // element from each publisher once the original publisher has emitted
    // at least one value.
    func test_combineLatest() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [(Int, String)]()

        example(of: "combineLatest") {
            // create publishers of different types
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<String, Never>()

            // combine the latest emissions of publisher2 with those
            // of publisher1. Up to four publishers can be used.
            publisher1
                .combineLatest(publisher2)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("P1: \($0), P2: \($1)")
                        result.append(($0, $1))
                    })
                .store(in: &subscriptions)

            // this first event will not get pushed through combineLatest, as
            // combineLatest won't start publishing tuples until every publisher
            // has emmitted at least one value.
            publisher1.send(1)

            // these will yield: (2, "a") and (2, "b")
            publisher1.send(2)
            publisher2.send("a")
            publisher2.send("b")

            // this will yield (3, "b") - because "b" is publisher2's latest
            publisher1.send(3)

            // (3, "c")
            publisher2.send("c")

            // complete publishers
            publisher1.send(completion: .finished)
            publisher2.send(completion: .finished)
        }

        // expect result: [(2, "a"), (2, "b"), (3, "b"), (3, "c")]
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0] == (2, "a"))
        XCTAssertTrue(result[1] == (2, "b"))
        XCTAssertTrue(result[2] == (3, "b"))
        XCTAssertTrue(result[3] == (3, "c"))

        wait(for: [expectation], timeout: 1.0)
    }


    // zip emits tuples of paired values (across potentially different types)
    // with the same indeces. It waits for each publisher to emit a value, then
    // emits a paired tuple for the values of publishers at the current index.
    func test_zip() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [(Int, String)]()

        example(of: "zip") {
          // create publishers of potentially different types
          let publisher1 = PassthroughSubject<Int, Never>()
          let publisher2 = PassthroughSubject<String, Never>()

          // zip outputs into paired tuples with same index
          publisher1
            .zip(publisher2)
            .sink(
                receiveCompletion: {
                    print("Completed with: \($0)")
                    expectation.fulfill()
                },
                receiveValue: {
                    print("P1: \($0), P2: \($1)")
                    result.append(($0, $1))
                })
            .store(in: &subscriptions)

          // send the events
          publisher1.send(1)
          publisher1.send(2)
          publisher2.send("a")
          publisher2.send("b")
          publisher1.send(3)
          publisher2.send("c")
          publisher2.send("d")

          // 4
          publisher1.send(completion: .finished)
          publisher2.send(completion: .finished)
        }

        // expect result: [(1, "a"), (2, "b"), (3, "c")]
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result[0] == (1, "a"))
        XCTAssertTrue(result[1] == (2, "b"))
        XCTAssertTrue(result[2] == (3, "c"))

        wait(for: [expectation], timeout: 1.0)
    }
}
