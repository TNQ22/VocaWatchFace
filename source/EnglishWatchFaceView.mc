import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application.Storage;

class EnglishWatchFaceView extends WatchUi.WatchFace {

    private var vocabManager as VocabularyManager;
    private var isAwake as Boolean = true;

    // Loaded Resources
    private var iconAlarm as WatchUi.BitmapResource?;
    private var iconMoon as WatchUi.BitmapResource?;
    private var iconHeadphone as WatchUi.BitmapResource?;
    private var iconPhoneBt as WatchUi.BitmapResource?;
    private var iconFootprints as WatchUi.BitmapResource?;
    private var iconHeart as WatchUi.BitmapResource?;
    private var phoneticFont as WatchUi.FontResource?;

    // Bảng màu chuẩn Garmin (chuẩn palette 64 màu của MIP display)
    const COLOR_GREEN_MAIN = 0x00E676;  // Xanh lá thể thao chủ đạo
    const COLOR_RED_ALERT  = 0xFF5252;  // Đỏ cảnh báo / Âm lịch / Nhịp tim
    const COLOR_SEG_BG     = 0x555555;  // Xám đậm hiển thị rõ ràng trên nền đen MIP
    const COLOR_YELLOW_SEC = 0xFFD54F;  // Vàng kim giây & phiên âm IPA
    const COLOR_WHITE_ICON = 0xFFFFFF;  // Trắng cho toàn bộ icon trạng thái

