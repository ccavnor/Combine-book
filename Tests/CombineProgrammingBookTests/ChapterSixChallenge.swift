//
//  ChapterSixChallenge.swift
//
//
//  Created by Christopher Charles Cavnor on 3/31/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

// sample data!
let samples: [(TimeInterval, Int)] = [
    (0.05, 67), (0.10, 111), (0.15, 109), (0.20, 98), (0.25, 105), (0.30, 110), (0.35, 101),
    (1.50, 105), (1.55, 115),
    (2.60, 99), (2.65, 111), (2.70, 111), (2.75, 108), (2.80, 33)
]

// feed the samples using their specified timeInterval.
// sends a completion event when done.
public func startFeeding<S>(subject: S) where S: Subject, S.Output == Int {
    var lastDelay: TimeInterval = 0
    for entry in samples {
        lastDelay = entry.0
        DispatchQueue.main.asyncAfter(deadline: .now() + entry.0) {
            subject.send(entry.1)
        }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay + 0.5) {
        subject.send(completion: .finished)
    }
}

final class ChapterSixChallenge: XCTestCase {

    func test_Challenge() throws {
        let expectation = XCTestExpectation(description: "")
        var subscriptions = Set<AnyCancellable>()
        var result = ""

        // A subject you get values from
        let subject = PassthroughSubject<Int, Never>()

        // collect in 0.5s batches and stringify each unicode value
        let strings = subject
            .print("strings")
            .collect(.byTime(DispatchQueue.main, .seconds(0.5)))
            .map { array in
                String(array.map { Character(Unicode.Scalar($0)!) })
            }

        // if the interval is > 0.9s, inject an emoji
        let spaces = subject.measureInterval(using: DispatchQueue.main)
            .map { interval in
                interval > 0.9 ? "👏" : ""
            }

        // merge the strings and spaces subjects, filtering
        // out empty strings
        strings
            .print("merged")
            .merge(with: spaces)
            .filter { !$0.isEmpty }
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: {
                    result += $0
                })
            .store(in: &subscriptions)

        // start injecting events using samples above
        startFeeding(subject: subject)

        // max time to wait
        wait(for: [expectation], timeout: 5.0)

        XCTAssertEqual(result, "Combine👏is👏cool!")
    }

}
