//
//  ChapterFourTests.swift
//
//
//  Created by Christopher Charles Cavnor on 3/28/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

final class ChapterFourTests: XCTestCase {

    // Filter takes a predicate closure and emits only values that
    // satisfy the predicate.
    func test_filter() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "filter") {
            // publisher that emits 10 values
            let numbers = (1...10).publisher
            // emit only numbers that are multiples of three
            numbers
                .filter { $0.isMultiple(of: 3) }
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: { n in
                        print("\(n) is a multiple of 3!")
                        result.append(n)
                    })
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0], 3)
        XCTAssertEqual(result[1], 6)
        XCTAssertEqual(result[2], 9)

        wait(for: [expectation], timeout: 1.0)
    }

    // removeDuplicates creates a stream of unique values
    func test_removeDuplicates() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "removeDuplicates") {
            // create a publisher that emits an array of strings
            let words = "hey hey there! want to listen to mister mister ?"
                .components(separatedBy: " ")
                .publisher
            // apply removeDuplicates operator to publisher
            words
                .removeDuplicates()
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result += "\($0) "
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "hey there! want to listen to mister ? ")
        wait(for: [expectation], timeout: 1.0)
    }

    // compactMap removes the nil values of Optional from a stream
    func test_compactMap() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Float]()

        example(of: "compactMap") {
            // create a string publisher
            let strings = ["a", "1.24", "3",
                           "def", "45", "0.23"].publisher

            // casting as float returns nil iff Float's init
            // cannot convert the string into a float
            strings
                .compactMap { Float($0) }
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0], 1.24)
        XCTAssertEqual(result[1], 3.0)
        XCTAssertEqual(result[2], 45.0)
        XCTAssertEqual(result[3], 0.23)

        wait(for: [expectation], timeout: 1.0)
    }

    // ignoreOutput - ignore all emitted values if you only care
    // about completion.
    func test_ignoreOutput() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "ignoreOutput") {
            // create a publisher that emits ints
            let numbers = (1...10_000).publisher

            // ignore/suppress all output
            numbers
                .ignoreOutput()
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 0, "all output is ignored, as expected")
        wait(for: [expectation], timeout: 1.0)
    }


    // first emits only the first value from a publisher that
    // matches a given predicate (if any)
    func test_first() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "first(where:)") {
            // create an int publisher
            let numbers = (1...9).publisher

            // get the first even value
            numbers
                .print("numbers")
                .first(where: { $0 % 2 == 0 })
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], 2)

        wait(for: [expectation], timeout: 1.0)
    }

    // last emits only the final value from a publisher that
    // matches a given predicate (if any)
    func test_last() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "last(where:)") {
            let numbers = PassthroughSubject<Int, Never>()

            numbers
                .last(where: { $0 % 2 == 0 })
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)

            numbers.send(1)
            numbers.send(2)
            numbers.send(3)
            numbers.send(4)
            numbers.send(5)
            numbers.send(completion: .finished)
        }

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0], 4)

        wait(for: [expectation], timeout: 1.0)
    }

    // drop the first n emitted value from a publisher
    func test_dropFirst() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "dropFirst") {
            // int publisher
            let numbers = (1...10).publisher

            // drop the first 8 values and emit rest
            numbers
                .dropFirst(8)
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 9)
        XCTAssertEqual(result[1], 10)

        wait(for: [expectation], timeout: 1.0)
    }

    // dropWhile starts emitting values once the associated
    // predicate has been matched. Note that as soon as the
    // predicate returns true, no further values are tested.
    func test_dropWhile() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "drop(while:)") {
            // create an int publisher
            let numbers = (1...10).publisher

            // once the first value that is divisible by 5 is
            // seen, all following values are emitted
            numbers
                .drop(while: {
                    print("x")
                    return $0 % 5 != 0
                })
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result.count, 6)
        XCTAssertEqual(result[0], 5)
        XCTAssertEqual(result[1], 6)
        XCTAssertEqual(result[2], 7)
        XCTAssertEqual(result[3], 8)
        XCTAssertEqual(result[4], 9)
        XCTAssertEqual(result[5], 10)

        wait(for: [expectation], timeout: 1.0)
    }

    // drop(untilOutputFrom:) skips all output from a primary
    // publisher until a secondary publisher starts to emit
    // its values.
    func test_dropUntilOutputFrom() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "drop(untilOutputFrom:)") {
            let isReady = PassthroughSubject<Void, Never>()
            // represents user taps.
            let taps = PassthroughSubject<Int, Never>()

            // taps publisher won't emit values until isReady
            // publisher passes its first value.
            taps
                .drop(untilOutputFrom: isReady)
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print("isReady: \($0)")
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)

            // taps emissions are ignored until isReady emits (at tap 3)
            (1...5).forEach { n in
                print("tapping... \(n)")
                taps.send(n)

                if n == 3 {
                    isReady.send()
                }
            }

            // this is fulfill the testing expectation
            taps.send(completion: .finished)
        }

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 4)
        XCTAssertEqual(result[1], 5)

        wait(for: [expectation], timeout: 1.0)
    }


    // takes values until some condition is met
    func test_prefix() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prefix") {
            // create int publisher
            let numbers = (1...10).publisher

            // accept only the first two values, then the publisher completes
            numbers
                .prefix(2)
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

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)

        wait(for: [expectation], timeout: 1.0)
    }

    // prefix(while:) allows values to be emitted while the predicate is true
    func test_prefixWhile() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prefix(while:)") {
            // create int publisher
            let numbers = (1...10).publisher

            // accept ints less than 3, then the publisher completes
            numbers
                .prefix(while: { $0 < 3 })
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

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)

        wait(for: [expectation], timeout: 1.0)
    }

    // prefix(untilOutputFrom:) accepts values until a secondary publisher emits
    func test_prefixUntilOutputFrom() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "prefix(untilOutputFrom:)") {
            let isReady = PassthroughSubject<Void, Never>()
            // represents user taps
            let taps = PassthroughSubject<Int, Never>()

            // accept
            taps
                .prefix(untilOutputFrom: isReady)
                .sink(
                    receiveCompletion: {
                        print("Completed with: \($0)")
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result.append($0)
                    }
                )
                .store(in: &subscriptions)

            // taps emissions are ignored after isReady emits (at tap 2)
            (1...5).forEach { n in
                taps.send(n)

                if n == 2 {
                    isReady.send()
                }
            }
        }

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0], 1)
        XCTAssertEqual(result[1], 2)

        wait(for: [expectation], timeout: 1.0)
    }
}
