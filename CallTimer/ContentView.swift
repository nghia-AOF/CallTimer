import SwiftUI
import ActivityKit

private let simColors: [Color] = [.blue, .purple, .teal, .pink, .indigo]

private func simColor(_ index: Int) -> Color {
    simColors[((index % simColors.count) + simColors.count) % simColors.count]
}

struct ContentView: View {
    @EnvironmentObject private var timerManager: TimerManager
    @State private var phoneNumberToCall: String = ""
    @FocusState private var focusedField: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerView

                    if !ActivityAuthorizationInfo().areActivitiesEnabled {
                        liveActivityHint
                    }

                    if let session = timerManager.session {
                        ActiveTimerCard(session: session)
                            .transition(.scale.combined(with: .opacity))
                    }

                    phoneInputCard

                    ForEach($timerManager.sims) { $sim in
                        SimConfigCard(
                            sim: $sim,
                            canDelete: timerManager.sims.count > 1,
                            hasPhoneNumber: !phoneNumberToCall.isEmpty,
                            onDelete: {
                                withAnimation { timerManager.removeSim(id: sim.id) }
                            },
                            onStart: {
                                focusedField = false
                                withAnimation {
                                    timerManager.startCall(sim: sim, phoneNumber: phoneNumberToCall)
                                }
                            }
                        )
                    }

                    Button {
                        withAnimation { timerManager.addSim() }
                    } label: {
                        Label("Thêm SIM / eSIM", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                    }

                    warningSettingCard

                    guidanceFooter
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("CallTimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { focusedField = false }
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.blue)
            Text("Quản lý Thời lượng Cuộc gọi")
                .font(.title2)
                .fontWeight(.bold)
            Text("Đặt mốc thời gian riêng cho từng SIM · Đếm ngược trên Dynamic Island")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
    }

    private var liveActivityHint: some View {
        Label("Live Activities đang tắt. Vào Cài đặt › CallTimer › bật \"Hoạt động trực tiếp\" để thấy đếm ngược trên Dynamic Island.",
              systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundColor(.orange)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(12)
    }

    private var phoneInputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Số điện thoại cần gọi (tùy chọn)", systemImage: "phone.arrow.up.right")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                TextField("Nhập số để vừa gọi vừa đếm ngược...", text: $phoneNumberToCall)
                    .keyboardType(.phonePad)
                    .focused($focusedField)
                    .padding()
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)

                if !phoneNumberToCall.isEmpty {
                    Button { phoneNumberToCall = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }

            Text("Để trống nếu bạn tự gọi bằng ứng dụng Điện thoại: bấm Bắt đầu đếm ngay khi cuộc gọi được kết nối.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var warningSettingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(value: $timerManager.warningSeconds, in: 10...120, step: 5) {
                Label("Cảnh báo trước mốc: \(timerManager.warningSeconds) giây", systemImage: "bell.badge.fill")
                    .font(.subheadline)
            }
            Text("Cảnh báo vàng (rung nhẹ + chuông) khi còn \(timerManager.warningSeconds) giây; cảnh báo đỏ (rung liên tục + chuông lớn) khi chạm mốc.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var guidanceFooter: some View {
        VStack(spacing: 6) {
            Label("Hướng dẫn sử dụng", systemImage: "info.circle")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            Text("Chọn đúng thẻ SIM bạn sẽ dùng để gọi rồi bấm nút. Đếm ngược hiển thị trên **Dynamic Island** và **Màn hình khóa**. iOS không cho ứng dụng khác chọn SIM thay bạn: khi gọi, iPhone dùng đường dây mặc định hoặc đường dây bạn đã dùng gần nhất với số đó.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }
}

// MARK: - Active timer

private struct ActiveTimerCard: View {
    @EnvironmentObject private var timerManager: TimerManager
    let session: CallSession

    private var color: Color {
        switch timerManager.phase {
        case .finished: return .red
        case .warning: return .orange
        default: return simColor(session.colorIndex)
        }
    }

    private var badge: String {
        switch timerManager.phase {
        case .finished: return "🛑 HẾT GIỜ – DẬP MÁY"
        case .warning: return "⚠️ SẮP HẾT GIỜ"
        default: return "ĐANG ĐẾM NGƯỢC"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(session.simName, systemImage: "phone.fill.badge.checkmark")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(badge)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.18))
                    .cornerRadius(8)
            }

            Text(formatDuration(timerManager.remainingSeconds))
                .font(.system(size: 56, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
                .contentTransition(.numericText())

            ProgressView(value: Double(session.totalSeconds - timerManager.remainingSeconds),
                         total: Double(max(1, session.totalSeconds)))
                .tint(color)

            HStack {
                Text("Mốc: \(formatDuration(session.totalSeconds))")
                Spacer()
                if !session.phoneNumber.isEmpty {
                    Text("Số: \(session.phoneNumber)")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Button {
                withAnimation { timerManager.stop() }
            } label: {
                Label(timerManager.phase == .finished ? "Đóng" : "Dừng đếm ngược",
                      systemImage: timerManager.phase == .finished ? "checkmark" : "stop.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(timerManager.phase == .finished ? Color.gray : Color.red)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.5), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - SIM configuration

private struct SimConfigCard: View {
    @Binding var sim: SimProfile
    let canDelete: Bool
    let hasPhoneNumber: Bool
    let onDelete: () -> Void
    let onStart: () -> Void

    private var accent: Color { simColor(sim.colorIndex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "simcard.fill")
                    .foregroundColor(accent)
                    .font(.title3)
                TextField("Tên SIM", text: $sim.name)
                    .font(.headline)
                    .textInputAutocapitalization(.sentences)
                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phút").font(.caption).foregroundColor(.secondary)
                    Picker("Phút", selection: $sim.minutes) {
                        ForEach(0..<181, id: \.self) { m in
                            Text("\(m) phút").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giây").font(.caption).foregroundColor(.secondary)
                    Picker("Giây", selection: $sim.seconds) {
                        ForEach(0..<60, id: \.self) { s in
                            Text("\(s) giây").tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
            }

            Button(action: onStart) {
                Label(hasPhoneNumber
                        ? "Gọi & đếm ngược \(formatDuration(sim.totalSeconds))"
                        : "Bắt đầu đếm \(formatDuration(sim.totalSeconds))",
                      systemImage: hasPhoneNumber ? "phone.fill" : "timer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sim.totalSeconds > 0 ? accent : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(sim.totalSeconds == 0)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ContentView().environmentObject(TimerManager())
}
