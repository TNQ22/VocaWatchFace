# AGENTS.md — Quy chuẩn phát triển VocaWatchFace (Garmin FR245 / FR245M)

Tài liệu này tổng hợp các quy ước thiết kế, kỹ thuật hiển thị phần cứng MIP 64 màu, bố cục và quy trình kiểm thử bắt buộc cho dự án **VocaWatchFace**. Mọi agent hoặc chỉnh sửa về sau cần tuân thủ các quy tắc dưới đây.

---

## 1. Quy tắc Git & Kiểm thử
- **Không tự động `git commit` hoặc `git push`** khi chưa có yêu cầu rõ ràng của người dùng.
- **Không dùng mockup HTML** để kiểm tra giao diện; luôn build `.prg` thật bằng Connect IQ SDK (`monkeyc.bat`) và kiểm tra trực tiếp trên Garmin Connect IQ Simulator (`fr245m`).
- Script build, nạp và chụp ảnh simulator: `tools/build_and_capture.ps1` (tự đóng `MonkeyDoDeux` / `shell.exe` sau khi đẩy `.prg` để tránh treo console) kết hợp `tools/capture_sim.py`.
- Lệnh build chuẩn:
  ```powershell
  & "$SDK_BIN\monkeyc.bat" -o "out\VocaWatchFace_fr245m.prg" -f "monkey.jungle" -y "ci\developer_key.der" -d fr245m -l 0
  ```

---

## 2. Quy chuẩn màu sắc cho màn hình MIP 64 màu (`fr245m` / RGB222)
Màn hình MIP phản xạ của Garmin Forerunner 245 / 245 Music chỉ hỗ trợ **64 màu phần cứng** với đúng 4 mức mỗi kênh R/G/B (`0x00`, `0x55`, `0xAA`, `0xFF`) và **hiển thị ngoài thực tế khác với màn hình phát sáng của simulator trên PC**:
- **TUYỆT ĐỐI KHÔNG dùng mã màu pha pastel/Material RGB** (như `0x00E676`, `0xFF5252`, `0xFFD54F`, `0x40C4FF`, `0xFF9900`) vì các kênh phụ (`0x55`, `0xAA`) làm màu bị bạc về trắng hoặc lệch tông trên đồng hồ thật (xanh lục ngả xanh dương, đỏ thành cam, vàng thành trắng, xanh dương thành trắng).
- Luôn dùng màu thuần MIP đồng bộ giữa `source/EnglishWatchFaceView.mc` và file PNG trong `resources/drawables/`:

| Thành phần | Hằng số / Giá trị chuẩn MIP | Lưu ý phần cứng |
|---|---|---|
| **Xanh lục chính** (từ vựng, thanh tiến độ, bước chân) | `Graphics.COLOR_GREEN` (`0x00FF00`) | Kênh Blue = `0` để không ngả cyan/teal. `icon_footprints.png` dùng đúng `(0, 255, 0)`. |
| **Đỏ cảnh báo** (tim, nhịp tim, pin `<= 20%`, âm lịch đặc biệt) | `Graphics.COLOR_RED` (`0xFF0000`) | Kênh Green/Blue = `0` để không ngả cam. `icon_heart.png` dùng đúng `(255, 0, 0)`. |
| **Cam** (âm lịch ngày thường) | `Graphics.COLOR_ORANGE` (`0xFF5500`) | Cam chuẩn Garmin, tránh `0xFFAA00` bị nhạt vàng. |
| **Vàng** (giây, phiên âm IPA) | `0xFFFF00` | Dùng literal `0xFFFF00` (`B = 0`); lưu ý `Graphics.COLOR_YELLOW` của `fr245m` là `0xFFAA00` (hơi cam) và `0xFFFF55` bị bạc trắng. |
| **Xanh dương** (từ loại `n.`, `v.`, `adj.`) | `Graphics.COLOR_BLUE` (`0x00AAFF`) | Kênh Red = `0` để không bạc trắng. |
| **Xám nền thanh / viền mờ** | `Graphics.COLOR_DK_GRAY` (`0x555555`), `Graphics.COLOR_LT_GRAY` (`0xAAAAAA`) | — |

---

## 3. Bố cục màn hình tròn 240×240 (`source/EnglishWatchFaceView.mc`)
Lưu ý các font hệ thống của Garmin có khoảng đệm trên ẩn (`FONT_NUMBER_HOT` lệch +23px, ink cao 46px; `FONT_MEDIUM` +9px; `FONT_XTINY` +6px). Bố cục chuẩn từ trên xuống dưới:

1. **Ngày dương & Âm lịch (`dateY = 17` với `DateFont`)**:
   - Định dạng gọn: `T3-24/11 16/10` (không có dấu cách quanh `-`, không có chữ `AL` trong `LunarCalendar.mc`), căn giữa tổng thể quanh `centerX`.
   - Màu âm lịch: **Đỏ (`COLOR_RED_ALERT`)** vào ngày **mùng 1 (đầu tháng), 14, 15, và ngày cuối tháng âm lịch** (`lunar.day == lunar.daysInMonth`, hỗ trợ cả tháng thiếu 29 ngày và tháng đủ 30 ngày trong `source/LunarCalendar.mc`); ngày bình thường hiển thị màu **Cam (`COLOR_ORANGE_LUNAR`)**.
