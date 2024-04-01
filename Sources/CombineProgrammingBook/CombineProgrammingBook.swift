import Foundation
import Combine

// This is the example runner for tests
public func example(of description: String, action: () -> Void) {
    print("\n--- Example of: ", description, " ---")
    action()
}

// chapter six sources
//-------------------------------------------------------------------

//===============
// data.swift
//===============
/// Sample data we use to feed a subject, simulating a user typing "Hello World"
public let typingHelloWorld: [(TimeInterval, String)] = [
  (0.0, "H"),
  (0.1, "He"),
  (0.2, "Hel"),
  (0.3, "Hell"),
  (0.5, "Hello"),
  (0.6, "Hello "),
  (2.0, "Hello W"),
  (2.1, "Hello Wo"),
  (2.2, "Hello Wor"),
  (2.4, "Hello Worl"),
  (2.5, "Hello World")
]

@available(macOS 10.15, *)
public extension Subject where Output == String {

  /// A function that can feed delayed values to a subject for testing and simulation purposes
  func feed(with data: [(TimeInterval, String)]) {
    var lastDelay: TimeInterval = 0
    for entry in data {
      lastDelay = entry.0
      DispatchQueue.main.asyncAfter(deadline: .now() + entry.0) { [unowned self] in
        self.send(entry.1)
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay + 1.5) { [unowned self] in
      self.send(completion: .finished)
    }
  }
}

//=================
// deltaTime.swift
//=================
let start = Date()
let deltaFormatter: NumberFormatter = {
  let f = NumberFormatter()
  f.negativePrefix = ""
  f.minimumFractionDigits = 1
  f.maximumFractionDigits = 1
  return f
}()

/// A simple delta time formatter suitable for use in playground pages: start date is initialized every time the page starts running
public var deltaTime: String {
  return deltaFormatter.string(for: Date().timeIntervalSince(start))!
}
