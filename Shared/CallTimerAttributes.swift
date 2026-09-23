import Foundation
import ActivityKit

// Shared between the app (starts/updates the Live Activity) and the widget
// extension (renders it on the Dynamic Island & Lock Screen).
struct CallTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        // The countdown is rendered by the system from endDate, so it keeps
        // ticking even while the app is suspended during the phone call.
        var endDate: Date
        var isWarning: Bool
        var isFinished: Bool
    }

    var simName: String
    var phoneNumber: String
    var startDate: Date
    var totalSeconds: Int
    var warningSeconds: Int
}

func formatDuration(_ seconds: Int) -> String {
    let s = max(0, seconds)
    return String(format: "%02d:%02d", s / 60, s % 60)
}
