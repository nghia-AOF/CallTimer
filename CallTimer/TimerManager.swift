import Foundation
import Combine
import ActivityKit
import UIKit

struct SimProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var minutes: Int
    var seconds: Int
    var colorIndex: Int

    var totalSeconds: Int { minutes * 60 + seconds }
}

struct CallSession: Codable, Equatable {
    var simName: String
    var phoneNumber: String
    var colorIndex: Int
    var startDate: Date
    var endDate: Date
    var totalSeconds: Int
    var warningSeconds: Int

    var warningDate: Date { endDate.addingTimeInterval(-Double(warningSeconds)) }
}

final class TimerManager: ObservableObject {
    enum Phase { case idle, running, warning, finished }

    @Published var sims: [SimProfile] = [] { didSet { saveSettings() } }
    @Published var warningSeconds: Int = 30 { didSet { saveSettings() } }

    @Published private(set) var session: CallSession?
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var phase: Phase = .idle

    private var ticker: AnyCancellable?
    private var currentActivity: Activity<CallTimerAttributes>?
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sims = "sims.v2"
        static let warningSeconds = "warningSeconds"
        static let session = "activeSession"
    }

    init() {
        loadSettings()
        restoreSession()
    }

    // MARK: - Settings persistence

    private func loadSettings() {
        if let data = defaults.data(forKey: Keys.sims),
           let saved = try? JSONDecoder().decode([SimProfile].self, from: data),
           !saved.isEmpty {
            sims = saved
        } else {
            // Migrate values saved by v1.0 (eSIM 1 / eSIM 2 only), else use defaults.
            let hasV1 = defaults.object(forKey: "esim1Minutes") != nil
            sims = [
                SimProfile(name: "eSIM 1 (Công việc)",
                           minutes: hasV1 ? defaults.integer(forKey: "esim1Minutes") : 9,
                           seconds: hasV1 ? defaults.integer(forKey: "esim1Seconds") : 30,
                           colorIndex: 0),
                SimProfile(name: "eSIM 2 (Cá nhân)",
                           minutes: hasV1 ? defaults.integer(forKey: "esim2Minutes") : 14,
                           seconds: hasV1 ? defaults.integer(forKey: "esim2Seconds") : 30,
                           colorIndex: 1)
            ]
        }
        if defaults.object(forKey: Keys.warningSeconds) != nil {
            warningSeconds = defaults.integer(forKey: Keys.warningSeconds)
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(sims) {
            defaults.set(data, forKey: Keys.sims)
        }
        defaults.set(warningSeconds, forKey: Keys.warningSeconds)
    }

    func addSim() {
        let n = sims.count + 1
        sims.append(SimProfile(name: "eSIM \(n)", minutes: 10, seconds: 0, colorIndex: (n - 1) % 5))
    }

    func removeSim(id: UUID) {
        guard sims.count > 1 else { return }
        sims.removeAll { $0.id == id }
    }

    // MARK: - Countdown

    func startCall(sim: SimProfile, phoneNumber: String) {
        guard sim.totalSeconds > 0 else { return }
        stop()

        let now = Date()
        let newSession = CallSession(
            simName: sim.name,
            phoneNumber: phoneNumber,
            colorIndex: sim.colorIndex,
            startDate: now,
            endDate: now.addingTimeInterval(Double(sim.totalSeconds)),
            totalSeconds: sim.totalSeconds,
            warningSeconds: min(warningSeconds, sim.totalSeconds)
        )
        session = newSession
        persistSession()

        NotificationManager.shared.scheduleCallAlerts(
            simName: newSession.simName,
            totalSeconds: newSession.totalSeconds,
            warningSeconds: newSession.warningSeconds,
            endDate: newSession.endDate
        )

        // The Live Activity must be requested while the app is still in the foreground,
        // i.e. before handing over to the Phone app.
        startLiveActivity(newSession)
        startTicker()
        tick(playAlerts: true)

        dial(phoneNumber)
    }

    /// Stops the countdown and removes all alerts / Live Activity.
    func stop() {
        ticker?.cancel()
        ticker = nil
        NotificationManager.shared.cancelScheduledAlerts()
        endLiveActivity(immediately: true)
        session = nil
        remainingSeconds = 0
        phase = .idle
        persistSession()
    }

    /// Called when the app returns to the foreground: re-sync with the wall clock.
    func refresh() {
        guard session != nil else {
            endOrphanedActivities()
            return
        }
        if phase != .finished { startTicker() }
        tick(playAlerts: true)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick(playAlerts: true) }
    }

    private func tick(playAlerts: Bool) {
        guard let s = session else { return }
        let now = Date()
        remainingSeconds = max(0, Int(ceil(s.endDate.timeIntervalSince(now))))

        // Only play in-app sounds if we cross the threshold "live" (not when
        // reopening the app long after the notification already rang).
        func isFresh(_ date: Date) -> Bool { playAlerts && now.timeIntervalSince(date) < 3 }

        if remainingSeconds == 0 {
            if phase != .finished {
                phase = .finished
                ticker?.cancel()
                ticker = nil
                if isFresh(s.endDate) { NotificationManager.shared.startAlarm() }
                updateLiveActivity(isWarning: true, isFinished: true)
                endLiveActivity(immediately: false)
            }
        } else if remainingSeconds <= s.warningSeconds {
            if phase != .warning {
                phase = .warning
                if isFresh(s.warningDate) { NotificationManager.shared.playWarningAlert() }
                updateLiveActivity(isWarning: true, isFinished: false)
            }
        } else if phase != .running {
            phase = .running
        }
    }

    private func dial(_ number: String) {
        let allowed = CharacterSet(charactersIn: "+0123456789")
        let cleaned = String(number.unicodeScalars.filter { allowed.contains($0) })
        guard !cleaned.isEmpty, let url = URL(string: "tel:\(cleaned)") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Session persistence (survives the app being killed during a call)

    private func persistSession() {
        if let s = session, let data = try? JSONEncoder().encode(s) {
            defaults.set(data, forKey: Keys.session)
        } else {
            defaults.removeObject(forKey: Keys.session)
        }
    }

    private func restoreSession() {
        guard let data = defaults.data(forKey: Keys.session),
              let s = try? JSONDecoder().decode(CallSession.self, from: data) else {
            endOrphanedActivities()
            return
        }
        // Forget sessions that ended long ago.
        if Date().timeIntervalSince(s.endDate) > 10 * 60 {
            session = s
            stop()
            return
        }
        session = s
        currentActivity = Activity<CallTimerAttributes>.activities.first
        endOrphanedActivities()
        if s.endDate > Date() { startTicker() }
        tick(playAlerts: false)
    }

    // MARK: - Live Activity (Dynamic Island & Lock Screen)

    private func startLiveActivity(_ s: CallSession) {
        endOrphanedActivities(keepCurrent: false)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = CallTimerAttributes(
            simName: s.simName,
            phoneNumber: s.phoneNumber,
            startDate: s.startDate,
            totalSeconds: s.totalSeconds,
            warningSeconds: s.warningSeconds
        )
        let isWarning = s.warningDate <= Date()
        let state = CallTimerAttributes.ContentState(endDate: s.endDate, isWarning: isWarning, isFinished: false)
        // When staleDate passes the widget re-renders with isStale = true, which it
        // uses to switch colors even though the app is suspended during the call.
        let staleDate = isWarning ? s.endDate : s.warningDate

        do {
            currentActivity = try Activity<CallTimerAttributes>.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: staleDate),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    private func updateLiveActivity(isWarning: Bool, isFinished: Bool) {
        guard let activity = currentActivity, let s = session else { return }
        let state = CallTimerAttributes.ContentState(endDate: s.endDate, isWarning: isWarning, isFinished: isFinished)
        let staleDate: Date? = isFinished ? nil : s.endDate
        Task {
            await activity.update(ActivityContent(state: state, staleDate: staleDate))
        }
    }

    private func endLiveActivity(immediately: Bool) {
        guard let activity = currentActivity else { return }
        currentActivity = nil
        let endDate = session?.endDate ?? Date()
        let state = CallTimerAttributes.ContentState(endDate: endDate, isWarning: true, isFinished: true)
        let policy: ActivityUIDismissalPolicy = immediately ? .immediate : .after(Date().addingTimeInterval(60))
        Task {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: policy)
        }
    }

    private func endOrphanedActivities(keepCurrent: Bool = true) {
        for activity in Activity<CallTimerAttributes>.activities {
            if keepCurrent, activity.id == currentActivity?.id { continue }
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
