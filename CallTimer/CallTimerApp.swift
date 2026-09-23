import SwiftUI

@main
struct CallTimerApp: App {
    @StateObject private var timerManager = TimerManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timerManager)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerManager.refresh()
            }
        }
    }
}
