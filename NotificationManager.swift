import Foundation
import UserNotifications
import AudioToolbox
import AVFoundation

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleCallWarnings(simName: String, totalSeconds: Int) {
        // Clear previous pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let warningTime = totalSeconds - 30 // Warning 30 seconds before limit
        
        // 1. Warning Notification (30s before limit)
        if warningTime > 5 {
            let content1 = UNMutableNotificationContent()
            content1.title = "⚠️ Sắp hết thời gian cuộc gọi!"
            content1.body = "Cuộc gọi trên \(simName) chỉ còn 30 giây nữa là chạm mốc giới hạn."
            content1.sound = UNNotificationSound.default
            
            let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(warningTime), repeats: false)
            let req1 = UNNotificationRequest(identifier: "call_warning_30s", content: content1, trigger: trigger1)
            UNUserNotificationCenter.current().add(req1)
        }
        
        // 2. Final Time's Up Notification
        let content2 = UNMutableNotificationContent()
        content2.title = "🛑 ĐÃ ĐẾN GIỚI HẠN THỜI GIAN!"
        content2.body = "Cuộc gọi trên \(simName) đã đạt mốc tối đa (\(totalSeconds / 60) phút). Vui lòng dập máy!"
        content2.sound = UNNotificationSound.defaultCritical
        
        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(totalSeconds), repeats: false)
        let req2 = UNNotificationRequest(identifier: "call_times_up", content: content2, trigger: trigger2)
        UNUserNotificationCenter.current().add(req2)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func playAlertVibrationAndSound() {
        // Play system vibration and alert chime
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1005) // Standard alert sound
    }
    
    // Allow notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        playAlertVibrationAndSound()
        completionHandler([.banner, .sound, .list, .badge])
    }
}
