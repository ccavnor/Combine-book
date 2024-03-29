//
//  ChapterThreeChallenge.swift
//
//
//  Created by Christopher Charles Cavnor on 3/28/24.
//

import XCTest
import Foundation
import Combine
@testable import CombineProgrammingBook

final class ChapterThreeChallenge: XCTestCase {

    func test_Challenge() throws {
        let expectation = XCTestExpectation(description: "")
        var result = [String]()
        var subscriptions = Set<AnyCancellable>()

        example(of: "Create a phone number lookup") {
            let contacts = [
                "603-555-1234": "Florent",
                "408-555-4321": "Marin",
                "217-555-1212": "Scott",
                "212-555-3434": "Shai"
            ]

            func convert(phoneNumber: String) -> Int? {
                if let number = Int(phoneNumber),
                   number < 10 {
                    return number
                }

                let keyMap: [String: Int] = [
                    "abc": 2, "def": 3, "ghi": 4,
                    "jkl": 5, "mno": 6, "pqrs": 7,
                    "tuv": 8, "wxyz": 9
                ]

                let converted = keyMap
                    .filter { $0.key.contains(phoneNumber.lowercased()) }
                    .map { $0.value }
                    .first

                return converted
            }

            func format(digits: [Int]) -> String {
                assert(digits.count == 10)
                var phone = digits.map(String.init)
                    .joined()

                phone.insert("-", at: phone.index(
                    phone.startIndex,
                    offsetBy: 3)
                )

                phone.insert("-", at: phone.index(
                    phone.startIndex,
                    offsetBy: 7)
                )

                return phone
            }

            func dial(phoneNumber: String) -> String {
                guard let contact = contacts[phoneNumber] else {
                    return "Contact not found for \(phoneNumber)"
                }

                return "Dialing \(contact) (\(phoneNumber))..."
            }

            let input = PassthroughSubject<String, Never>()

            input
                .map(convert) // convert chars into ints
                .replaceNil(with: 0) // replace nils with zero
                .collect(10) // format require 10 digits
                .map(format) // format into area code and phone number
                .map(dial) // look up the number in the contacts dictionary
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

            "0!1234567".forEach {
                input.send(String($0))
            }

            "4085554321".forEach {
                input.send(String($0))
            }

            "A1BJKLDGEH".forEach {
                input.send("\($0)")
            }

            // done
            input.send(completion: .finished)

            // test results
            XCTAssertEqual(result.count, 3)
            XCTAssertEqual(result[0], "Contact not found for 000-123-4567")
            XCTAssertEqual(result[1], "Dialing Marin (408-555-4321)...")
            XCTAssertEqual(result[2], "Dialing Shai (212-555-3434)...")

            wait(for: [expectation], timeout: 1.0)
        }
    }

}
