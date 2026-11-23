# VocaWatchFace - Garmin English Vocabulary Watch Face

Mặt đồng hồ Garmin học từ vựng tiếng Anh kết hợp Âm lịch Việt Nam, tối ưu chuyên biệt cho **Forerunner 245 Music** (và các dòng Garmin 240x240 / AMOLED).

## 🌿 Điểm nổi bật phiên bản mới

1. **Thiết kế tràn viền 100%:**
   - Xóa bỏ hoàn toàn vòng đếm tròn ở rìa màn hình.
   - Toàn bộ không gian hiển thị được mở rộng tối đa, giúp hiển thị đồng hồ và thẻ từ vựng to rõ nét.
2. **Thanh ngang tiến độ bước chân:**
   - Đặt ngay phía trên số bước chân để trực quan hóa % mục tiêu hàng ngày.
   - Bỏ ký hiệu `(%)` rườm rà: hiển thị gọn gàng `👟 7,240 / 10,000`.
3. **Màu xanh lá thể thao (Garmin Green):**
   - Tông màu xanh lá năng động `#00E676`, phối cùng số trắng và điểm nhấn vàng/xanh dương.
4. **Cấu trúc Từ vựng 3 dòng tinh gọn:**
   - **Dòng 1:** TỪ VỰNG (In hoa, xanh lá) + Loại từ (`n.`, `v.`, `adj.`)
   - **Dòng 2:** Phiên âm chuẩn IPA (Màu vàng nổi bật, dễ đọc)
   - **Dòng 3:** Nghĩa tiếng Việt ngắn gọn, xúc tích (đã loại bỏ câu ví dụ dài dòng).
5. **Trạng thái kết nối & Pin rõ ràng:**
   - **Bluetooth:** `BT ON` (Xanh dương khi kết nối) / `BT OFF`.
   - **Tin nhắn:** `💬 [số]` (Icon tin nhắn chat bubble thay vì phong bì thư).
   - **Pin:** `86%` (Pin số rõ ràng, tự đổi sang màu đỏ khi pin yếu dưới 20%).
6. **Âm lịch Việt Nam:**
   - Mốc tính chính xác từ năm 2026 (Tết Bính Ngọ) đến 2040.

---

## 📂 Danh sách file dự án

- [manifest.xml](file:///C:/Users/TNQ/.t3/projects/garmin/manifest.xml): Cấu hình thiết bị `fr245m`, `fr245` và quyền hệ thống.
- [source/EnglishWatchFaceView.mc](file:///C:/Users/TNQ/.t3/projects/garmin/source/EnglishWatchFaceView.mc): Giao diện vẽ đồ họa chính (GDC).
- [source/VocabularyManager.mc](file:///C:/Users/TNQ/.t3/projects/garmin/source/VocabularyManager.mc): Quản lý từ vựng, phiên âm IPA, cơ chế đổi từ khi lắc tay/định kỳ.
- [source/LunarCalendar.mc](file:///C:/Users/TNQ/.t3/projects/garmin/source/LunarCalendar.mc): Thuật toán âm lịch siêu nhẹ bắt đầu từ 2026.
- [source/WebSyncServiceDelegate.mc](file:///C:/Users/TNQ/.t3/projects/garmin/source/WebSyncServiceDelegate.mc): Chạy ngầm tải từ vựng qua Web API.
- [resources/settings/settings.xml](file:///C:/Users/TNQ/.t3/projects/garmin/resources/settings/settings.xml): Menu cài đặt trên Garmin Connect Mobile.
- [mockup.html](file:///C:/Users/TNQ/.t3/projects/garmin/mockup.html): Bản mô phỏng trực quan tương tác.
