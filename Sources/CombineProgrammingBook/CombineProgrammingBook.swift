import Foundation
import Combine

// This is the example runner for tests
public func example(of description: String, action: () -> Void) {
    print("\n--- Example of: ", description, " ---")
    action()
}