    function initialize() {
        WatchFace.initialize();
        vocabManager = new VocabularyManager();
        reloadWordsFromCache();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        iconAlarm = WatchUi.loadResource(Rez.Drawables.IconAlarm) as WatchUi.BitmapResource;
        iconMoon = WatchUi.loadResource(Rez.Drawables.IconMoon) as WatchUi.BitmapResource;
        iconHeadphone = WatchUi.loadResource(Rez.Drawables.IconHeadphone) as WatchUi.BitmapResource;
        iconPhoneBt = WatchUi.loadResource(Rez.Drawables.IconPhoneBt) as WatchUi.BitmapResource;
        iconFootprints = WatchUi.loadResource(Rez.Drawables.IconFootprints) as WatchUi.BitmapResource;
        iconHeart = WatchUi.loadResource(Rez.Drawables.IconHeart) as WatchUi.BitmapResource;
        phoneticFont = WatchUi.loadResource(Rez.Fonts.PhoneticFont) as WatchUi.FontResource;
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

        // 3. TOP STATUS BAR: Viên pin nền trắng có số bên trong + 4 icon trạng thái Garmin
        var battery = sysStats.battery.toNumber();
        var alarmCount = devSettings.alarmCount;
        var showAlarm = (alarmCount != null && alarmCount > 0);
        var showPhone = devSettings.phoneConnected;
        var showMoon = (devSettings has :doNotDisturb && devSettings.doNotDisturb);
        var showHeadphone = true;

        var iconCount = 0;
        if (showAlarm) { iconCount++; }
        if (showPhone) { iconCount++; }
        if (showMoon) { iconCount++; }
        if (showHeadphone) { iconCount++; }

        var iconSpacing = 4;
        var batW = 28; // 26px thân + 2px chóp
        var iconW = 16; // Icon Garmin gốc 16x16 chuẩn sắc nét
        var totalBarW = batW + (iconCount > 0 ? (iconSpacing + iconCount * iconW + (iconCount - 1) * iconSpacing) : 0);
        var curX = centerX - (totalBarW / 2);
        var topY = 14;

        // Vẽ viên pin nền trắng có số pin bên trong
        drawCompactWhiteBattery(dc, curX, topY + 1, battery);
        curX += batW + iconSpacing;

        // Vẽ các icon trạng thái bitmap 16x16 Garmin
        if (showAlarm && iconAlarm != null) {
            dc.drawBitmap(curX, topY, iconAlarm);
            curX += iconW + iconSpacing;
        }
        if (showPhone && iconPhoneBt != null) {
            dc.drawBitmap(curX, topY, iconPhoneBt);
            curX += iconW + iconSpacing;
        }
        if (showMoon && iconMoon != null) {
            dc.drawBitmap(curX, topY, iconMoon);
            curX += iconW + iconSpacing;
        }
        if (showHeadphone && iconHeadphone != null) {
            dc.drawBitmap(curX, topY, iconHeadphone);
            curX += iconW + iconSpacing;
        }

        // 4. NGÀY: "T2 - 23/11" & ÂM LỊCH (dateY = 32)
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        var lunar = LunarCalendar.getLunarDate(dateInfo.year, dateInfo.month, dateInfo.day);

        var dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        var dayOfWeekStr = dayNames[dateInfo.day_of_week - 1];
        var solarStr = Lang.format("$1$ - $2$/$3$", [dayOfWeekStr, dateInfo.day.format("%02d"), dateInfo.month.format("%02d")]);
        var lunarStr = lunar.toString();

        var dateY = 32;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 38, dateY, Graphics.FONT_XTINY, solarStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 40, dateY, Graphics.FONT_XTINY, lunarStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 5. GIỜ - PHÚT: CĂN GIỮA CHUẨN, KHÔNG BỊ THANH VẠCH ĐÈ LÊN SỐ
        var timeY = 28;
        var timeFont = Graphics.FONT_NUMBER_HOT;
        var colonDim = dc.getTextDimensions(":", timeFont);
        var colonHalfWidth = colonDim[0] / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // 1. Dấu hai chấm (:) ở đúng tâm màn hình (centerX)
        dc.drawText(centerX, timeY, timeFont, ":", Graphics.TEXT_JUSTIFY_CENTER);

        // 2. Số Giờ (bên trái dấu hai chấm)
        dc.drawText(centerX - colonHalfWidth - 1, timeY, timeFont, hourStr, Graphics.TEXT_JUSTIFY_RIGHT);

        // 3. Số Phút (bên phải dấu hai chấm)
        var minX = centerX + colonHalfWidth + 1;
        dc.drawText(minX, timeY, timeFont, minStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 4. Số Giây: Đặt ngay bên phải số phút
        if (isAwake) {
            var secFont = Graphics.FONT_TINY;
            var minDim = dc.getTextDimensions(minStr, timeFont);
            dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
            var secX = minX + minDim[0] + 3;
            var secY = 78;
            dc.drawText(secX, secY, secFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 6. VÙNG TỪ VỰNG
        var word = vocabManager.getCurrentWord();
        var totalWords = vocabManager.getTotalWords();
        var currentVocabIdx = vocabManager.getCurrentIndex();

        var segBarWidth = 160;
        var barHeight = 3;

        // A. THANH TRÊN: vạch phân cách nằm dưới đáy số giờ phút (topBarY = 100)
        var topBarY = 100;
        drawSegmentedBar(dc, centerX, topBarY, segBarWidth, barHeight, totalWords, currentVocabIdx, COLOR_GREEN_MAIN, true);

        // B. NỘI DUNG TỪ VỰNG
        // Dòng 1: TỪ VỰNG (Xanh lá) + Từ loại (Xanh dương)
        var wordFont = Graphics.FONT_MEDIUM;
        var wordDim = dc.getTextDimensions(word.word, wordFont);
        var posFont = Graphics.FONT_XTINY;
        var posDim = dc.getTextDimensions(word.pos, posFont);
        var wordPosGap = 6;
        var totalWordW = wordDim[0] + wordPosGap + posDim[0];

        if (totalWordW > 175) {
            wordFont = Graphics.FONT_SMALL;
            wordDim = dc.getTextDimensions(word.word, wordFont);
            totalWordW = wordDim[0] + wordPosGap + posDim[0];
        }

        var startWordX = centerX - (totalWordW / 2);
        var wordY = 106;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startWordX, wordY, wordFont, word.word, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(0x40C4FF, Graphics.COLOR_TRANSPARENT);
        var posOffsetY = (wordDim[1] - posDim[1]) / 2;
        dc.drawText(startWordX + wordDim[0] + wordPosGap, wordY + posOffsetY, posFont, word.pos, Graphics.TEXT_JUSTIFY_LEFT);

        // Dòng 2: PHIÊN ÂM IPA (Vàng kim) - font phoneticFont hỗ trợ IPA chuẩn
        var phoneticY = 127;
        var pFont = (phoneticFont != null) ? phoneticFont : Graphics.FONT_XTINY;
        dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, phoneticY, pFont, word.phonetic, Graphics.TEXT_JUSTIFY_CENTER);

        // Dòng 3: NGHĨA TIẾNG VIỆT (Trắng) - dùng FONT_XTINY hiển thị đầy đủ, không tràn màn hình tròn
        var meaningY = 145;
        var meaningFont = Graphics.FONT_XTINY;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, meaningY, meaningFont, word.meaning, Graphics.TEXT_JUSTIFY_CENTER);

        // C. THANH DƯỚI: TRÙNG SỐ VẠCH TIẾN ĐỘ BƯỚC CHÂN
        var botBarY = 164;
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo != null && actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var activeStepSegs = ((steps * totalWords * 1.0) / stepGoal).toNumber();
        if (activeStepSegs > totalWords) {
            activeStepSegs = totalWords;
        }
        drawSegmentedBar(dc, centerX, botBarY, segBarWidth, barHeight, totalWords, activeStepSegs, COLOR_GREEN_MAIN, false);

        // 7. DƯỚI CÙNG: BƯỚC CHÂN THỰC TẾ BÊN TRÁI | NHỊP TIM BÊN PHẢI
        var rowY = 175;
        var stepStr = steps.toString();
        var hrStr = getHeartRate();

        var botFont = Graphics.FONT_XTINY;
        var stepDim = dc.getTextDimensions(stepStr, botFont);
        var sepDim = dc.getTextDimensions("|", botFont);
        var hrDim = dc.getTextDimensions(hrStr, botFont);

        var footW = 16;
        var footH = 16;
        var heartW = 16;
        var heartH = 16;
        var gap = 4;
        var sepMargin = 8;

        var leftBlockW = footW + gap + stepDim[0];
        var sepW = sepDim[0];
        var rightBlockW = heartW + gap + hrDim[0];
        var totalRowW = leftBlockW + sepMargin + sepW + sepMargin + rightBlockW;
        var rowStartX = centerX - (totalRowW / 2);

        // A. Bên trái: Icon bước chân + số bước thực tế
        if (iconFootprints != null) {
            dc.drawBitmap(rowStartX, rowY, iconFootprints);
        }
        var stepTextY = rowY + (footH - stepDim[1]) / 2;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rowStartX + footW + gap, stepTextY, botFont, stepStr, Graphics.TEXT_JUSTIFY_LEFT);

        // B. Ở giữa: Dấu phân cách |
        var sepX = rowStartX + leftBlockW + sepMargin + (sepW / 2);
        var sepTextY = rowY + (footH - sepDim[1]) / 2;
        dc.setColor(COLOR_SEG_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sepX, sepTextY, botFont, "|", Graphics.TEXT_JUSTIFY_CENTER);

        // C. Bên phải: Icon nhịp tim + nhịp tim
        var rightStartX = rowStartX + leftBlockW + sepMargin + sepW + sepMargin;
        if (iconHeart != null) {
            dc.drawBitmap(rightStartX, rowY, iconHeart);
        }
        var hrTextY = rowY + (heartH - hrDim[1]) / 2;
        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightStartX + heartW + gap, hrTextY, botFont, hrStr, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Lấy thông tin nhịp tim thời gian thực
    private function getHeartRate() as String {
        var hr = null;
        var actInfo = Activity.getActivityInfo();
        if (actInfo != null && actInfo.currentHeartRate != null) {
            hr = actInfo.currentHeartRate;
        } else {
            var hrIter = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrIter != null) {
                var sample = hrIter.next();
                if (sample != null && sample.heartRate != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hr = sample.heartRate;
                }
            }
        }
        if (hr != null && hr > 0) {
            return hr.toString();
        }
        return "--";
    }

    // Vẽ thanh đứt đoạn (Segmented Bar) với hình chữ nhật sắc nét
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
            dc.fillRectangle(sX, y, segWidth, barH);
        }
    }

    // Icon Pin nhỏ gọn có số pin bên trong nền trắng (hoặc đỏ khi pin yếu)
    private function drawCompactWhiteBattery(dc as Graphics.Dc, x as Number, y as Number, pct as Number) as Void {
        var w = 26;
        var h = 13;
        var isLow = (pct <= 20);
        var bgColor = isLow ? COLOR_RED_ALERT : COLOR_WHITE_ICON;
        var textColor = isLow ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        // 1. Thân pin nền trắng bo nhẹ góc 2px
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, 2);

        // 2. Chóp pin cực dương bên phải (2x5px)
        dc.fillRoundedRectangle(x + w, y + 4, 2, 5, 1);

        // 3. Chữ số pin: căn giữa tuyệt đối theo thân pin
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        var batStr = Lang.format("$1$", [pct]);
        var bodyCenterX = x + (w / 2);
        var bodyCenterY = y + (h / 2);
        dc.drawText(bodyCenterX, bodyCenterY, Graphics.FONT_XTINY, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
