# CallTimer - Ứng dụng Nhắc nhở Thời lượng Cuộc gọi cho iPhone (Dynamic Island & Live Activity)

Ứng dụng iOS hỗ trợ quản lý và đếm ngược thời gian gọi cho từng eSIM (eSIM 1 & eSIM 2) trên iPhone 15 Pro Max.

## Tính năng
- ⏱️ Cấu hình thời gian tối đa cho eSIM 1 và eSIM 2.
- 🏝️ Hiển thị đếm ngược thời gian thực trên **Dynamic Island** & Lock Screen.
- 🔔 Cảnh báo rung & phát âm thanh khi còn 30 giây và khi chạm mốc giới hạn.
- 📱 Icon hiển thị chuẩn Retina 1024x1024 trên Thư viện ứng dụng iOS.

## Cấu trúc Dự án
- `CallTimer/`: Mã nguồn SwiftUI (`ContentView`, `TimerManager`, `NotificationManager`, `CallTimerAttributes`, `CallTimerWidgetLiveActivity`).
- `CallTimerApp.xcodeproj`: Dự án Xcode.
- `.github/workflows/build_ios.yml`: Workflow biên dịch tự động `.ipa`.
- `BUILD_GUIDE.md`: Hướng dẫn cài đặt lên iPhone từ Windows bằng Sideloadly / AltStore.
