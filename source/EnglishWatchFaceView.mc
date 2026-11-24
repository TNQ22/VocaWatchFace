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

    // Loaded Resources
    private var iconAlarm as WatchUi.BitmapResource?;
    private var iconMoon as WatchUi.BitmapResource?;
    private var iconHeadphone as WatchUi.BitmapResource?;
    private var iconPhoneBt as WatchUi.BitmapResource?;
    private var iconFootprints as WatchUi.BitmapResource?;
    private var phoneticFont as WatchUi.FontResource?;

    // Bảng màu chuẩn Garmin (chuẩn palette 64 màu của MIP display)
    const COLOR_GREEN_MAIN = 0x00E676;  // Xanh lá thể thao chủ đạo
    const COLOR_RED_ALERT  = 0xFF5252;  // Đỏ cảnh báo / Âm lịch
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

        // 3. TOP STATUS BAR: Đẩy lên cao hơn (topY = 8) tạo không gian rộng rãi
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
        var batW = 24; // 22px thân + 2px chóp
        var iconW = 16; // Icon 16x16 chuẩn sắc nét
        var totalBarW = batW + (iconCount > 0 ? (iconSpacing + iconCount * iconW + (iconCount - 1) * iconSpacing) : 0);
        var curX = centerX - (totalBarW / 2);
        // Hạ thấp thanh thông báo xuống y=18 như cũ để 5 icon hiển thị đầy đủ, không bị viền tròn che khuất
        var topY = 18;

        // Vẽ viên pin
        drawCleanBattery(dc, curX, topY + 2, battery);
        curX += batW + iconSpacing;

        // Vẽ các icon trạng thái bitmap 14x14 sắc nét Garmin
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

        // 4. NGÀY: "T2 - 23/11" & ÂM LỊCH (dateY = 35)
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        var lunar = LunarCalendar.getLunarDate(dateInfo.year, dateInfo.month, dateInfo.day);

        var dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        var dayOfWeekStr = dayNames[dateInfo.day_of_week - 1];
        var solarStr = Lang.format("$1$ - $2$/$3$", [dayOfWeekStr, dateInfo.day.format("%02d"), dateInfo.month.format("%02d")]);
        var lunarStr = lunar.toString();

        var dateY = 35;
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - 36, dateY, Graphics.FONT_XTINY, solarStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX + 42, dateY, Graphics.FONT_XTINY, lunarStr, Graphics.TEXT_JUSTIFY_CENTER);

        // 5. GIỜ - PHÚT: NÂNG LÊN (timeY = 46) ĐỂ MỞ RỘNG VÙNG HỌC LÊN TRÊN VÀ TO RA
        var timeY = 46;
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
            var secY = timeY + 36;
            dc.drawText(secX, secY, secFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 6. VÙNG TỪ VỰNG: DÙNG FONT 17px TO RÕ, NÂNG CAO LÊN TRÊN
        var word = vocabManager.getCurrentWord();
        var totalWords = vocabManager.getTotalWords();
        var currentVocabIdx = vocabManager.getCurrentIndex();

        var segBarWidth = 180;
        var barHeight = 4;

        // A. THANH TRÊN: Đặt ngay sát dưới số giờ phút (y = 103), triệt tiêu khoảng trống thừa
        var topBarY = timeY + 57;
        drawSegmentedBar(dc, centerX, topBarY, segBarWidth, barHeight, totalWords, currentVocabIdx, COLOR_GREEN_MAIN, true);

        // B. NỘI DUNG TỪ VỰNG: Dùng font 17px Segoe UI (phoneticFont) to, rõ, thanh thoát
        var studyFont = (phoneticFont != null) ? phoneticFont : Graphics.FONT_TINY;
        var wordDim = dc.getTextDimensions(word.word, studyFont);
        var posDim = dc.getTextDimensions(word.pos, studyFont);
        var wordPosGap = 5;
        var totalWordW = wordDim[0] + wordPosGap + posDim[0];

        var startWordX = centerX - (totalWordW / 2);
        var wordY = topBarY + 5;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startWordX, wordY, studyFont, word.word, Graphics.TEXT_JUSTIFY_LEFT);

        dc.setColor(0x40C4FF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startWordX + wordDim[0] + wordPosGap, wordY, studyFont, word.pos, Graphics.TEXT_JUSTIFY_LEFT);

        // Dòng 2: PHIÊN ÂM IPA (Vàng kim) - font 17px sắc nét
        var phoneticY = wordY + wordDim[1] + 2;
        dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, phoneticY, studyFont, word.phonetic, Graphics.TEXT_JUSTIFY_CENTER);

        // Dòng 3: NGHĨA TIẾNG VIỆT (Trắng) - font 17px to rõ, dễ nhìn
        var phoneticDim = dc.getTextDimensions(word.phonetic, studyFont);
        var meaningY = phoneticY + phoneticDim[1] + 2;
        var meaningDim = dc.getTextDimensions(word.meaning, studyFont);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, meaningY, studyFont, word.meaning, Graphics.TEXT_JUSTIFY_CENTER);

        // C. THANH DƯỚI: TRÙNG SỐ VẠCH TIẾN ĐỘ BƯỚC CHÂN
        var botBarY = meaningY + meaningDim[1] + 4;
        var steps = (actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var activeStepSegs = ((steps * totalWords * 1.0) / stepGoal).toNumber();
        if (activeStepSegs > totalWords) {
            activeStepSegs = totalWords;
        }
        drawSegmentedBar(dc, centerX, botBarY, segBarWidth, barHeight, totalWords, activeStepSegs, COLOR_GREEN_MAIN, false);

        // 7. DƯỚI CÙNG: ICON DẤU CHÂN GARMIN SẮC NÉT + SỐ BƯỚC CHÂN FONT TO HƠN
        var stepTextY = botBarY + 5;
        var stepFont = Graphics.FONT_TINY;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        var stepsText = Lang.format("$1$ / $2$", [steps, stepGoal]);
        var stepTextDim = dc.getTextDimensions(stepsText, stepFont);
        var footW = 16;
        var footH = 16;
        var footGap = 5;
        var totalStepW = footW + footGap + stepTextDim[0];
        var footStartX = centerX - (totalStepW / 2);

        if (iconFootprints != null) {
            dc.drawBitmap(footStartX, stepTextY, iconFootprints);
        }
        var textOffsetY = (footH - stepTextDim[1]) / 2;
        dc.drawText(footStartX + footW + footGap, stepTextY + textOffsetY, stepFont, stepsText, Graphics.TEXT_JUSTIFY_LEFT);
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

    // Vẽ viên pin sắc nét phong cách Garmin
    private function drawCleanBattery(dc as Graphics.Dc, x as Number, y as Number, pct as Number) as Void {
        var w = 22;
        var h = 11;

        // 1. Viền ngoài viên pin bo góc nhẹ
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, 2);

        // 2. Cực dương bên phải (2x5px)
        dc.fillRectangle(x + w, y + 3, 2, 5);

        // 3. Mức pin sạc (Xanh lá nếu > 20%, Đỏ nếu <= 20%)
        var maxFillW = w - 4;
        var fillW = (maxFillW * pct) / 100;
        if (pct > 0 && fillW < 1) {
            fillW = 1;
        }
        if (fillW > maxFillW) {
            fillW = maxFillW;
        }

        if (pct <= 20) {
            dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        }

        if (fillW > 0) {
            dc.fillRectangle(x + 2, y + 2, fillW, h - 4);
        }
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
