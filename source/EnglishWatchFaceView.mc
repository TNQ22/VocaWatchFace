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
    private var badgeFont as WatchUi.FontResource?;
    private var dateFontRes as WatchUi.FontResource?;

    // Bảng màu chuẩn 64 màu phần cứng MIP Display của Garmin (tránh pha RGB khiến màu bị nhạt/lệch khi ra thực tế)
    const COLOR_GREEN_MAIN   = Graphics.COLOR_GREEN;   // 0x00FF00 - Xanh lục thuần (bỏ kênh xanh dương để không bị ngả cyan/teal)
    const COLOR_RED_ALERT    = Graphics.COLOR_RED;     // 0xFF0000 - Đỏ thuần (bỏ xanh lục/dương để không bị ngả cam)
    const COLOR_ORANGE_LUNAR = Graphics.COLOR_ORANGE;  // 0xFF5500 - Cam đậm chuẩn Garmin MIP
    const COLOR_SEG_BG       = Graphics.COLOR_DK_GRAY; // 0x555555 - Xám đậm hiển thị rõ ràng trên nền đen MIP
    const COLOR_YELLOW_SEC   = 0xFFFF00;               // 0xFFFF00 - Vàng thuần 64-màu MIP (G=FF, B=0; tránh COLOR_YELLOW 0xFFAA00 hơi cam và tránh 0xFFFF55 bị nhạt trắng)
    const COLOR_BLUE_POS     = Graphics.COLOR_BLUE;    // 0x00AAFF - Xanh dương thuần chuẩn Garmin (bỏ kênh đỏ để không ngả trắng)
    const COLOR_WHITE_ICON   = Graphics.COLOR_WHITE;   // 0xFFFFFF - Trắng cho toàn bộ icon trạng thái

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
        badgeFont = WatchUi.loadResource(Rez.Fonts.BadgeFont) as WatchUi.FontResource;
        dateFontRes = WatchUi.loadResource(Rez.Fonts.DateFont) as WatchUi.FontResource;
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

        // 3. NGÀY DƯƠNG & ÂM LỊCH ĐƯA LÊN TRÊN CÙNG (dateY = 19 -> ink 25..37)
        var now = Time.now();
        var dateInfo = Gregorian.info(now, Time.FORMAT_SHORT);
        var lunar = LunarCalendar.getLunarDate(dateInfo.year, dateInfo.month, dateInfo.day);

        var dayNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
        var dayOfWeekStr = dayNames[dateInfo.day_of_week - 1];
        var solarStr = Lang.format("$1$-$2$/$3$", [dayOfWeekStr, dateInfo.day.format("%02d"), dateInfo.month.format("%02d")]);
        var lunarStr = lunar.toString();

        var dateY = (dateFontRes != null) ? 17 : 15;
        var dateFont = (dateFontRes != null) ? dateFontRes : Graphics.FONT_XTINY;
        var solarDim = dc.getTextDimensions(solarStr, dateFont);
        var lunarDim = dc.getTextDimensions(lunarStr, dateFont);
        var dateGap = 8;
        var totalDateW = solarDim[0] + dateGap + lunarDim[0];
        var dateStartX = centerX - (totalDateW / 2);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateStartX, dateY, dateFont, solarStr, Graphics.TEXT_JUSTIFY_LEFT);

        var isSpecialLunar = (lunar.day == 1 || lunar.day == 14 || lunar.day == 15 || lunar.day == lunar.daysInMonth);
        dc.setColor(isSpecialLunar ? COLOR_RED_ALERT : COLOR_ORANGE_LUNAR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateStartX + solarDim[0] + dateGap, dateY, dateFont, lunarStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 4. GIỜ - PHÚT: ĐẨY LÊN NGAY DƯỚI NGÀY (timeY = 20 -> ink 43..88)
        var timeY = 20;
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
            var secY = 65;
            dc.drawText(secX, secY, secFont, secStr, Graphics.TEXT_JUSTIFY_LEFT);
        }

        // 5. VÙNG TỪ VỰNG CÂN ĐỐI Ở GIỮA MÀN HÌNH
        var word = vocabManager.getCurrentWord();
        var totalWords = vocabManager.getTotalWords();
        var currentVocabIdx = vocabManager.getCurrentIndex();

        var segBarWidth = 206;
        var barHeight = 3;

        // A. THANH TRÊN: (topBarY = 96, cách đáy số giờ phút 8px)
        var topBarY = 96;
        drawSegmentedBar(dc, centerX, topBarY, segBarWidth, barHeight, totalWords, currentVocabIdx, COLOR_GREEN_MAIN, true);

        // B. NỘI DUNG TỪ VỰNG
        // Dòng 1: TỪ VỰNG căn chính giữa (Xanh lá) + Từ loại tách riêng đặt bên phải ngang đáy (Xanh dương)
        var wordFont = Graphics.FONT_MEDIUM;
        var wordDim = dc.getTextDimensions(word.word, wordFont);
        var posFont = Graphics.FONT_XTINY;
        var posDim = dc.getTextDimensions(word.pos, posFont);
        var wordPosGap = 4;

        if ((wordDim[0] / 2) + wordPosGap + posDim[0] > 106) {
            wordFont = Graphics.FONT_SMALL;
            wordDim = dc.getTextDimensions(word.word, wordFont);
        }

        var wordY = 95;
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, wordY, wordFont, word.word, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(COLOR_BLUE_POS, Graphics.COLOR_TRANSPARENT);
        var posX = centerX + (wordDim[0] / 2) + wordPosGap;
        // Bù -3px để đáy chân chữ thường (n., v., adj.) nằm ngang hàng tuyệt đối với chân chữ in hoa của từ vựng
        var posY = wordY + wordDim[1] - posDim[1] - 3;
        dc.drawText(posX, posY, posFont, word.pos, Graphics.TEXT_JUSTIFY_LEFT);

        // Dòng 2: PHIÊN ÂM IPA (Vàng kim) - căn đều giữa từ tiếng Anh và nghĩa tiếng Việt, tránh đè dấu/descender
        var phoneticY = 123;
        var pFont = (phoneticFont != null) ? phoneticFont : Graphics.FONT_XTINY;
        dc.setColor(COLOR_YELLOW_SEC, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, phoneticY, pFont, word.phonetic, Graphics.TEXT_JUSTIFY_CENTER);

        // Dòng 3: NGHĨA TIẾNG VIỆT (Trắng) - hạ sát thanh dưới cho cân với thanh trên và không chạm phiên âm
        var meaningY = 147;
        var mFont = (meaningFont != null) ? meaningFont : ((phoneticFont != null) ? phoneticFont : Graphics.FONT_XTINY);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var meaningLines = splitTextToFit(dc, word.meaning, mFont, 218);
        dc.drawText(centerX, meaningY, mFont, meaningLines[0], Graphics.TEXT_JUSTIFY_CENTER);
        var extraMeaningH = 0;
        if (meaningLines.size() > 1) {
            dc.drawText(centerX, meaningY + 15, mFont, meaningLines[1], Graphics.TEXT_JUSTIFY_CENTER);
            extraMeaningH = 14;
        }

        // C. THANH DƯỚI: TRÙNG SỐ VẠCH TIẾN ĐỘ BƯỚC CHÂN
        var botBarY = 172 + extraMeaningH;
        var steps = (actInfo != null && actInfo.steps != null) ? actInfo.steps : 0;
        var stepGoal = (actInfo != null && actInfo.stepGoal != null && actInfo.stepGoal > 0) ? actInfo.stepGoal : 10000;
        var activeStepSegs = ((steps * totalWords * 1.0) / stepGoal).toNumber();
        if (activeStepSegs > totalWords) {
            activeStepSegs = totalWords;
        }
        drawSegmentedBar(dc, centerX, botBarY, segBarWidth, barHeight, totalWords, activeStepSegs, COLOR_GREEN_MAIN, false);

        // 6. BƯỚC CHÂN THỰC TẾ BÊN TRÁI | NHỊP TIM BÊN PHẢI (căn đều giữa botBarY=172 và botStatusY=207)
        var rowY = 182 + (extraMeaningH > 0 ? 9 : 0);
        var stepStr = steps.toString();
        var hrStr = getHeartRate();

        var botFont = (dateFontRes != null) ? dateFontRes : Graphics.FONT_TINY;
        var stepDim = dc.getTextDimensions(stepStr, botFont);
        var sepDim = dc.getTextDimensions("|", botFont);
        var hrDim = dc.getTextDimensions(hrStr, botFont);

        var footW = 18;
        var heartW = 18;
        var gap = 4;
        var sepMargin = 8;

        var leftBlockW = footW + gap + stepDim[0];
        var sepW = sepDim[0];
        var rightBlockW = heartW + gap + hrDim[0];
        var totalRowW = leftBlockW + sepMargin + sepW + sepMargin + rightBlockW;
        var rowStartX = centerX - (totalRowW / 2);

        // DateFont ink cao ~13px -> đặt tại rowY + 2 để cân giữa icon 18x18 (ink y=rowY+1..rowY+16)
        var botTextY = (dateFontRes != null) ? (rowY + 2) : (rowY - 6);

        // A. Bên trái: Icon bước chân + số bước thực tế
        if (iconFootprints != null) {
            dc.drawBitmap(rowStartX, rowY, iconFootprints);
        }
        dc.setColor(COLOR_GREEN_MAIN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rowStartX + footW + gap, botTextY, botFont, stepStr, Graphics.TEXT_JUSTIFY_LEFT);

        // B. Ở giữa: Dấu phân cách |
        var sepX = rowStartX + leftBlockW + sepMargin + (sepW / 2);
        dc.setColor(COLOR_SEG_BG, Graphics.COLOR_TRANSPARENT);
        dc.drawText(sepX, botTextY, botFont, "|", Graphics.TEXT_JUSTIFY_CENTER);

        // C. Bên phải: Icon nhịp tim + nhịp tim
        var rightStartX = rowStartX + leftBlockW + sepMargin + sepW + sepMargin;
        if (iconHeart != null) {
            dc.drawBitmap(rightStartX, rowY, iconHeart);
        }
        dc.setColor(COLOR_RED_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightStartX + heartW + gap, botTextY, botFont, hrStr, Graphics.TEXT_JUSTIFY_LEFT);

        // 7. CỤM TRẠNG THÁI & THÔNG BÁO Ở DƯỚI CÙNG
        //    Thứ tự: Pin -> Kết nối điện thoại -> Báo thức -> Không làm phiền -> Tai nghe -> Thông báo
        var battery = sysStats.battery.toNumber();
        var notifCount = (devSettings has :notificationCount && devSettings.notificationCount != null) ? devSettings.notificationCount : 0;
        var alarmCount = devSettings.alarmCount;
        var showPhone = devSettings.phoneConnected;
        var showAlarm = (alarmCount != null && alarmCount > 0);
        var showMoon = (devSettings has :doNotDisturb && devSettings.doNotDisturb);
        var showHeadphone = true;
        var showNotif = (notifCount > 0);

        var iconSpacing = 3;
        var batW = 29; // 26px thân bo tròn + 1px khe + 2px chóp
        var iconW = 16; // Icon Garmin 16x16 sắc nét
        var notifStr = showNotif ? (notifCount > 99 ? "99" : notifCount.toString()) : "";
        var notifW = showNotif ? (notifStr.length() >= 2 ? 20 : 16) : 0;

        var totalBarW = batW;
        if (showPhone) { totalBarW += iconSpacing + iconW; }
        if (showAlarm) { totalBarW += iconSpacing + iconW; }
        if (showMoon) { totalBarW += iconSpacing + iconW; }
        if (showHeadphone) { totalBarW += iconSpacing + iconW; }
        if (showNotif) { totalBarW += iconSpacing + notifW; }

        var curX = centerX - (totalBarW / 2);
        var botStatusY = 207 + (extraMeaningH > 0 ? 4 : 0);

        // 1. Pin
        drawCompactWhiteBattery(dc, curX, botStatusY, battery);
        curX += batW + iconSpacing;

        // 2. Kết nối điện thoại
        if (showPhone && iconPhoneBt != null) {
            dc.drawBitmap(curX, botStatusY, iconPhoneBt);
            curX += iconW + iconSpacing;
        }

        // 3. Báo thức
        if (showAlarm && iconAlarm != null) {
            dc.drawBitmap(curX, botStatusY, iconAlarm);
            curX += iconW + iconSpacing;
        }

        // 4. Không làm phiền
        if (showMoon && iconMoon != null) {
            dc.drawBitmap(curX, botStatusY, iconMoon);
            curX += iconW + iconSpacing;
        }

        // 5. Kết nối tai nghe
        if (showHeadphone && iconHeadphone != null) {
            dc.drawBitmap(curX, botStatusY, iconHeadphone);
            curX += iconW + iconSpacing;
        }

        // 6. Thông báo (số nằm trực tiếp bên trong icon)
        if (showNotif) {
            drawNotificationBadge(dc, curX, botStatusY, notifStr, notifW);
            curX += notifW + iconSpacing;
        }
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

    // Icon Pin bo tròn mềm kiểu iOS (nền xám phần trống, trắng phần pin còn lại, đỏ khi <=20%, chữ số đen căn giữa)
    private function drawCompactWhiteBattery(dc as Graphics.Dc, x as Number, y as Number, pct as Number) as Void {
        if (pct < 0) { pct = 0; }
        if (pct > 100) { pct = 100; }

        var w = 26;
        var h = 15;
        var isLow = (pct <= 20);
        var fillColor = isLow ? COLOR_RED_ALERT : COLOR_WHITE_ICON;
        var fillAaInner = isLow ? COLOR_RED_ALERT : Graphics.COLOR_LT_GRAY;

        // 1. Thân pin nền xám đậm hơn (DK_GRAY) để phân biệt rõ với phần trắng đã sạc
        drawSmoothBatteryPill(dc, x, y, w, h, Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);

        // 2. Phần pin đã sạc bên trái (cắt clip gọn theo đúng dáng bo tròn mềm)
        var fillW = ((w * pct) + 50) / 100;
        if (fillW > 0) {
            dc.setClip(x, y, fillW, h);
            drawSmoothBatteryPill(dc, x, y, w, h, fillColor, fillAaInner);
            dc.clearClip();
        }

        // 3. Chóp pin cực dương bên phải cách 1px (đầy 100% -> trắng, tụt <100% -> xám đậm đồng bộ thân pin)
        var tipColor = (pct >= 100) ? fillColor : Graphics.COLOR_DK_GRAY;
        dc.setColor(tipColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + w + 1, y + 4, 1, 7);
        dc.fillRectangle(x + w + 2, y + 5, 1, 5);

        // 4. Chữ số pin màu đen: nâng lên 1px tại y + 2
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var batStr = Lang.format("$1$", [pct]);
        var numFont = (badgeFont != null) ? badgeFont : Graphics.FONT_XTINY;
        if (badgeFont != null) {
            dc.drawText(x + (w / 2), y + 2, numFont, batStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x + (w / 2), y + (h / 2) - 2, numFont, batStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Vẽ thân bo góc nhỏ tròn mềm (r=2 symmetric soft AA ở cả 2 cạnh góc)
    private function drawSmoothBatteryPill(dc as Graphics.Dc, x as Number, y as Number, w as Number, h as Number, color as Number, aaColor as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + 2, y, w - 4, 1);
        dc.fillRectangle(x + 1, y + 1, w - 2, 1);
        dc.fillRectangle(x, y + 2, w, h - 4);
        dc.fillRectangle(x + 1, y + h - 2, w - 2, 1);
        dc.fillRectangle(x + 2, y + h - 1, w - 4, 1);

        dc.setColor(aaColor, Graphics.COLOR_TRANSPARENT);
        dc.drawPoint(x + 1, y);
        dc.drawPoint(x, y + 1);
        dc.drawPoint(x + w - 2, y);
        dc.drawPoint(x + w - 1, y + 1);
        dc.drawPoint(x + 1, y + h - 1);
        dc.drawPoint(x, y + h - 2);
        dc.drawPoint(x + w - 2, y + h - 1);
        dc.drawPoint(x + w - 1, y + h - 2);
    }

    // Icon Thông báo nền trắng bo tròn mềm dạng bong bóng tin nhắn, ghi số thông báo trực tiếp bên trong
    private function drawNotificationBadge(dc as Graphics.Dc, x as Number, y as Number, notifStr as String, w as Number) as Void {
        var h = 15;
        drawSmoothBatteryPill(dc, x, y, w, h, COLOR_WHITE_ICON, Graphics.COLOR_LT_GRAY);
        // Đuôi nhọn bong bóng tin nhắn ở góc dưới bên trái
        dc.setColor(COLOR_WHITE_ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x + 3, y + h - 1], [x + 7, y + h - 1], [x + 2, y + h + 2]]);

        // Số thông báo màu đen: nâng lên 1px tại y + 2
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var numFont = (badgeFont != null) ? badgeFont : Graphics.FONT_XTINY;
        if (badgeFont != null) {
            dc.drawText(x + (w / 2), y + 2, numFont, notifStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x + (w / 2), y + (h / 2) - 2, numFont, notifStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
