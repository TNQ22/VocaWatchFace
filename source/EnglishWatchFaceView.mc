import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.Application.Storage;

class EnglishWatchFaceView extends WatchUi.WatchFace {

    private var vocabManager as VocabularyManager;
    private var isAwake as Boolean = true;

    // Bảng màu chuẩn Garmin
    const COLOR_GREEN_MAIN = 0x00E676;  // Xanh lá thể thao chủ đạo
    const COLOR_RED_ALERT  = 0xFF5252;  // Đỏ cảnh báo pin yếu
    const COLOR_SEG_BG     = 0x152219;  // Nền vạch đứt đoạn chưa sáng
    const COLOR_YELLOW_SEC = 0xFFD54F;  // Vàng kim giây & phiên âm IPA
    const COLOR_WHITE_ICON = 0xFFFFFF;  // Trắng cho toàn bộ icon trạng thái
    const COLOR_GRAY_BAT   = 0x616161;  // Xám trung tính cho phần pin đã tụt

    function initialize() {
        WatchFace.initialize();
        vocabManager = new VocabularyManager();
        reloadWordsFromCache();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
    }

    function onSettingsChanged() as Void {
        reloadWordsFromCache();
    }

    function reloadWordsFromCache() as Void {
        var cached = Storage.getValue("WebWordsCache");
        if (cached != null && cached instanceof Array) {
            var newWords = [];
            for (var i = 0; i < cached.size(); i++) {
                var item = cached[i];
                if (item instanceof Dictionary) {
                    var w = item.get("w") != null ? item.get("w") : "";
                    var p = item.get("p") != null ? item.get("p") : "";
                    var ph = item.get("ph") != null ? item.get("ph") : "";
                    var m = item.get("m") != null ? item.get("m") : "";
                    if (w.length() > 0) {
                        newWords.add(new VocabularyItem(w, p, ph, m));
                    }
                }
            }
            if (newWords.size() > 0) {
                vocabManager.updateCustomWords(newWords);
            }
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var centerX = width / 2;

        vocabManager.checkPeriodicUpdate();

        // 1. Nền đen hoàn toàn (tương phản tối đa cho MIP 240x240)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // 2. Dữ liệu hệ thống
        var clockTime = System.getClockTime();
        var devSettings = System.getDeviceSettings();
        var sysStats = System.getSystemStats();
        var actInfo = ActivityMonitor.getInfo();

        var hours = clockTime.hour;
        var is24Hour = devSettings.is24Hour;
        if (!is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            } else if (hours == 0) {
                hours = 12;
            }
        }
        var hourStr = hours.format("%02d");
        var minStr = clockTime.min.format("%02d");
        var secStr = clockTime.sec.format("%02d");

        // 3. TOP STATUS BAR: CHUẨN THEO ẢNH IMG_0235
        // Viên pin thu nhỏ gọn (22x12px), số đen to đậm ở giữa + 4 Icon trắng
        var topY = 20;
        var iconSpacing = 19;
        var curX = centerX - 50;

        // A. VIÊN PIN NHỎ GỌN CHUẨN IOS (24x12px), CĂN CHUẨN THÂN PIN (IMG_0241)
        var battery = sysStats.battery.toNumber();
        drawCompactIosBattery(dc, curX, topY, battery);
        curX += 30;

        // B. BÁO THỨC (Alarm - Chuông đôi màu TRẮNG)
        var alarmCount = devSettings.alarmCount;
        if (alarmCount != null && alarmCount > 0) {
            drawAlarmIcon(dc, curX, topY);
            curX += iconSpacing;
        }

        // C. ĐIỆN THOẠI + BLUETOOTH (Ống nghe cong có logo BT ở giữa, màu TRẮNG, ẩn khi ngắt)
        if (devSettings.phoneConnected) {
            drawPhoneBtHandset(dc, curX, topY);
            curX += iconSpacing;
        }

        // D. KHÔNG LÀM PHIỀN (Mặt trăng khuyết MẬP MẠP, DÀY DẶN, RÕ NÉT HƠN)
        if (devSettings has :doNotDisturb && devSettings.doNotDisturb) {
            drawBolderMoonIcon(dc, curX, topY);
            curX += iconSpacing;
        }

        // E. TAI NGHE (Headphone over-ear màu TRẮNG)
        drawHeadphoneIcon(dc, curX, topY);

        // 4. NGÀY: "T2 - 23/11" & ÂM LỊCH 2026
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        var lunar = LunarCalendar.getLunarDate(dateInfo.year, dateInfo.month, dateInfo.day);

        var dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        var dayOfWeekStr = dayNames[dateInfo.day_of_week - 1];
        var solarStr = Lang.format("$1$ - $2$/$3$", [dayOfWeekStr, dateInfo.day.format("%02d"), dateInfo.month.format("%02d")]);
        var lunarStr = lunar.toString();

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 36, topY + 20, Graphics.FONT_XTINY, solarStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 42, topY + 20, Graphics.FONT_XTINY, lunarStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 5. GIỜ - PHÚT: CĂN GIỮA TUYỆT ĐỐI BẰNG THUẬT TOÁN TÁCH 3 PHẦN
        // Dấu hai chấm ":" được vẽ tại đúng centerX (120px)
        // Số giờ vẽ bên trái dấu hai chấm (TEXT_JUSTIFY_RIGHT)
        // Số phút vẽ bên phải dấu hai chấm (TEXT_JUSTIFY_LEFT)
        var timeY = topY + 36;
        var timeFont = Graphics.FONT_NUMBER_HOT;
        var colonDim = dc.getTextDimensions(":", timeFont);
        var colonHalfWidth = colonDim[0] / 2;
        var timeHeight = colonDim[1];

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // 1. Dấu hai chấm (:) ở đúng tâm màn hình (centerX)
        dc.drawText(centerX, timeY, timeFont, ":", Graphics.TEXT_JUSTIFY_CENTER);

        // 2. Số Giờ (bên trái dấu hai chấm)
        dc.drawText(centerX - colonHalfWidth - 1, timeY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // 3. Số Phút (bên phải dấu hai chấm)
        var minX = centerX + colonHalfWidth + 1;
        dc.drawText(minX, timeY, timeFont, minStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 4. Số Giây: Đặt ngay bên phải số phút, dóng chân thẳng hàng với phút
        if (isAwake) {
            var secFont = Graphics.FONT_TINY;
            var minDim = dc.getTextDimensions(minStr, timeFont);
            var secDim = dc.getTextDimensions(secStr, secFont);
            var secHeight = secDim[1];

            dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
            var secX = minX + minDim[0] + 3;
            var secY = timeY + timeHeight - secHeight - 14;
            dc.drawText(secX, secY, secFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 6. VÙNG TỪ VỰNG: 2 THANH ĐỨT ĐOẠN KÉO DÀI SÁT VIỀN (206px)
        var word = vocabManager.getCurrentWord();
        var totalWords = vocabManager.getTotalWords();
        var currentVocabIdx = vocabManager.getCurrentIndex();

        var segBarWidth = 206;
        var barHeight = 3;

        // A. THANH TRÊN: Kéo dài sát viền, vạch từ vựng hiện tại sáng màu xanh
        var topBarY = timeY + timeHeight + 4;
        drawSegmentedBar(dc, centerX, topBarY, segBarWidth, barHeight, totalWords, currentVocabIdx, COLOR_GREEN_MAIN, true);

        // B. NỘI DUNG TỪ VỰNG
        // Dòng 1: TỪ VỰNG (Xanh lá) + Loại từ
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 10, topBarY + 4, Graphics.FONT_MEDIUM, word.word, Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(0x40C4FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 4, topBarY + 8, Graphics.FONT_XTINY, word.pos, Graphics.TEXT_JUSTIFY_LEFT);

        // Dòng 2: PHIÊN ÂM IPA (Vàng)
        dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, topBarY + 22, Graphics.FONT_XTINY, word.phonetic, Graphics.TEXT_JUSTIFY_CENTER);

        // Dòng 3: NGHĨA TIẾNG VIỆT (Trắng)
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, topBarY + 36, Graphics.FONT_XTINY, word.meaning, Graphics.TEXT_JUSTIFY_CENTER);

        // C. THANH DƯỚI: TRÙNG SỐ VẠCH & KÉO DÀI SÁT VIỀN (206px)
        var botBarY = topBarY + 52;
        var steps = (actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var activeStepSegs = ((steps * totalWords * 1.0) / stepGoal).toNumber();
        if (activeStepSegs > totalWords) {
            activeStepSegs = totalWords;
        }
        drawSegmentedBar(dc, centerX, botBarY, segBarWidth, barHeight, totalWords, activeStepSegs, COLOR_GREEN_MAIN, false);

        // 7. DƯỚI CÙNG: SỐ BƯỚC THỰC TẾ / MỤC TIÊU
        var stepTextY = botBarY + 6;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        var stepsText = Lang.format("👟 $1$ / $2$", [steps, stepGoal]);
        dc.drawText(centerX, stepTextY, Graphics.FONT_XTINY, stepsText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Vẽ thanh đứt đoạn (Segmented Bar)
    private function drawSegmentedBar(dc as Graphics.Dc, cX as Number, y as Number, totalWidth as Number, barH as Number, count as Number, activeIdx as Number, activeColor as Number, isSingleHighlight as Boolean) as Void {
        if (count <= 0) {
            count = 1;
        }
        var gap = 4;
        var segWidth = (totalWidth - (gap * (count - 1))) / count;
        var startX = cX - (totalWidth / 2);

        for (var i = 0; i < count; i++) {
            var sX = startX + i * (segWidth + gap);
            var isActive = isSingleHighlight ? (i == activeIdx) : (i < activeIdx);

            if (isActive) {
                dc.setColor(activeColor, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_SEG_BG, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillRoundedRectangle(sX, y, segWidth, barH, 1);
        }
    }

    // Icon Pin nhỏ gọn chuẩn phong cách iOS (IMG_0235, IMG_0241)
    private function drawCompactIosBattery(dc as Graphics.Dc, x as Number, y as Number, pct as Number) as Void {
        var w = 24;
        var h = 12;

        // 1. Thân pin bo nhẹ góc 2px
        dc.setColor(COLOR_GRAY_BAT, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y + 1, w, h, 2);

        // 2. Mức pin sạc (Màu TRẮNG; <20% chuyển ĐỎ)
        var isFull = (pct >= 100);
        var fillColor = (pct > 20) ? COLOR_WHITE_ICON : COLOR_RED_ALERT;
        var fillW = ((pct * w) / 100).toNumber();
        if (fillW > 0) {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y + 1, fillW, h, 2);
        }

        // 3. Đầu chóp pin bên phải: ĐẦY (100%) THÌ MÀU TRẮNG LUÔN, chưa đầy thì màu xám
        var nibColor = isFull ? COLOR_WHITE_ICON : COLOR_GRAY_BAT;
        dc.setColor(nibColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x + w, y + 4, 2, 5, 1);

        // 4. Chữ số pin: CĂN GIỮA TUYỆT ĐỐI THEO THÂN PIN (từ x đến x + w, tâm là x + w/2)
        // HOÀN TOÀN KHÔNG TÍNH ĐẦU CHÓP PIN ĐỂ TRÁNH BỊ LỆCH SANG PHẢI
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var batStr = Lang.format("$1$", [pct]);
        var bodyCenterX = x + (w / 2);
        var bodyCenterY = y + 1 + (h / 2);
        dc.drawText(bodyCenterX, bodyCenterY, Graphics.FONT_XTINY, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(bodyCenterX + 1, bodyCenterY, Graphics.FONT_XTINY, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Icon Báo thức (Alarm) - Chuông đôi màu trắng
    private function drawAlarmIcon(dc as Graphics.Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x + 6, y + 6, 5);
        dc.drawLine(x + 6, y + 3, x + 6, y + 6);
        dc.drawLine(x + 6, y + 6, x + 9, y + 6);
        dc.drawLine(x + 2, y + 1, x + 4, y + 3);
        dc.drawLine(x + 10, y + 1, x + 8, y + 3);
    }

    // Icon Ống nghe điện thoại có logo Bluetooth ở giữa (Chuẩn ảnh IMG_0222)
    private function drawPhoneBtHandset(dc as Graphics.Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x + 6, y + 6, 5, Graphics.ARC_CLOCKWISE, 135, 315);
        dc.fillCircle(x + 3, y + 3, 2);
        dc.fillCircle(x + 9, y + 9, 2);
        dc.drawLine(x + 6, y + 3, x + 6, y + 9);
        dc.drawLine(x + 6, y + 4, x + 8, y + 6);
        dc.drawLine(x + 8, y + 6, x + 6, y + 8);
    }

    // Icon Không làm phiền (Mặt trăng khuyết MẬP MẠP, DÀY DẶN HƠN)
    private function drawBolderMoonIcon(dc as Graphics.Dc, x as Number, y as Number) as Void {
        // Vẽ mặt trăng khuyết mập mạp: hình tròn trắng bán kính 6px
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + 5, y + 6, 6);

        // Khoét lõm bằng hình tròn đen lệch sang phải (x+9, y+4, r=5) để lại bụng trăng dày ~5px
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x + 9, y + 4, 5);
    }

    // Icon Tai nghe nhạc Bluetooth (Quai over-ear màu trắng)
    private function drawHeadphoneIcon(dc as Graphics.Dc, x as Number, y as Number) as Void {
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x + 6, y + 5, 5, Graphics.ARC_CLOCKWISE, 180, 0);
        dc.fillRectangle(x + 1, y + 5, 2, 5);
        dc.fillRectangle(x + 9, y + 5, 2, 5);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
        isAwake = true;
        vocabManager.onWristGesture();
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        isAwake = false;
        WatchUi.requestUpdate();
    }
}
