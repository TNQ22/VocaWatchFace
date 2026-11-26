import Toybox.Lang;
import Toybox.System;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Time;

class VocabularyItem {
    var word as String;
    var pos as String;        // v., n., adj., adv.
    var phonetic as String;   // Phiên âm IPA
    var meaning as String;    // Nghĩa tiếng Việt

    function initialize(w as String, p as String, ph as String, m as String) {
        word = w;
        pos = p;
        phonetic = ph;
        meaning = m;
    }
}

class VocabularyManager {
    private var words as Array<VocabularyItem>;
    private var currentIndex as Number = 0;
    private var lastSwitchEpoch as Number = 0;
    private var currentTopic as Number = 0;

    const MODE_INTERVAL = 0;
    const MODE_WRIST_SHAKE = 1;
    const MODE_HOURLY = 2;
    const MODE_DAILY = 3;

    const TOPIC_GENERAL     = 0;
    const TOPIC_IELTS       = 1;
    const TOPIC_FITNESS     = 2;
    const TOPIC_HOSPITALITY = 3;
    const TOPIC_HOTEL_IT    = 4;
    const TOPIC_CUSTOM      = 5;

    function initialize() {
        words = [];
        loadSavedState();
        refreshTopicWords();
    }

    private function loadSavedState() as Void {
        var savedIdx = Storage.getValue("VocabIndex");
        if (savedIdx != null && savedIdx instanceof Number) {
            currentIndex = savedIdx;
        }
        var savedEpoch = Storage.getValue("LastVocabEpoch");
        if (savedEpoch != null && savedEpoch instanceof Number) {
            lastSwitchEpoch = savedEpoch;
        } else {
            lastSwitchEpoch = Time.now().value();
        }
        var savedTopic = Storage.getValue("LastTopicId");
        if (savedTopic != null && savedTopic instanceof Number) {
            currentTopic = savedTopic;
        } else {
            currentTopic = getTopic();
        }
    }

    function getTopic() as Number {
        var topic = Application.Properties.getValue("VocabTopic");
        return (topic != null && topic instanceof Number) ? topic : TOPIC_GENERAL;
    }

    function refreshTopicWords() as Void {
        var activeTopic = getTopic();
        if (activeTopic != currentTopic) {
            currentTopic = activeTopic;
            currentIndex = 0;
            Storage.setValue("LastTopicId", currentTopic);
            Storage.setValue("VocabIndex", 0);
        }

        if (activeTopic == TOPIC_CUSTOM) {
            var loadedCustom = loadCustomWordsFromStorage();
            if (loadedCustom != null && loadedCustom.size() > 0) {
                words = loadedCustom;
            } else {
                words = getWordsForTopic(TOPIC_GENERAL);
            }
        } else {
            words = getWordsForTopic(activeTopic);
        }

        if (words.size() == 0) {
            words = [ new VocabularyItem("WELCOME", "v.", "/ˈwel.kəm/", "Chào mừng bạn mỗi ngày") ];
        }
        if (currentIndex >= words.size()) {
            currentIndex = 0;
            Storage.setValue("VocabIndex", 0);
        }
    }

    private function loadCustomWordsFromStorage() as Array<VocabularyItem>? {
        var cached = Storage.getValue("WebWordsCache");
        if (cached != null && cached instanceof Array) {
            var result = [] as Array<VocabularyItem>;
            for (var i = 0; i < cached.size(); i++) {
                var item = cached[i];
                if (item instanceof Dictionary) {
                    var w = item.get("w") != null ? item.get("w") : "";
                    var p = item.get("p") != null ? item.get("p") : "";
                    var ph = item.get("ph") != null ? item.get("ph") : "";
                    var m = item.get("m") != null ? item.get("m") : "";
                    if (w.length() > 0) {
                        result.add(new VocabularyItem(w, p, ph, m));
                    }
                }
            }
            if (result.size() > 0) {
                return result;
            }
        }
        return null;
    }