2. **Giờ - Phút (`timeY = 20`) & Giây (`secY = 65`)**:
   - `FONT_NUMBER_HOT` căn dấu `:` tại `centerX`, số giây màu vàng (`0xFFFF00`) đặt ngang đáy số phút bên phải. Không để vạch phân cách đè lên số.
3. **Cụm Từ vựng ở giữa màn hình**:
   - Thanh tiến độ trên (`topBarY = 96`), từ vựng + từ loại (`wordY = 95`), phiên âm IPA (`phoneticY = 123`), nghĩa tiếng Việt (`meaningY = 147`), thanh tiến độ bước chân dưới (`botBarY = 172`).
   - Hai thanh phân cách trên & dưới có chiều rộng bằng nhau (`segBarWidth = 206`), vươn sát viền màn hình tròn mà không bị cắt góc.
   - Nghĩa tiếng Việt dài vượt `218px` tự xuống tối đa 2 dòng qua `splitTextToFit`.
4. **Hàng Bước chân | Nhịp tim (`rowY = 182`, dùng `DateFont`)**:
   - Căn giữa đều giữa thanh phân chia dưới (`botBarY = 172`) và cụm trạng thái (`botStatusY = 207`).
   - Trái: `icon_footprints.png` (`18×18`, xanh `0x00FF00`) + số bước; giữa: dấu `|`; phải: `icon_heart.png` (`18×18`, đỏ `0xFF0000`) + nhịp tim.
5. **Cụm trạng thái & thông báo ở dưới cùng (`botStatusY = 207`)**:
   - **Thứ tự cố định từ trái sang phải**:
     `Pin` → `Kết nối điện thoại` → `Báo thức` → `Không làm phiền` → `Tai nghe` → `Thông báo`.

---

## 4. Quy chuẩn Font & Icon (`tools/generate_bmfont.py`, `resources/`)
- **Font tùy chỉnh (`resources/fonts/fonts.xml`)**:
  - `DateFont` (`date.fnt`, cao `14px`, bitmap đối xứng nét đều `2px`): dùng chung cho dòng ngày dương & âm lịch và hàng Bước chân | Nhịp tim (`0-9`, `/`, `T`, `C`, `N`, `-`, `|`), tránh rasterize TrueType gây lệch nét bên to bên nhỏ.
  - `PhoneticFont` (`phonetic.fnt`, Segoe UI Light 18px, `cutoff=95` đơn sắc): hỗ trợ IPA chuẩn nét mảnh `1px` đồng đều + tiếng Việt.
  - `MeaningFont` (`meaning.fnt`, Segoe UI Light 16px, `cutoff=95` đơn sắc): bắt buộc dùng cho nghĩa tiếng Việt nét đều không bết (font hệ thống `FONT_XTINY` thiếu dấu tiếng Việt mở rộng nên hiện ký tự lỗi `♦`).
  - `BadgeFont` (`badge.fnt`, cao `9px`, bitmap nhị phân `0/255` đối xứng nét đều `2px`): dùng cho số bên trong Pin và Thông báo để hai bên số (`0`, `8`...) dày đều tuyệt đối, không bị nét mờ hay bên to bên nhỏ.
- **Vẽ Pin & Icon Thông báo (`drawSmoothBatteryPill`, `drawCompactWhiteBattery`, `drawNotificationBadge`)**:
  - **Không dùng `dc.fillRoundedRectangle` ở bán kính nhỏ (`<= 3`)** vì Connect IQ vẽ góc vát chéo 45° và tự lược bỏ chóp pin `2px`. Luôn dùng `drawSmoothBatteryPill` (`r = 2` kèm điểm làm mềm đối xứng ở 4 góc) và vẽ chóp pin bằng `fillRectangle` 2 cột cách thân `1px`.
  - Khung pin `26×15`, chữ số `BadgeFont` (`9px`) vẽ tại `y + 2` (cân đều theo thị giác). Pin nền xám sáng `COLOR_LT_GRAY`, phần đã sạc tô trắng (hoặc đỏ khi `<= 20%`). Chóp pin **màu trắng khi đầy `100%`**, và **chuyển về xám khi tụt dưới `100%`**.
  - Icon Thông báo cao `15px`, dạng bong bóng tin nhắn bo góc mềm nền trắng có đuôi nhọn góc dưới trái, ghi số `notificationCount` màu đen trực tiếp bên trong tại `y + 2` (hiển thị khi `notificationCount > 0`).
- **Bộ icon (`resources/drawables/`)**:
  - Trạng thái trắng (`16×16`): `icon_phone_bt.png` (ống nghe uốn chéo + Bluetooth), `icon_alarm.png` (đồng hồ tròn 2 tai + kim `L`), `icon_moon.png` (trăng lưỡi liềm cân đối từ 2 đường tròn), `icon_headphone.png` (tai nghe bo tròn đối xứng).
  - Bước chân & Nhịp tim (`18×18`): `icon_footprints.png` (render theo path Bezier Lucide `footprints` màu `(0, 255, 0)`) và `icon_heart.png` (trái tim đối xứng màu `(255, 0, 0)`).
