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

    const MODE_INTERVAL = 0;
    const MODE_WRIST_SHAKE = 1;
    const MODE_HOURLY = 2;
    const MODE_DAILY = 3;

    function initialize() {
        words = [];
        loadDefaultWords();
        loadSavedState();
    }

    private function loadDefaultWords() as Void {
        words = [
            new VocabularyItem("CADENCE", "n.", "/ˈkeɪ.dəns/", "Nhịp chân (bước/phút khi chạy)"),
            new VocabularyItem("ENDURANCE", "n.", "/ɪnˈdʊr.əns/", "Sức bền, khả năng dẻo dai"),
            new VocabularyItem("PACE", "n./v.", "/peɪs/", "Tốc độ chạy (phút/km)"),
            new VocabularyItem("RECOVERY", "n.", "/rɪˈkʌv.ɚ.i/", "Hồi phục sau tập luyện"),
            new VocabularyItem("PERSEVERE", "v.", "/ˌpɜː.sɪˈvɪər/", "Kiên trì, bền bỉ vượt khó"),
            new VocabularyItem("RESILIENT", "adj.", "/rɪˈzɪl.jənt/", "Kiên cường, hồi phục nhanh")
        ];
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
            words = newWordList;
            currentIndex = 0;
            Storage.setValue("VocabIndex", 0);
        }
    }
}
