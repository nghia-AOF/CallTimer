# Hướng dẫn build & cài CallTimer lên iPhone từ Windows (không qua App Store)

## Tổng quan quy trình
1. **GitHub Actions** (máy macOS miễn phí của GitHub) tự động biên dịch mã nguồn thành `CallTimer.ipa` mỗi khi có commit mới lên nhánh `main` của repo https://github.com/nghia-AOF/CallTimer.
2. **Sideloadly** trên Windows ký file `.ipa` bằng Apple ID của bạn rồi cài vào iPhone qua cáp.

---

## BƯỚC 1: Lấy file `CallTimer.ipa`
1. Mở https://github.com/nghia-AOF/CallTimer/actions và chờ lần chạy **Build CallTimer iOS App (.ipa)** mới nhất có dấu ✅ xanh (khoảng 3–6 phút).
   - Nếu muốn chạy lại thủ công: chọn workflow đó, bấm **Run workflow**.
2. Tải file theo một trong hai cách:
   - **Releases** (dễ nhất): https://github.com/nghia-AOF/CallTimer/releases, chọn bản `build-N` mới nhất rồi tải `CallTimer.ipa`.
   - Hoặc trong trang lần chạy Actions: tải artifact **CallTimer-iOS-Installer** (file .zip) rồi giải nén để lấy `CallTimer.ipa`.

## BƯỚC 2: Chuẩn bị máy tính Windows
1. Cài **iTunes bản tải trực tiếp từ Apple** (không phải bản Microsoft Store): https://www.apple.com/itunes/download/win64.
   Sideloadly cần driver của bản này để nhận iPhone.
2. Cài **Sideloadly**: https://sideloadly.io.
3. Cắm iPhone vào máy tính bằng cáp. Trên iPhone, bấm **Tin cậy** (Trust) và nhập mật mã.

## BƯỚC 3: Bật Chế độ nhà phát triển trên iPhone (iOS 16 trở lên)
1. Trên iPhone vào **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển** (Developer Mode) và bật lên.
   Nếu chưa thấy mục này, hãy làm Bước 4 một lần trước, mục này sẽ xuất hiện sau đó.
2. iPhone khởi động lại. Sau khi mở máy, xác nhận **Bật**.

## BƯỚC 4: Cài bằng Sideloadly
1. Mở Sideloadly, kéo thả `CallTimer.ipa` vào ô IPA.
2. Mục **iDevice**: chọn iPhone của bạn.
3. Mục **Apple ID**: nhập Apple ID (nên dùng một Apple ID phụ). Bấm **Start** rồi nhập mật khẩu và mã xác thực 2 lớp nếu được hỏi.
4. Chờ đến khi hiện **Done**.

## BƯỚC 5: Tin cậy nhà phát triển trên iPhone
**Cài đặt → Cài đặt chung → Quản lý VPN & Thiết bị** → chọn Apple ID của bạn → **Tin cậy**.

## BƯỚC 6: Cấp quyền khi mở app lần đầu
- Cho phép **Thông báo**: cần cho cảnh báo vàng và đỏ khi màn hình tắt.
- Kiểm tra **Cài đặt → CallTimer → Hoạt động trực tiếp (Live Activities)** đang bật để thấy đếm ngược trên Dynamic Island.
- Nếu dùng chế độ **Tập trung / Không làm phiền**, hãy cho phép CallTimer gửi thông báo.

---

## ⚠️ Giới hạn của Apple ID miễn phí
- Ứng dụng **hết hạn sau 7 ngày**. Khi đó chỉ cần cắm máy và bấm Start lại trong Sideloadly (dữ liệu cài đặt vẫn giữ nguyên).
  Có thể bật **Auto-refresh** trong Sideloadly để tự làm mới qua Wi-Fi khi máy tính đang bật.
- Mỗi Apple ID miễn phí được cài tối đa 3 app tự ký cùng lúc. CallTimer gồm app và 1 widget extension.
- Nếu có tài khoản Apple Developer trả phí (99 USD/năm), app sẽ dùng được 1 năm.

## Cách dùng
1. Mỗi thẻ SIM/eSIM có tên và mốc phút/giây riêng. Dùng **Thêm SIM / eSIM** nếu bạn có nhiều hơn 2 SIM. Cài đặt được lưu tự động.
2. Có 2 cách gọi:
   - Nhập số, rồi bấm **Gọi & đếm ngược** trên thẻ SIM tương ứng: app bắt đầu đếm và mở ứng dụng Điện thoại.
   - Hoặc để trống ô số, tự gọi bằng ứng dụng Điện thoại (chọn SIM ở đó), rồi mở CallTimer và bấm **Bắt đầu đếm** trên thẻ SIM tương ứng.
3. Đếm ngược hiển thị trên Dynamic Island (nhấn giữ để mở rộng) và Màn hình khóa.
4. Khi còn N giây (mặc định 30, chỉnh được): **cảnh báo vàng** gồm thông báo, chuông và rung nhẹ.
   Khi chạm mốc: **cảnh báo đỏ** gồm 3 thông báo liên tiếp; nếu app đang mở thì rung và chuông lặp lại.
5. Sau khi dập máy, mở app và bấm **Dừng đếm ngược / Đóng**.

> Lưu ý: iOS không cho ứng dụng bên thứ ba chọn SIM để gọi. Khi gọi qua CallTimer, iPhone dùng đường dây mặc định hoặc đường dây đã dùng gần nhất với số đó.
> Muốn chắc chắn gọi đúng SIM, hãy dùng cách thứ hai ở trên.

---

## Build trên máy Mac (tùy chọn)
```bash
brew install xcodegen
xcodegen generate        # tạo CallTimerApp.xcodeproj từ project.yml
open CallTimerApp.xcodeproj
```
Chọn Team (Apple ID) cho cả 2 target `CallTimer` và `CallTimerWidgetExtension`, cắm iPhone rồi bấm **Run**.
