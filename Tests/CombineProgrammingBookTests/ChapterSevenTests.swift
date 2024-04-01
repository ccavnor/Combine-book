//
//  ChapterSevenTests.swift
//
//
//  Created by Christopher Charles Cavnor on 3/31/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

final class ChapterSevenTests: XCTestCase {

    // MARK: - Finding values

    // the min operator lets you find the minimum value that
    // is emitted by a publisher.
    // min is a greedy operator - no evaluation occurs until
    // the stream is completed.
    func test_min() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = 0

        example(of: "min") {
            // a publisher of Comparables
            let publisher = [1, -50, 246, 0].publisher

            publisher
                .print("publisher")
                .min()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("Lowest value is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, -50)
        wait(for: [expectation], timeout: 1.0)
    }

    // same as above, but uses min(by:) to provide a comparator
    // when values do not conform to Comparable
    func test_minNonComparable() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = Data()

        example(of: "min") {
            // a publisher of non-Comparable values
            let publisher = ["12345",
                             "ab",
                             "hello world"]
                .map { Data($0.utf8) } // [Data]
                .publisher // Publisher<Data, Never>

            // use min(by:) to provide a manual comparrison
            publisher
                .print("publisher")
                .min(by: { $0.count < $1.count })
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: { data in
                        let string = String(data: data, encoding: .utf8)!
                        print("Smallest data is \(string), \(data.count) bytes")
                        result = data
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, Data("ab".utf8))
        wait(for: [expectation], timeout: 1.0)
    }


    // get the max value of a publisher. Also greedy like min.
    func test_max() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "max") {
            let publisher = ["A", "F", "Z", "E"].publisher

            publisher
                .print("publisher")
                .max()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("Highest value is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "Z")
        wait(for: [expectation], timeout: 1.0)
    }

    // first returns the first value in a stream and then
    // immediately cancels. Unlike min and max it is lazy.
    func test_first() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "first") {
            let publisher = ["A", "B", "C"].publisher

            publisher
                .print("publisher")
                .first()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("First value is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "A")
        wait(for: [expectation], timeout: 1.0)
    }

    // first(where:) will emit the first value to satisfy the where predicate
    func test_firstWhere() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "first(where:)") {
            let publisher = ["J", "O", "H", "N"].publisher

            // emit the first value that satisfies the predicate.
            // note that we match with matching case.
            publisher
                .print("publisher")
                .first(where: { "Hello World".contains($0) })
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("First match is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "H")
        wait(for: [expectation], timeout: 1.0)
    }

    // last returns the last value in a stream and then
    // immediately cancels. Unlike min and max it is lazy.
    func test_last() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "last") {
            let publisher = ["A", "B", "C"].publisher

            publisher
                .print("publisher")
                .last()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("Last value is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "C")
        wait(for: [expectation], timeout: 1.0)
    }

    // output(at:) looks for a value in the output stream of a
    // publisher at the specified index.
    func test_outputAt() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "output(at:)") {
            let publisher = ["A", "B", "C"].publisher

            // emit the value at the specified index
            publisher
                .print("publisher")
                .output(at: 1)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("Value at index 1 is \($0)")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "B")
        wait(for: [expectation], timeout: 1.0)
    }

    // output(in:) emits values that are within the given range
    // of indeces.
    func test_outputIn() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [String]()

        example(of: "output(in:)") {
            let publisher = ["A", "B", "C", "D", "E"].publisher

            // emit values in range 1...3
            publisher
                .output(in: 1...3)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("Value in range: \($0)")
                        result.append($0)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, ["B","C","D"])
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Querying the publisher

    // count emits a single value - the number of values from the
    // upstream publisher. It is therefore greedy, and emits once
    // the upstream publisher is complete.
    func test_count() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = 0

        example(of: "count") {
            let publisher = ["A", "B", "C"].publisher

            // count values from publisher
            publisher
                .print("publisher")
                .count()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("I have \($0) items")
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(result, 3)
    }

    // contains will emit true and cancel the subscription if
    // the upstream publisher contains the specified value.
    // Here we test with a value that is in the published stream.
    func test_containsTrue() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = false

        example(of: "contains") {
            let publisher = ["A", "B", "C", "D", "E"].publisher
            // value to look for
            let letter = "C"

            // publisher contains C
            publisher
                .print("publisher")
                .contains(letter)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    // Same as above, but here  we test with a value
    // that is NOT in the published stream.
    func test_containsFalse() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = true

        example(of: "contains") {
            let publisher = ["A", "B", "C", "D", "E"].publisher
            // value to look for
            let letter = "F"

            // publisher does not contain F
            publisher
                .print("publisher")
                .contains(letter)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertFalse(result)
        wait(for: [expectation], timeout: 1.0)
    }

    // contains(where:) lazily matches the output of the upstream
    // publisher and returns the first match, if any, to the provided
    // predicate then cancels the subscription.
    func test_containsWhere() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = false

        example(of: "contains(where:)") {
            // Person
            struct Person {
                let id: Int
                let name: String
            }

            // create list of Person instances
            let people = [
                (123, "Shai Mishali"),
                (777, "Marin Todorov"),
                (214, "Florent Pillet")
            ]
                .map(Person.init)
                .publisher

            // match on "Marin Todorov"
            people
                .print("people")
                .contains(where: { $0.id == 800 || $0.name == "Marin Todorov" })
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    // allSatisfy takes a predicate and greedily tests that all
    // values from the upstream publisher satisy the predicate.
    func test_allSatisfy() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = true

        example(of: "allSatisfy") {
            // publisher of Int values (odd and even)
            let publisher = stride(from: 0, to: 5, by: 1).publisher

            // true when all values are even, else false
            publisher
                .print("publisher")
                .allSatisfy { $0 % 2 == 0 }
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertFalse(result)
        wait(for: [expectation], timeout: 1.0)
    }

    // reduce will iteratively accumulate a new value based on the
    // emissions of an upstream publisher.
    func test_reduce() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "reduce") {
            // publisher of strings
            let publisher = ["Hel", "lo", " ", "Wor", "ld", "!"].publisher

            // reduce by string accumulation
            publisher
                .print("publisher")
                .reduce("", +)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        result = $0
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "Hello World!")
        wait(for: [expectation], timeout: 1.0)
    }

}
