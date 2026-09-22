import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @State private var phoneNumberToCall: String = ""
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Banner
                        headerView
                        
                        // Active Timer Card (If running)
                        if timerManager.isTimerRunning {
                            activeTimerCard
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Quick Phone Number Input
                        phoneInputCard
                        
                        // eSIM 1 Configuration Card
                        simConfigCard(
                            title: "eSIM 1 (SIM Chính / Công việc)",
                            iconName: "antenna.radiowaves.left.and.right",
                            accentColor: .blue,
                            minutes: $timerManager.esim1Minutes,
                            seconds: $timerManager.esim1Seconds
                        ) {
                            let totalSecs = (timerManager.esim1Minutes * 60) + timerManager.esim1Seconds
                            timerManager.saveSettings()
                            timerManager.startCallTimer(simName: "eSIM 1", totalSecs: totalSecs, phoneNumber: phoneNumberToCall)
                        }
                        
                        // eSIM 2 Configuration Card
                        simConfigCard(
                            title: "eSIM 2 (SIM Phụ / Cá nhân)",
                            iconName: "simcard.fill",
                            accentColor: .purple,
                            minutes: $timerManager.esim2Minutes,
                            seconds: $timerManager.esim2Seconds
                        ) {
                            let totalSecs = (timerManager.esim2Minutes * 60) + timerManager.esim2Seconds
                            timerManager.saveSettings()
                            timerManager.startCallTimer(simName: "eSIM 2", totalSecs: totalSecs, phoneNumber: phoneNumberToCall)
                        }
                        
                        // How it works / Guidance
                        guidanceFooter
                    }
                    .padding()
                }
            }
            .navigationTitle("CallTimer iOS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                NotificationManager.shared.requestAuthorization()
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
            
            Text("Hỗ trợ Dynamic Island & Thông báo cảnh báo tự động")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
    }
    
    private var activeTimerCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label(timerManager.activeSimName, systemImage: "phone.fill.badge.checkmark")
                    .font(.headline)
                    .foregroundColor(timerManager.isWarningState ? .red : .primary)
                Spacer()
                Text(timerManager.isWarningState ? "⚠️ SẮP HẾT GIỜ" : "ĐANG ĐẾM NGUỒN")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(timerManager.isWarningState ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(timerManager.formattedTime(timerManager.remainingSeconds))
                .font(.system(size: 52, weight: .heavy, design: .monospaced))
                .foregroundColor(timerManager.isWarningState ? .red : .blue)
            
            ProgressView(value: Double(timerManager.totalSeconds - timerManager.remainingSeconds), total: Double(timerManager.totalSeconds))
                .tint(timerManager.isWarningState ? .red : .blue)
            
            Button(action: {
                withAnimation {
                    timerManager.stopTimer()
                }
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Dừng Đếm Ngược")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var phoneInputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Số điện thoại gọi (Tùy chọn)", systemImage: "phone.arrow.up.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Nhập số điện thoại cần gọi...", text: $phoneNumberToCall)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(10)
                
                if !phoneNumberToCall.isEmpty {
                    Button(action: { phoneNumberToCall = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func simConfigCard(
        title: String,
        iconName: String,
        accentColor: Color,
        minutes: Binding<Int>,
        seconds: Binding<Int>,
        onStart: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(accentColor)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phút")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Phút", selection: minutes) {
                        ForEach(0..<60) { m in
                            Text("\(m) phút").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 90)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giây")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Giây", selection: seconds) {
                        ForEach([0, 15, 30, 45], id: \.self) { s in
                            Text("\(s) giây").tag(s)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 90)
                    .clipped()
                }
            }
            
            Button(action: {
                withAnimation {
                    onStart()
                }
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Bắt đầu cuộc gọi (\(minutes.wrappedValue)m \(seconds.wrappedValue)s)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accentColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    private var guidanceFooter: some View {
        VStack(spacing: 6) {
            Label("Hướng dẫn sử dụng", systemImage: "info.circle")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("Khi nhấn nút gọi, đếm ngược sẽ xuất hiện trên **Dynamic Island** của iPhone 15 Pro Max. Vui lòng dập máy khi nghe tiếng chuông/rung cảnh báo.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
