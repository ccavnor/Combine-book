//
//  ChapterFourChallenge.swift
//  
//
//  Created by Christopher Charles Cavnor on 3/29/24.
//

import XCTest
import Combine
import Foundation
@testable import CombineProgrammingBook

final class ChapterFourChallenge: XCTestCase {

    func test_Challenge() throws {
        let expectation = XCTestExpectation(description: "")
        var result = [Int]()
        var subscriptions = Set<AnyCancellable>()

        example(of: "Challenge: Filter all the things") {
          let numbers = (1...100).publisher

          numbers
            .dropFirst(50) // now have 50-100
            .prefix(20) // only keep 50-70
            .filter { $0 % 2 == 0 } // filter out even numbers
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

        // test results: expect [52, 54, 56 58, 60, 62, 64, 66, 68, 70]
        XCTAssertEqual(result.count, 10)
        XCTAssertEqual(result[0], 52)
        XCTAssertEqual(result[1], 54)
        XCTAssertEqual(result[2], 56)
        XCTAssertEqual(result[3], 58)
        XCTAssertEqual(result[4], 60)
        XCTAssertEqual(result[5], 62)
        XCTAssertEqual(result[6], 64)
        XCTAssertEqual(result[7], 66)
        XCTAssertEqual(result[8], 68)
        XCTAssertEqual(result[9], 70)

        wait(for: [expectation], timeout: 1.0)



    }


}
