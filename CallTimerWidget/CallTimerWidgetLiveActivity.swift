import ActivityKit
import WidgetKit
import SwiftUI

@main
struct CallTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        CallTimerWidgetLiveActivity()
    }
}

private enum AlertPhase {
    case normal, warning, finished

    // Staleness is driven by the app: staleDate = warning time while counting,
    // then staleDate = end time once the warning update has been sent.
    init(_ context: ActivityViewContext<CallTimerAttributes>) {
        if context.state.isFinished || (context.state.isWarning && context.isStale) {
            self = .finished
        } else if context.state.isWarning || context.isStale {
            self = .warning
        } else {
            self = .normal
        }
    }

    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .yellow
        case .finished: return .red
        }
    }

    var title: String {
        switch self {
        case .normal: return "ĐANG GỌI"
        case .warning: return "SẮP HẾT GIỜ"
        case .finished: return "HẾT GIỜ – DẬP MÁY!"
        }
    }
}

private struct CountdownText: View {
    let context: ActivityViewContext<CallTimerAttributes>

    var body: some View {
        let start = context.attributes.startDate
        let end = max(start, context.state.endDate)
        if context.state.isFinished {
            Text("00:00")
        } else {
            Text(timerInterval: start...end, countsDown: true, showsHours: false)
        }
    }
}

private struct CountdownBar: View {
    let context: ActivityViewContext<CallTimerAttributes>
    let color: Color

    var body: some View {
        let start = context.attributes.startDate
        let end = max(start, context.state.endDate)
        ProgressView(timerInterval: start...end, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .tint(color)
    }
}

struct CallTimerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CallTimerAttributes.self) { context in
            // Lock Screen / Notification Center banner
            let phase = AlertPhase(context)
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: phase == .finished ? "phone.down.fill" : "timer")
                        .font(.title2)
                        .foregroundColor(phase.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.simName)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(phase.title) · Mốc \(formatDuration(context.attributes.totalSeconds))")
                            .font(.caption)
                            .foregroundColor(phase.color)
                    }

                    Spacer()

                    CountdownText(context: context)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110, alignment: .trailing)
                        .foregroundColor(phase.color)
                }
                CountdownBar(context: context, color: phase.color)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let phase = AlertPhase(context)
            return DynamicIsland {
                // Expanded (long-press on the Dynamic Island)
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.simName).lineLimit(1)
                    } icon: {
                        Image(systemName: "simcard.fill")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(phase.color)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(phase.title)
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(phase.color)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Còn lại")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            CountdownText(context: context)
                                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                                .monospacedDigit()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(phase.color)
                        }
                        CountdownBar(context: context, color: phase.color)
                        Text("Mốc tối đa \(formatDuration(context.attributes.totalSeconds)) · Cảnh báo trước \(context.attributes.warningSeconds)s")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(phase.color)
            } compactTrailing: {
                CountdownText(context: context)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 48)
                    .foregroundColor(phase.color)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(phase.color)
            }
        }
    }
}
