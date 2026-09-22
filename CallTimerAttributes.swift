import Foundation
import ActivityKit

// Structure defining the attributes for Live Activity on Dynamic Island & Lock Screen
public struct CallTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state updated during the timer countdown
        public var timeRemaining: TimeInterval
        public var totalDuration: TimeInterval
        public var simName: String
        public var isWarning: Bool
    }

    // Static attributes set when starting the activity
    public var esimLabel: String // e.g. "eSIM 1 (Công việc)" or "eSIM 2 (Cá nhân)"
    public var phoneNumber: String
}
