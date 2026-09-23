import Foundation
import UserNotifications
import AudioToolbox
import UIKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let warningId = "calltimer.warning"
    private let endIds = ["calltimer.end.0", "calltimer.end.1", "calltimer.end.2"]
    private var alarmTimer: Timer?
    private var alarmRemaining = 0

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if !granted {
                print("Notification permission denied.")
            }
        }
    }

    // Local notifications fire even when the screen is off or the app is suspended
    // during the call, so they are the primary alert mechanism.
    func scheduleCallAlerts(simName: String, totalSeconds: Int, warningSeconds: Int, endDate: Date) {
        cancelScheduledAlerts()

        let untilEnd = max(1, endDate.timeIntervalSinceNow)
        let untilWarning = untilEnd - Double(warningSeconds)

        if untilWarning >= 1 {
            let content = UNMutableNotificationContent()
            content.title = "⚠️ \(simName): còn \(warningSeconds) giây"
            content.body = "Cuộc gọi sắp chạm mốc \(formatDuration(totalSeconds)). Chuẩn bị kết thúc cuộc gọi."
            content.sound = .default
            content.threadIdentifier = "calltimer"
            add(id: warningId, content: content, after: untilWarning)
        }

        // Several notifications a few seconds apart act as a repeating "red" alarm.
        for (i, id) in endIds.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "🛑 \(simName): ĐÃ HẾT \(formatDuration(totalSeconds))"
            content.body = "Đã chạm mốc thời gian gọi tối đa. Vui lòng dập máy ngay!"
            content.sound = .default
            content.threadIdentifier = "calltimer"
            add(id: id, content: content, after: untilEnd + Double(i * 4))
        }
    }

    func cancelScheduledAlerts() {
        let ids = [warningId] + endIds
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
        stopAlarm()
    }

    private func add(id: String, content: UNNotificationContent, after interval: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // MARK: - In-app alerts (used while the app is in the foreground)

    /// Yellow alert: light haptic + short chime.
    func playWarningAlert() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        AudioServicesPlaySystemSound(1007) // tri-tone
    }

    /// Red alert: repeated vibration + loud alarm sound until stopped.
    func startAlarm(repeatCount: Int = 8) {
        stopAlarm()
        alarmRemaining = repeatCount
        fireAlarm()
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.fireAlarm()
        }
    }

    private func fireAlarm() {
        guard alarmRemaining > 0 else {
            stopAlarm()
            return
        }
        alarmRemaining -= 1
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlayAlertSound(1005) // alarm
    }

    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
    }

    // MARK: - UNUserNotificationCenterDelegate

    // In the foreground the app plays its own sounds, so only show the banner.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }
}
