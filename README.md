# CallTimer: nhắc thời lượng cuộc gọi theo từng SIM cho iPhone (Dynamic Island & Live Activity)

Ứng dụng iOS 17+ cho phép đặt mốc thời gian gọi tối đa riêng cho từng SIM/eSIM (2 SIM trở lên), đếm ngược trên Dynamic Island và Màn hình khóa, rồi cảnh báo bằng chuông và rung trước khi chạm mốc.

## Tính năng
- ⏱️ Mốc phút/giây riêng cho từng SIM. Có thể thêm, xóa và đổi tên SIM; cài đặt được lưu tự động bằng UserDefaults.
- 🏝️ Đếm ngược thời gian thực trên **Dynamic Island** (dạng compact và expanded) và **Màn hình khóa**. Hệ thống tự đếm nên vẫn chạy khi app ở nền trong lúc gọi.
- 🔔 **Cảnh báo vàng** trước N giây (mặc định 30, chỉnh được) và **cảnh báo đỏ** khi chạm mốc, dùng thông báo cục bộ nên hoạt động cả khi tắt màn hình.
- 📞 Nhập số để vừa gọi (`tel:`) vừa đếm ngược.
- 🌗 Giao diện dạng thẻ, tự đổi theo chế độ Sáng/Tối; icon 1024×1024.

## Cấu trúc
- `CallTimer/`: app chính (`ContentView`, `TimerManager`, `NotificationManager`, `Info.plist`, `Assets.xcassets`).
- `CallTimerWidget/`: Widget Extension hiển thị Live Activity trên Dynamic Island và Màn hình khóa.
- `Shared/CallTimerAttributes.swift`: dữ liệu Live Activity, dùng chung cho cả 2 target.
- `project.yml`: cấu hình dự án XcodeGen; `CallTimerApp.xcodeproj` được tạo tự động từ file này.
- `.github/workflows/build_ios.yml`: tự build `CallTimer.ipa` trên GitHub Actions.
- `BUILD_GUIDE.md`: hướng dẫn cài lên iPhone từ Windows bằng Sideloadly.