    private function getWordsForTopic(topic as Number) as Array<VocabularyItem> {
        if (topic == TOPIC_GENERAL) {
            return [
                new VocabularyItem("APPRECIATE", "v.", "/əˈpriː.ʃi.eɪt/", "Trân trọng, cảm kích, đánh giá cao"),
                new VocabularyItem("COLLABORATE", "v.", "/kəˈlæb.ə.reɪt/", "Hợp tác, cùng làm việc"),
                new VocabularyItem("PERSPECTIVE", "n.", "/pəˈspek.tɪv/", "Góc nhìn, quan điểm cá nhân"),
                new VocabularyItem("OPPORTUNITY", "n.", "/ˌɒp.əˈtʃuː.nə.ti/", "Cơ hội, thời cơ thuận lợi"),
                new VocabularyItem("COMMUNICATE", "v.", "/kəˈmjuː.nɪ.keɪt/", "Giao tiếp, trao đổi thông tin"),
                new VocabularyItem("COURTESY", "n.", "/ˈkɜː.tə.si/", "Lịch sự, nhã nhặn, tôn trọng"),
                new VocabularyItem("RECOMMEND", "v.", "/ˌrek.əˈmend/", "Gợi ý, giới thiệu, đề xuất"),
                new VocabularyItem("SINCERELY", "adv.", "/sɪnˈsɪə.li/", "Chân thành, thật lòng"),
                new VocabularyItem("FLEXIBLE", "adj.", "/ˈflek.sə.bəl/", "Linh hoạt, dễ thích ứng"),
                new VocabularyItem("CONVERSATION", "n.", "/ˌkɒn.vəˈseɪ.ʃən/", "Cuộc trò chuyện, đối thoại"),
                new VocabularyItem("ENTHUSIASM", "n.", "/ɪnˈθjuː.zi.æz.əm/", "Sự nhiệt huyết, hăng hái"),
                new VocabularyItem("COMPASSION", "n.", "/kəmˈpæʃ.ən/", "Lòng trắc ẩn, sự thấu cảm")
            ];
        } else if (topic == TOPIC_IELTS) {
            return [
                new VocabularyItem("METICULOUS", "adj.", "/məˈtɪk.jə.ləs/", "Tỉ mỉ, cẩn thận từng chi tiết"),
                new VocabularyItem("SUBSTANTIATE", "v.", "/səbˈstæn.ʃi.eɪt/", "Chứng minh, xác thực luận điểm"),
                new VocabularyItem("UBIQUITOUS", "adj.", "/juːˈbɪk.wɪ.təs/", "Phổ biến, có mặt khắp nơi"),
                new VocabularyItem("PARADIGM", "n.", "/ˈpær.ə.daɪm/", "Mô hình, khuôn mẫu chuẩn mực"),
                new VocabularyItem("INEVITABLE", "adj.", "/ɪnˈev.ɪ.tə.bəl/", "Không thể tránh khỏi, tất yếu"),
                new VocabularyItem("ELOQUENT", "adj.", "/ˈel.ə.kwənt/", "Hùng biện, diễn đạt lưu loát"),
                new VocabularyItem("PRAGMATIC", "adj.", "/præɡˈmæt.ɪk/", "Thực tế, coi trọng thực tiễn"),
                new VocabularyItem("AMBIGUOUS", "adj.", "/æmˈbɪɡ.ju.əs/", "Mơ hồ, nhiều cách hiểu"),
                new VocabularyItem("COGNIZANT", "adj.", "/ˈkɒɡ.nɪ.zənt/", "Nhận thức rõ, hiểu biết sâu"),
                new VocabularyItem("SCRUTINIZE", "v.", "/ˈskruː.tɪ.naɪz/", "Xem xét kỹ lưỡng, soi xét"),
                new VocabularyItem("FEASIBLE", "adj.", "/ˈfiː.zə.bəl/", "Khả thi, có thể thực hiện được"),
                new VocabularyItem("COMPREHENSIVE", "adj.", "/ˌkɒm.prɪˈhen.sɪv/", "Toàn diện, bao quát mọi mặt")
            ];
        } else if (topic == TOPIC_FITNESS) {
            return [
                new VocabularyItem("CADENCE", "n.", "/ˈkeɪ.dəns/", "Nhịp chân (bước/phút khi chạy)"),
                new VocabularyItem("ENDURANCE", "n.", "/ɪnˈdʊr.əns/", "Sức bền, độ dẻo dai thể lực"),
                new VocabularyItem("PACE", "n./v.", "/peɪs/", "Tốc độ chạy (phút/km)"),
                new VocabularyItem("RECOVERY", "n.", "/rɪˈkʌv.ɚ.i/", "Hồi phục cơ thể sau tập luyện"),
                new VocabularyItem("PERSEVERE", "v.", "/ˌpɜː.sɪˈvɪər/", "Kiên trì, bền bỉ vượt khó"),
                new VocabularyItem("RESILIENT", "adj.", "/rɪˈzɪl.jənt/", "Kiên cường, phục hồi nhanh"),
                new VocabularyItem("HYDRATION", "n.", "/haɪˈdreɪ.ʃən/", "Bổ sung nước cho cơ thể"),
                new VocabularyItem("AEROBIC", "adj.", "/eəˈrəʊ.bɪk/", "Hiếu khí, dùng oxy tạo năng lượng"),
                new VocabularyItem("STAMINA", "n.", "/ˈstæm.ɪ.nə/", "Sức chịu đựng, thể lực dồi dào"),
                new VocabularyItem("THRESHOLD", "n.", "/ˈθreʃ.həʊld/", "Ngưỡng lactate, giới hạn gắng sức"),
                new VocabularyItem("INTERVAL", "n.", "/ˈɪn.tə.vəl/", "Bài tập chạy biến tốc ngắt quãng"),
                new VocabularyItem("NUTRITION", "n.", "/njuːˈtrɪʃ.ən/", "Dinh dưỡng bổ trợ thể thao")
            ];
        } else if (topic == TOPIC_HOSPITALITY) {
            return [
                new VocabularyItem("CONCIERGE", "n.", "/kɔːn.siˈeəʒ/", "Lễ tân hỗ trợ khách, dịch vụ trợ giúp"),
                new VocabularyItem("OCCUPANCY", "n.", "/ˈɒk.jə.pən.si/", "Công suất phòng, tỷ lệ lấp đầy phòng"),
                new VocabularyItem("AMENITIES", "n.", "/əˈmiː.nə.tiz/", "Tiện nghi phòng (minibar, đồ cá nhân)"),
                new VocabularyItem("CHECK-IN", "n./v.", "/ˈtʃek.ɪn/", "Thủ tục nhận phòng của khách"),
                new VocabularyItem("UPGRADE", "v./n.", "/ʌpˈɡreɪd/", "Nâng cấp lên hạng phòng cao hơn"),
                new VocabularyItem("HOSPITALITY", "n.", "/ˌhɒs.pɪˈtæl.ə.ti/", "Ngành khách sạn, lòng hiếu khách"),
                new VocabularyItem("BELLHOP", "n.", "/ˈbel.hɒp/", "Nhân viên hỗ trợ hành lý"),
                new VocabularyItem("HOUSEKEEPING", "n.", "/ˈhaʊsˌkiː.pɪŋ/", "Bộ phận buồng phòng, dọn dẹp phòng"),
                new VocabularyItem("RESERVATION", "n.", "/ˌrez.əˈveɪ.ʃən/", "Hồ sơ đặt phòng, giữ chỗ trước"),
                new VocabularyItem("ITINERARY", "n.", "/aɪˈtɪn.ər.ər.i/", "Lịch trình tour, chuyến tham quan"),
                new VocabularyItem("FOLIO", "n.", "/ˈfəʊ.li.əʊ/", "Hồ sơ chi tiêu, hóa đơn tổng phòng"),
                new VocabularyItem("COMPLIMENTARY", "adj.", "/ˌkɒm.plɪˈmen.tər.i/", "Miễn phí đi kèm (dịch vụ ưu đãi)"),
                new VocabularyItem("TURNDOWN", "n.", "/ˈtɜːn.daʊn/", "Dịch vụ dọn giường buổi tối"),
                new VocabularyItem("FRONT DESK", "n.", "/frʌnt desk/", "Quầy tiếp tân khách sạn")
            ];
        } else if (topic == TOPIC_HOTEL_IT) {
            return [
                new VocabularyItem("PMS", "n.", "/ˌpiː.emˈes/", "Hệ thống quản lý khách sạn tổng thể"),
                new VocabularyItem("POS", "n.", "/ˌpiː.əʊˈes/", "Hệ thống bán hàng quầy bar / nhà hàng"),
                new VocabularyItem("CHANNEL MGR", "n.", "/ˈtʃæn.əl ˈmæn.ɪ.dʒər/", "Phần mềm quản lý kênh bán phòng online"),
                new VocabularyItem("KEYCARD", "n.", "/ˈkiː.kɑːd/", "Thẻ từ mở khóa phòng điện tử"),
                new VocabularyItem("DOOR LOCK", "n.", "/dɔːr lɒk/", "Hệ thống khóa cửa RFID / Bluetooth"),
                new VocabularyItem("HSIA", "n.", "/ˌeɪtʃ.es.aɪˈeɪ/", "Hệ thống Internet tốc độ cao khách sạn"),
                new VocabularyItem("PAYMENT GATE", "n.", "/ˈpeɪ.mənt ɡeɪt/", "Cổng thanh toán thẻ / ví điện tử"),
                new VocabularyItem("NIGHT AUDIT", "n.", "/naɪt ˈɔː.dɪt/", "Quy trình kiểm toán đêm trên hệ thống"),
                new VocabularyItem("OTA SYNC", "n.", "/ˌəʊ.tiːˈeɪ sɪŋk/", "Đồng bộ phòng với Agoda, Booking..."),
                new VocabularyItem("KIOSK", "n.", "/ˈkiː.ɒsk/", "Máy tự làm thủ tục nhận / trả phòng"),
                new VocabularyItem("INTERFACE", "n.", "/ˈɪn.tə.feɪs/", "Giao diện kết nối các hệ thống phần mềm"),
                new VocabularyItem("PBX", "n.", "/ˌpiː.biːˈeks/", "Tổng đài điện thoại nội bộ khách sạn"),
                new VocabularyItem("IPTV", "n.", "/ˌaɪ.piː.tiːˈviː/", "Truyền hình tương tác thông minh phòng"),
                new VocabularyItem("GRMS", "n.", "/ˌdʒiː.ɑːr.emˈes/", "Hệ thống điều khiển thiết bị trong phòng")
            ];
        }
        return [
            new VocabularyItem("WELCOME", "v.", "/ˈwel.kəm/", "Chào mừng bạn mỗi ngày")
        ];
    }

