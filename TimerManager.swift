import Foundation
import Combine
import ActivityKit
import UIKit

class TimerManager: ObservableObject {
    @Published var esim1Minutes: Int = 9
    @Published var esim1Seconds: Int = 30
    
    @Published var esim2Minutes: Int = 14
    @Published var esim2Seconds: Int = 30
    
    @Published var isTimerRunning: Bool = false
    @Published var activeSimName: String = ""
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isWarningState: Bool = false
    
    private var timer: Timer?
    private var currentActivity: Any? // Activity<CallTimerAttributes> on iOS 16.1+
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(esim1Minutes, forKey: "esim1Minutes")
        UserDefaults.standard.set(esim1Seconds, forKey: "esim1Seconds")
        UserDefaults.standard.set(esim2Minutes, forKey: "esim2Minutes")
        UserDefaults.standard.set(esim2Seconds, forKey: "esim2Seconds")
    }
    
    func loadSettings() {
        if UserDefaults.standard.object(forKey: "esim1Minutes") != nil {
            esim1Minutes = UserDefaults.standard.integer(forKey: "esim1Minutes")
            esim1Seconds = UserDefaults.standard.integer(forKey: "esim1Seconds")
            esim2Minutes = UserDefaults.standard.integer(forKey: "esim2Minutes")
            esim2Seconds = UserDefaults.standard.integer(forKey: "esim2Seconds")
        }
    }
    
    func startCallTimer(simName: String, totalSecs: Int, phoneNumber: String = "") {
        stopTimer()
        
        self.activeSimName = simName
        self.totalSeconds = totalSecs
        self.remainingSeconds = totalSecs
        self.isTimerRunning = true
        self.isWarningState = false
        
        // 1. Schedule local push notification & vibration
        NotificationManager.shared.scheduleCallWarnings(simName: simName, totalSeconds: totalSecs)
        
        // 2. Start Live Activity for Dynamic Island (iOS 16.2+)
        if #available(iOS 16.2, *) {
            startLiveActivity(simName: simName, totalSecs: totalSecs, phoneNumber: phoneNumber)
        }
        
        // 3. Start local countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                
                if self.remainingSeconds <= 30 {
                    self.isWarningState = true
                }
                
                self.updateLiveActivity()
            } else {
                self.timeIsUp()
            }
        }
        
        // 4. Open Phone Dialer if phone number provided
        if !phoneNumber.isEmpty, let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        remainingSeconds = 0
        isWarningState = false
        NotificationManager.shared.cancelAllNotifications()
        
        if #available(iOS 16.2, *) {
            endLiveActivity()
        }
    }
    
    private func timeIsUp() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        NotificationManager.shared.playAlertVibrationAndSound()
        
        if #available(iOS 16.2, *) {
            endLiveActivity()
        }
    }
    
    // MARK: - Live Activity Support
    @available(iOS 16.2, *)
    private func startLiveActivity(simName: String, totalSecs: Int, phoneNumber: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = CallTimerAttributes(esimLabel: simName, phoneNumber: phoneNumber)
        let initialContentState = CallTimerAttributes.ContentState(
            timeRemaining: TimeInterval(totalSecs),
            totalDuration: TimeInterval(totalSecs),
            simName: simName,
            isWarning: false
        )
        
        do {
            let activity = try Activity<CallTimerAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    @available(iOS 16.2, *)
    private func updateLiveActivity() {
        guard let activity = currentActivity as? Activity<CallTimerAttributes> else { return }
        
        let updatedState = CallTimerAttributes.ContentState(
            timeRemaining: TimeInterval(remainingSeconds),
            totalDuration: TimeInterval(totalSeconds),
            simName: activeSimName,
            isWarning: isWarningState
        )
        
        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }
    
    @available(iOS 16.2, *)
    private func endLiveActivity() {
        guard let activity = currentActivity as? Activity<CallTimerAttributes> else { return }
        
        let finalState = CallTimerAttributes.ContentState(
            timeRemaining: 0,
            totalDuration: TimeInterval(totalSeconds),
            simName: activeSimName,
            isWarning: true
        )
        
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
    
    func formattedTime(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
