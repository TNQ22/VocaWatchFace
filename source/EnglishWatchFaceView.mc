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
    private var meaningFont as WatchUi.FontResource?;

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
        meaningFont = WatchUi.loadResource(Rez.Fonts.MeaningFont) as WatchUi.FontResource;
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

        // 3. TOP STATUS BAR: Pin kiểu iOS (nền xám + phần sạc trắng, số đen) + Thông báo có số + 4 icon Garmin
        var battery = sysStats.battery.toNumber();
        var notifCount = (devSettings has :notificationCount && devSettings.notificationCount != null) ? devSettings.notificationCount : 0;
        var alarmCount = devSettings.alarmCount;
        var showNotif = (notifCount > 0);
        var showAlarm = (alarmCount != null && alarmCount > 0);
        var showPhone = devSettings.phoneConnected;
        var showMoon = (devSettings has :doNotDisturb && devSettings.doNotDisturb);
        var showHeadphone = true;

        var iconSpacing = 3;
        var batW = 29; // 26px thân bo tròn + 1px khe + 2px chóp
        var iconW = 16; // Icon Garmin 16x16 sắc nét
        var notifStr = showNotif ? (notifCount > 99 ? "99" : notifCount.toString()) : "";
        var notifW = showNotif ? (notifStr.length() >= 2 ? 20 : 16) : 0;

        var totalBarW = batW;
        if (showNotif) { totalBarW += iconSpacing + notifW; }
        if (showAlarm) { totalBarW += iconSpacing + iconW; }
        if (showPhone) { totalBarW += iconSpacing + iconW; }
        if (showMoon) { totalBarW += iconSpacing + iconW; }
        if (showHeadphone) { totalBarW += iconSpacing + iconW; }

        var curX = centerX - (totalBarW / 2);
        var topY = 14;

        // Vẽ viên pin giống IMG_0235: thân bo tròn nền xám, phần sạc trắng, số đen ở giữa
        drawCompactWhiteBattery(dc, curX, topY + 1, battery);
        curX += batW + iconSpacing;

        // Vẽ icon thông báo có số trực tiếp bên trong
        if (showNotif) {
            drawNotificationBadge(dc, curX, topY + 1, notifStr, notifW);
            curX += notifW + iconSpacing;
        }

        // Vẽ các icon trạng thái bitmap 16x16 theo mẫu IMG_0284
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

        // 4. NGÀY: "T2 - 23/11" & ÂM LỊCH (dateY = 30 -> ink 36..48)
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        var lunar = LunarCalendar.getLunarDate(dateInfo.year, dateInfo.month, dateInfo.day);

        var dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        var dayOfWeekStr = dayNames[dateInfo.day_of_week - 1];
        var solarStr = Lang.format("$1$ - $2$/$3$", [dayOfWeekStr, dateInfo.day.format("%02d"), dateInfo.month.format("%02d")]);
        var lunarStr = lunar.toString();

        var dateY = 30;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 38, dateY, Graphics.FONT_XTINY, solarStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 40, dateY, Graphics.FONT_XTINY, lunarStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 5. GIỜ - PHÚT: CĂN GIỮA CHUẨN, KHÔNG BỊ THANH VẠCH ĐÈ LÊN SỐ
        var timeY = 31;
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

        // 4. Số Giây: Đặt ngay bên phải số phút, đáy ngang với số phút
        if (isAwake) {
            var secFont = Graphics.FONT_TINY;
            var minDim = dc.getTextDimensions(minStr, timeFont);
            dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
            var secX = minX + minDim[0] + 3;
            var secY = 76;
            dc.drawText(secX, secY, secFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 6. VÙNG TỪ VỰNG
        var word = vocabManager.getCurrentWord();
        var totalWords = vocabManager.getTotalWords();
        var currentVocabIdx = vocabManager.getCurrentIndex();

        var segBarWidth = 160;
        var barHeight = 3;

        // A. THANH TRÊN: vạch phân cách nằm dưới đáy số giờ phút (topBarY = 105)
        var topBarY = 105;
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
        var wordY = 105;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startWordX, wordY, wordFont, word.word, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(0x40C4FF, Graphics.COLOR_TRANSPARENT);
        var posOffsetY = (wordDim[1] - posDim[1]) / 2;
        dc.drawText(startWordX + wordDim[0] + wordPosGap, wordY + posOffsetY, posFont, word.pos, Graphics.TEXT_JUSTIFY_LEFT);

        // Dòng 2: PHIÊN ÂM IPA (Vàng kim) - font phoneticFont hỗ trợ IPA chuẩn
        var phoneticY = 133;
        var pFont = (phoneticFont != null) ? phoneticFont : Graphics.FONT_XTINY;
        dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, phoneticY, pFont, word.phonetic, Graphics.TEXT_JUSTIFY_CENTER);

        // Dòng 3: NGHĨA TIẾNG VIỆT (Trắng) - dùng MeaningFont hỗ trợ đầy đủ dấu tiếng Việt
        var meaningY = 156;
        var mFont = (meaningFont != null) ? meaningFont : ((phoneticFont != null) ? phoneticFont : Graphics.FONT_XTINY);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var meaningLines = splitTextToFit(dc, word.meaning, mFont, 204);
        dc.drawText(centerX, meaningY, mFont, meaningLines[0], Graphics.TEXT_JUSTIFY_CENTER);
        var extraMeaningH = 0;
        if (meaningLines.size() > 1) {
            dc.drawText(centerX, meaningY + 16, mFont, meaningLines[1], Graphics.TEXT_JUSTIFY_CENTER);
            extraMeaningH = 16;
        }

        // C. THANH DƯỚI: TRÙNG SỐ VẠCH TIẾN ĐỘ BƯỚC CHÂN
        var botBarY = 180 + extraMeaningH;
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo != null && actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var activeStepSegs = ((steps * totalWords * 1.0) / stepGoal).toNumber();
        if (activeStepSegs > totalWords) {
            activeStepSegs = totalWords;
        }
        drawSegmentedBar(dc, centerX, botBarY, segBarWidth, barHeight, totalWords, activeStepSegs, COLOR_GREEN_MAIN, false);

        // 7. DƯỚI CÙNG: BƯỚC CHÂN THỰC TẾ BÊN TRÁI | NHỊP TIM BÊN PHẢI
        var rowY = 190 + extraMeaningH;
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

    // Chia text thành tối đa 2 dòng nếu vượt quá maxWidth để không tràn viền tròn
    private function splitTextToFit(dc as Graphics.Dc, text as String, font as Graphics.FontType, maxWidth as Number) as Array<String> {
        var dim = dc.getTextDimensions(text, font);
        if (dim[0] <= maxWidth) {
            return [text];
        }
        var len = text.length();
        var mid = len / 2;
        var splitIdx = -1;
        var bestDist = len;
        for (var i = 0; i < len; i++) {
            if (text.substring(i, i + 1).equals(" ")) {
                var dist = (i - mid).abs();
                if (dist < bestDist) {
                    bestDist = dist;
                    splitIdx = i;
                }
            }
        }
        if (splitIdx <= 0) {
            return [text];
        }
        var line1 = text.substring(0, splitIdx);
        var line2 = text.substring(splitIdx + 1, len);
        return [line1, line2];
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

    // Icon Pin bo tròn kiểu iOS (nền xám phần trống, trắng phần pin còn lại, đỏ khi <=20%, chữ số đen căn giữa)
    private function drawCompactWhiteBattery(dc as Graphics.Dc, x as Number, y as Number, pct as Number) as Void {
        if (pct < 0) { pct = 0; }
        if (pct > 100) { pct = 100; }

        var w = 26;
        var h = 14;
        var radius = 4;
        var isLow = (pct <= 20);
        var fillColor = isLow ? COLOR_RED_ALERT : COLOR_WHITE_ICON;

        // 1. Thân pin nền xám sáng cho phần chưa sạc
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, radius);

        // 2. Phần pin đã sạc bên trái (cắt clip gọn theo góc bo tròn)
        var fillW = ((w * pct) + 50) / 100;
        if (fillW > 0) {
            dc.setClip(x, y, fillW, h);
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, radius);
            dc.clearClip();
        }

        // 3. Chóp pin cực dương bên phải cách 1px (vẽ 2 cột tạo đầu bo tròn không bị CIQ lược bỏ):
        //    Đầy 100% -> chóp trắng; tụt dưới 100% -> chóp xám (hoặc đỏ nếu muốn? không, tụt dưới 100% phần phải màu xám nên chóp xám)
        var tipColor = (pct >= 100) ? fillColor : Graphics.COLOR_LT_GRAY;
        dc.setColor(tipColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + w + 1, y + 4, 1, 6);
        dc.fillRectangle(x + w + 2, y + 5, 1, 4);

        // 4. Chữ số pin màu đen: trừ 1px theo trục Y để bù padding trên của FONT_XTINY, cân chính giữa thân pin
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var batStr = Lang.format("$1$", [pct]);
        dc.drawText(x + (w / 2), y + (h / 2) - 1, Graphics.FONT_XTINY, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Icon Thông báo nền trắng bo tròn dạng bong bóng tin nhắn, ghi số thông báo trực tiếp bên trong
    private function drawNotificationBadge(dc as Graphics.Dc, x as Number, y as Number, notifStr as String, w as Number) as Void {
        var h = 14;
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, 4);
        // Đuôi nhọn bong bóng tin nhắn ở góc dưới bên trái
        dc.fillPolygon([[x + 3, y + h - 1], [x + 7, y + h - 1], [x + 2, y + h + 2]]);

        // Số thông báo màu đen: trừ 1px để cân chính giữa phần thân bong bóng (h=14)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + (w / 2), y + (h / 2) - 1, Graphics.FONT_XTINY, notifStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