    function getSwitchMode() as Number {
        var mode = Application.Properties.getValue("WordSwitchMode");
        return (mode != null && mode instanceof Number) ? mode : MODE_WRIST_SHAKE;
    }

    function getIntervalMinutes() as Number {
        var mins = Application.Properties.getValue("WordIntervalMinutes");
        return (mins != null && mins instanceof Number && mins > 0) ? mins : 15;
    }

    function onWristGesture() as Void {
        if (getSwitchMode() == MODE_WRIST_SHAKE) {
            nextWord();
        }
    }

    function checkPeriodicUpdate() as Void {
        var mode = getSwitchMode();
        var nowEpoch = Time.now().value();

        if (mode == MODE_INTERVAL) {
            var intervalSecs = getIntervalMinutes() * 60;
            if (nowEpoch - lastSwitchEpoch >= intervalSecs) {
                nextWord();
                lastSwitchEpoch = nowEpoch;
                Storage.setValue("LastVocabEpoch", lastSwitchEpoch);
            }
        } else if (mode == MODE_HOURLY) {
            var clock = System.getClockTime();
            var targetIdx = clock.hour % words.size();
            if (targetIdx != currentIndex) {
                currentIndex = targetIdx;
                Storage.setValue("VocabIndex", currentIndex);
            }
        } else if (mode == MODE_DAILY) {
            var daysSinceEpoch = nowEpoch / 86400;
            var targetIdx = daysSinceEpoch % words.size();
            if (targetIdx != currentIndex) {
                currentIndex = targetIdx;
                Storage.setValue("VocabIndex", currentIndex);
            }
        }
    }

    function nextWord() as Void {
        if (words.size() > 0) {
            currentIndex = (currentIndex + 1) % words.size();
            Storage.setValue("VocabIndex", currentIndex);
        }
    }

    function getCurrentWord() as VocabularyItem {
        if (words.size() == 0) {
            return new VocabularyItem("LEARN", "v.", "/lɜːn/", "Học tập mỗi ngày");
        }
        var safeIdx = currentIndex % words.size();
        return words[safeIdx];
    }

    function getCurrentIndex() as Number {
        return currentIndex % (words.size() > 0 ? words.size() : 1);
    }

    function getTotalWords() as Number {
        return words.size();
    }

    function updateCustomWords(newWordList as Array<VocabularyItem>) as Void {
        if (newWordList != null && newWordList.size() > 0) {
            if (getTopic() == TOPIC_CUSTOM) {
                words = newWordList;
                currentIndex = 0;
                Storage.setValue("VocabIndex", 0);
            }
        }
    }
}
