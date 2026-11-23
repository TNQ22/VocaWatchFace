import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

module LunarCalendar {

    // Bảng dữ liệu nén âm lịch từ năm 2026 đến năm 2040
    // Cấu trúc 20 bit:
    // [19..16]: Tháng nhuận trong năm (0 nếu không có nhuận)
    // [15..4]: 12 bit cho 12 tháng thường (1 = 30 ngày, 0 = 29 ngày)
    // [3..0]: 1 nếu tháng nhuận có 30 ngày, 0 nếu 29 ngày
    const LUNAR_INFO = [
        0x06554, // 2026 (Bính Ngọ)
        0x056a0, // 2027 (Đinh Mùi)
        0x07120, // 2028 (Mậu Thân)
        0x06955, // 2029 (Kỷ Dậu)
        0x058a0, // 2030 (Canh Tuất)
        0x0b560, // 2031 (Tân Hợi)
        0x04b64, // 2032 (Nhâm Tý)
        0x0a570, // 2033 (Quý Sửu)
        0x052b0, // 2034 (Giáp Dần)
        0x0a935, // 2035 (Ất Mão)
        0x06aa0, // 2036 (Bính Thìn)
        0x0ad50, // 2037 (Đinh Tỵ)
        0x04b63, // 2038 (Mậu Ngọ)
        0x0a570, // 2039 (Kỷ Mùi)
        0x054e4  // 2040 (Canh Thân)
    ];

    const START_YEAR = 2026;
    // Mốc ngày 1 Tết Bính Ngọ 2026: ngày 17/02/2026 dương lịch
    const REF_YEAR = 2026;
    const REF_MONTH = 2;
    const REF_DAY = 17;

    class LunarDate {
        var day as Number = 1;
        var month as Number = 1;
        var year as Number = 2026;
        var isLeapMonth as Boolean = false;

        function toString() as String {
            var prefix = isLeapMonth ? "N" : "";
            return Lang.format("$1$$2$/$3$ AL", [prefix, day, month]);
        }
    }

    // Chuyển đổi từ ngày dương lịch (năm, tháng, ngày) sang âm lịch
    function getLunarDate(solarYear as Number, solarMonth as Number, solarDay as Number) as LunarDate {
        var result = new LunarDate();

        // Giới hạn an toàn từ 2026 đến 2040
        if (solarYear < START_YEAR || solarYear > (START_YEAR + LUNAR_INFO.size() - 1)) {
            result.day = solarDay;
            result.month = solarMonth;
            result.year = solarYear;
            return result;
        }

        // Mốc mùng 1 Tết Bính Ngọ 2026 (17/02/2026)
        var refMoment = Gregorian.moment({
            :year => REF_YEAR,
            :month => REF_MONTH,
            :day => REF_DAY,
            :hour => 0,
            :minute => 0
        });

        var targetMoment = Gregorian.moment({
            :year => solarYear,
            :month => solarMonth,
            :day => solarDay,
            :hour => 0,
            :minute => 0
        });

        var diffSeconds = targetMoment.compare(refMoment);
        var offsetDays = (diffSeconds / 86400).toNumber();

        // Nếu ngày trước mùng 1 Tết 2026, fallback về ngày cuối năm Ất Tỵ
        if (offsetDays < 0) {
            result.day = solarDay;
            result.month = 12;
            result.year = 2025;
            return result;
        }

        var lYear = START_YEAR;
        var daysInYear = 0;

        // Trừ bớt các năm âm lịch đã qua
        while (lYear < START_YEAR + LUNAR_INFO.size()) {
            daysInYear = getDaysInLunarYear(lYear);
            if (offsetDays < daysInYear) {
                break;
            }
            offsetDays -= daysInYear;
            lYear++;
        }

        result.year = lYear;

        // Tìm tháng âm lịch
        var leapMonth = getLeapMonth(lYear);
        var isLeap = false;
        var lMonth = 1;

        while (lMonth <= 12) {
            var daysInMonth = isLeap ? getDaysInLeapMonth(lYear) : getDaysInLunarMonth(lYear, lMonth);

            if (offsetDays < daysInMonth) {
                break;
            }
            offsetDays -= daysInMonth;

            // Xử lý tháng nhuận
            if (leapMonth > 0 && lMonth == leapMonth && !isLeap) {
                isLeap = true; // Đến tháng nhuận cùng số tháng
            } else {
                if (isLeap) {
                    isLeap = false;
                }
                lMonth++;
            }
        }

        result.month = lMonth;
        result.day = offsetDays + 1;
        result.isLeapMonth = isLeap;

        return result;
    }

    private function getDaysInLunarYear(year as Number) as Number {
        var idx = year - START_YEAR;
        if (idx < 0 || idx >= LUNAR_INFO.size()) {
            return 365;
        }
        var info = LUNAR_INFO[idx];
        var sum = 0;
        var mask = 0x8000;
        for (var i = 0; i < 12; i++) {
            sum += ((info & mask) != 0) ? 30 : 29;
            mask = mask >> 1;
        }
        if (getLeapMonth(year) > 0) {
            sum += getDaysInLeapMonth(year);
        }
        return sum;
    }

    private function getLeapMonth(year as Number) as Number {
        var idx = year - START_YEAR;
        if (idx < 0 || idx >= LUNAR_INFO.size()) {
            return 0;
        }
        return (LUNAR_INFO[idx] >> 16) & 0x0F;
    }

    private function getDaysInLeapMonth(year as Number) as Number {
        var idx = year - START_YEAR;
        if (idx < 0 || idx >= LUNAR_INFO.size()) {
            return 29;
        }
        return ((LUNAR_INFO[idx] & 0x01) != 0) ? 30 : 29;
    }

    private function getDaysInLunarMonth(year as Number, month as Number) as Number {
        var idx = year - START_YEAR;
        if (idx < 0 || idx >= LUNAR_INFO.size()) {
            return 30;
        }
        var mask = 0x8000 >> (month - 1);
        return ((LUNAR_INFO[idx] & mask) != 0) ? 30 : 29;
    }
}
