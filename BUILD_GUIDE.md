# Hướng dẫn Cài đặt Ứng dụng "CallTimer" lên iPhone 15 Pro Max từ Windows

Mã nguồn đầy đủ của ứng dụng **CallTimer** đã được tạo hoàn chỉnh trong thư mục:
`D:\AI Agent - SelfStudies\Time for Call on Iphone`

---

## 📁 Danh sách các Tệp tin đã Tạo

1. **`CallTimer/ContentView.swift`**: Giao diện chính SwiftUI cấu hình phút/giây cho eSIM 1 & eSIM 2.
2. **`CallTimer/TimerManager.swift`**: Logic đếm ngược, lưu cấu hình và kết nối Dynamic Island.
3. **`CallTimer/NotificationManager.swift`**: Xử lý rung & phát chuông cảnh báo khi sắp hết giờ.
4. **`CallTimer/CallTimerAttributes.swift`**: Thuộc tính dữ liệu cho Live Activity trên iPhone.
5. **`CallTimer/CallTimerWidgetLiveActivity.swift`**: Giao diện hiển thị trực quan trên **Dynamic Island** & Lock Screen.
6. **`CallTimer/Info.plist`**: Cấu hình quyền hệ thống, Background Audio & Live Activity.
7. **`CallTimer/Assets.xcassets/AppIcon.appiconset/icon1024.png`**: Icon ứng dụng chất lượng cao (1024x1024) hiển thị trên Thư viện ứng dụng.
8. **`CallTimerApp.xcodeproj/project.pbxproj`**: File dự án chuẩn Xcode.
9. **`.github/workflows/build_ios.yml`**: Kịch bản tự động biên dịch file `.ipa` trên đám mây.

---

## 🚀 HƯỚNG DẪN CÀI TRỰC TIẾP LÊN IPHONE TỪ MÁY TÍNH WINDOWS (Không cần máy Mac)

Vì hệ điều hành iOS của Apple yêu cầu biên dịch qua máy chủ macOS, bạn có thể thực hiện theo **2 bước đơn giản** sau từ máy Windows của mình:

### BƯỚC 1: Tạo file cài đặt `.ipa` tự động bằng GitHub (Miễn phí 100%)

1. Tạo một repository mới trên [GitHub.com](https://github.com).
2. Tải toàn bộ thư mục `D:\AI Agent - SelfStudies\Time for Call on Iphone` lên repository đó.
3. Vào tab **Actions** trên GitHub, kịch bản `Build CallTimer iOS App (.ipa)` sẽ tự động chạy biên dịch file trên máy chủ macOS của GitHub trong 1-2 phút.
4. Sau khi xong, nhấn tải file **`CallTimer-iOS-Installer`** (chứa file `CallTimer.ipa`) về máy tính Windows của bạn.

---

### BƯỚC 2: Cài ứng dụng file `.ipa` vào iPhone bằng Sideloadly hoặc AltStore

1. Tải phần mềm **Sideloadly** (Miễn phí cho Windows) tại: [https://sideloadly.io](https://sideloadly.io)
2. Cắm iPhone 15 Pro Max của bạn vào máy tính Windows bằng cáp sạc.
3. Mở Sideloadly lên:
   * Kéo thả file **`CallTimer.ipa`** vào Sideloadly.
   * Nhập Apple ID của bạn vào ô **Apple Account**.
   * Nhấn **Start**.
4. Sau 30 giây, ứng dụng **CallTimer** với **Icon hiển thị đẹp mắt** sẽ xuất hiện ngay trên Màn hình chính và Thư viện ứng dụng của iPhone!

> 💡 **Lưu ý trên iPhone:** 
> Khi mở ứng dụng lần đầu, bạn vào **Cài đặt (Settings) trên iPhone** -> **E-mail & Tài khoản / Cấu hình (General -> VPN & Device Management)** -> Chọn Apple ID của bạn -> Nhấn **Tin cậy (Trust)** để khởi chạy ứng dụng.

---

## 💻 NẾU BẠN HOẶC BẠN BÈ CÓ MÁY MAC:
Chỉ cần copy thư mục `Time for Call on Iphone` sang Mac, kích kép vào tệp `CallTimerApp.xcodeproj` để mở bằng Xcode và nhấn nút **Run (Play)** để cài trực tiếp vào iPhone cắm qua dây cáp.
