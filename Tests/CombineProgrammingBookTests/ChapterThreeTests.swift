//
//  ChapterThreeTests.swift
//
//
//  Created by Christopher Charles Cavnor on 3/27/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

final class ChapterThreeTests: XCTestCase {

    // Chapter three - Operators
    // NOTE: each Combine Operator returns a Publisher that will transmit upstream errors
    // (if any) downstream.

    // the Collect operator
    func test_Collect() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        let result1 = ["A", "B"]
        let result2 = ["C", "D"]
        let result3 = ["E"]
        var results = [[String]]()

        ["A", "B", "C", "D", "E"].publisher
            .collect(2)
            .sink(
                receiveCompletion: {
                    print($0)
                    expectation.fulfill()
                },
                receiveValue: {
                    print($0)
                    results.append($0)
                })
            .store(in: &subscriptions)

        XCTAssertEqual(results, [result1, result2, result3])
        wait(for: [expectation], timeout: 1.0)
    }

    // the map operator
    func test_Map() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var results = [String]()
        example(of: "map") {
            // number formatter to spell out each number
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut

            // integer publisher
            [123, 4, 56].publisher
            // map the formatter over the numbers to get string output
                .map {
                    formatter.string(for: NSNumber(integerLiteral: $0)) ?? ""
                }.sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        results.append($0)
                    })
                .store(in: &subscriptions)

            XCTAssertEqual(results.count, 3)
            XCTAssertEqual(results[0], "one hundred twenty-three")
            XCTAssertEqual(results[1], "four")
            XCTAssertEqual(results[2], "fifty-six")

            wait(for: [expectation], timeout: 1.0)
        }

    }

    public struct Coordinate {
        public let x: Int
        public let y: Int

        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }

    public func quadrantOf(x: Int, y: Int) -> String {
        var quadrant = ""

        switch (x, y) {
        case (1..., 1...):
            quadrant = "1"
        case (..<0, 1...):
            quadrant = "2"
        case (..<0, ..<0):
            quadrant = "3"
        case (1..., ..<0):
            quadrant = "4"
        default:
            quadrant = "boundary"
        }

        return quadrant
    }

    // the map operator - using KeyPaths
    func test_MapKeyPaths() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var results = [String]()
        example(of: "mapping key paths") {
            // create a publisher of Coordinate that will never emit an error
            let publisher = PassthroughSubject<Coordinate, Never>()

            // create a subscriber to the Coordinate publisher
            publisher
            // map into x and y properties of Coordinate using KeyPaths
                .map(\.x, \.y)
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: { [self] x, y in
                        // gather the quadrantOf the x and y values
                        let q = quadrantOf(x: x, y: y)
                        print("The coordinate at (\(x), \(y)) is in quadrant", q)
                        results.append(q)
                    })
                .store(in: &subscriptions)

            // send coordinated through the publisher
            publisher.send(Coordinate(x: 10, y: -8))
            publisher.send(Coordinate(x: 0, y: 5))
            publisher.send(completion: .finished)

            XCTAssertEqual(results.count, 2)
            XCTAssertEqual(results[0], "4")
            XCTAssertEqual(results[1], "boundary")

            wait(for: [expectation], timeout: 1.0)
        }
    }

    // several operators have counterparts with the "try" prefix. They
    // take a throwing closure and pass any upstream error to that closure.
    func test_tryMap() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        example(of: "tryMap") {
            // publisher of one value
            Just("Directory name that does not exist")
            // user tryMap to attempt to get contents of non-existent directory (throws)
                .tryMap { try FileManager.default.contentsOfDirectory(atPath: $0) }
            // only the completion event will be received
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: { print($0) })
                .store(in: &subscriptions)

            wait(for: [expectation], timeout: 1.0)
        }
    }

    // FlatMap flattens the emissions of multiple upstream publishers
    // into a single downstream publisher.
    func test_FlatMap() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        example(of: "flatMap") {
            // takes an array of Int values that represent ASCII codes
            // and returns a type-erased publisher of strings
            func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
                // publish a single string that is the interpreted ASCII code
                Just(
                    codes
                        .compactMap { code in
                            guard (32...255).contains(code) else { return nil }
                            return String(UnicodeScalar(code) ?? " ")
                        }
                    // join into one string
                        .joined()
                )
                // type erase the publisher to match function return type
                .eraseToAnyPublisher()
            }

            // create a publisher of ASCII codes and collect into an array
            [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
                .publisher
                .collect()
            // flatMap the array using the decode function
                .flatMap(decode)
            // subscribe to this publisher and print out the result
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        result = $0
                        print(result)
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, "Hello, World!")
        wait(for: [expectation], timeout: 1.0)
    }

    // replaceNil replaces a nil value in an optional type with
    // the specified value
    func test_replaceNil() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [String]()

        example(of: "replaceNil") {
            // create publisher from array of optional strings
            ["A", nil, "C"].publisher
                .eraseToAnyPublisher()
                .replaceNil(with: "-") // replace nil with "-"
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
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result, ["A", "-", "C"])
        wait(for: [expectation], timeout: 1.0)
    }


    // the replaceEmpty(with:) operator replaces (inserts) a value
    // if the publisher completes without emitting a value
    func test_replaceEmptyWith() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = 0

        example(of: "replaceEmpty(with:)") {
            // immediately emits a completion event
            let empty = Empty<Int, Never>()

            // subscribe to prulisher and record (inserted) value
            empty
                .replaceEmpty(with: 1)
                .sink(
                    receiveCompletion: {
                        print($0)
                        expectation.fulfill()
                    },
                    receiveValue: {
                        print($0)
                        result = $0
                    }
                )
                .store(in: &subscriptions)
        }

        XCTAssertEqual(result, 1)
        wait(for: [expectation], timeout: 1.0)
    }

    // scan provides the current value emitted by a publisher to
    // a closure, along with the previous value returned by that closure.
    func test_scan() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = [Int]()

        example(of: "scan") {
            // generate a random int between -10 and 10
            var dailyGainLoss: Int { .random(in: -10...10) }

            // generate fake stock values
            let august2019 = (0..<22)
                .map { _ in dailyGainLoss }
                .publisher

            // scan (starting with 50) and add each daily change
            // to the running stock price (monotonically increasing)
            august2019
                .scan(50) { last, current in
                    max(0, last + current)
                }
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

        XCTAssertEqual(result.count, 22)
        wait(for: [expectation], timeout: 1.0)
    }

}
