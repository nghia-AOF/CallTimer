import ActivityKit
import WidgetKit
import SwiftUI

public struct CallTimerWidgetLiveActivity: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallTimerAttributes.self) { context in
            // 1. Lock Screen / Notification Center Banner View
            HStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.title)
                    .foregroundColor(context.state.isWarning ? .red : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.esimLabel)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(context.state.isWarning ? "⚠️ Sắp chạm mốc tối đa!" : "Cuộc gọi đang diễn ra...")
                        .font(.subheadline)
                        .foregroundColor(context.state.isWarning ? .red : .secondary)
                }
                
                Spacer()
                
                Text(timerString(context.state.timeRemaining))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(context.state.isWarning ? .red : .blue)
            }
            .padding()
            .activityBackgroundTint(Color(UIColor.secondarySystemGroupedBackground))
            .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            // 2. Dynamic Island Views (iPhone 15 Pro Max)
            DynamicIsland {
                // Expanded View (When user long-presses Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.esimLabel, systemImage: "phone.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(context.state.isWarning ? .red : .blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isWarning ? "CẢNH BÁO" : "ĐANG GỌI")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(context.state.isWarning ? .red : .green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Còn lại:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(timerString(context.state.timeRemaining))
                                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                .foregroundColor(context.state.isWarning ? .red : .blue)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact View Left
                Image(systemName: "timer")
                    .foregroundColor(context.state.isWarning ? .red : .blue)
            } compactTrailing: {
                // Compact View Right
                Text(timerString(context.state.timeRemaining))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(context.state.isWarning ? .red : .blue)
            } minimal: {
                // Minimal View (When multiple activities are active)
                Image(systemName: "timer")
                    .foregroundColor(context.state.isWarning ? .red : .blue)
            }
        }
    }
    
    private func timerString(_ seconds: TimeInterval) -> String {
        let sec = Int(seconds)
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}
