//
//  ChapterTwoChallenge.swift
//
//
//  Created by Christopher Charles Cavnor on 3/27/24.
//

import XCTest
import Foundation
import Combine
@testable import CombineProgrammingBook


// This is support code for the Programming Challenge
public let cards = [
    ("🂡", 11), ("🂢", 2), ("🂣", 3), ("🂤", 4), ("🂥", 5), ("🂦", 6), ("🂧", 7), ("🂨", 8), ("🂩", 9), ("🂪", 10), ("🂫", 10), ("🂭", 10), ("🂮", 10),
    ("🂱", 11), ("🂲", 2), ("🂳", 3), ("🂴", 4), ("🂵", 5), ("🂶", 6), ("🂷", 7), ("🂸", 8), ("🂹", 9), ("🂺", 10), ("🂻", 10), ("🂽", 10), ("🂾", 10),
    ("🃁", 11), ("🃂", 2), ("🃃", 3), ("🃄", 4), ("🃅", 5), ("🃆", 6), ("🃇", 7), ("🃈", 8), ("🃉", 9), ("🃊", 10), ("🃋", 10), ("🃍", 10), ("🃎", 10),
    ("🃑", 11), ("🃒", 2), ("🃓", 3), ("🃔", 4), ("🃕", 5), ("🃖", 6), ("🃗", 7), ("🃘", 8), ("🃙", 9), ("🃚", 10), ("🃛", 10), ("🃝", 10), ("🃞", 10)
]

public typealias Card = (String, Int)
public typealias Hand = [Card]

public extension Hand {
    var cardString: String {
        map { $0.0 }.joined(separator: ", ")
    }

    var points: Int {
        map { $0.1 }.reduce(0, +)
    }
}

public enum HandError: Error, CustomStringConvertible {
    case busted

    public var description: String {
        switch self {
        case .busted:
            return "\n!!! Busted !!!\n"
        }
    }
}

final class ChapterTwoChallenge: XCTestCase {

    // Run this test to execute the challenge code
    func test_Challenge() throws {
        example(of: "Create a Blackjack card dealer") {
            var subscriptions = Set<AnyCancellable>()
            let dealtHand = PassthroughSubject<Hand, HandError>()

            func deal(_ cardCount: UInt) {
                var deck = cards
                var cardsRemaining = 52
                var hand = Hand()

                for _ in 0 ..< cardCount {
                    let randomIndex = Int.random(in: 0 ..< cardsRemaining)
                    print("dealing -> \(deck[randomIndex])")
                    hand.append(deck[randomIndex])
                    deck.remove(at: randomIndex)
                    cardsRemaining -= 1
                }

                // Add code to update dealtHand here
                if hand.points > 21 {
                    dealtHand.send(completion: .failure(.busted))
                } else {
                    dealtHand.send(hand)
                }
            }

            // Add subscription to dealtHand here.
            // store in Set<AnyCancellable>() else this will go out of scope.
            dealtHand
                .sink(receiveCompletion: {
                    if case let .failure(error) = $0 {
                        print(error)
                    }
                }, receiveValue: { hand in
                    print()
                    print(hand.cardString, "for", hand.points, "points")
                    print()
                })
                .store(in: &subscriptions)

            // this kicks us off. Deal 3 cards and pray.
            deal(3)
            //deal(UInt.random(in: 0 ..< 5))
        }
    }

}
