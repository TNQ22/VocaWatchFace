/**
 * ==============================================================================
 * GOOGLE APPS SCRIPT CHO VocaWatchFace (GARMIN)
 * ==============================================================================
 * Hướng dẫn cài đặt trên Google Sheet:
 * 1. Tạo 1 Google Sheet mới.
 * 2. Đặt tên các cột ở Hàng 1:
 *    - Cột A: Word      (Từ vựng tiếng Anh, ví dụ: CONCIERGE)
 *    - Cột B: POS       (Loại từ, ví dụ: n., v., adj.)
 *    - Cột C: Phonetic  (Phiên âm IPA, ví dụ: /kɔːn.siˈeəʒ/)
 *    - Cột D: Meaning   (Nghĩa tiếng Việt ngắn gọn)
 *    - Cột E: Topic     (Chủ đề, ví dụ: hotel, it, ielts, general...)
 * 
 * 3. TỰ ĐỘNG HÓA TRÊN SHEET (Không cần gõ tay):
 *    - Cột D (Nghĩa): Gõ công thức: =GOOGLETRANSLATE(A2, "en", "vi")
 *    - Cột B & C: Có thể dùng hàm tùy chỉnh =GET_POS(A2) và =GET_IPA(A2) bên dưới.
 * 
 * 4. Triển khai API (Deploy):
 *    - Vào Tiện ích mở rộng (Extensions) -> Apps Script.
 *    - Dán toàn bộ nội dung file này vào.
 *    - Bấm nút "Triển khai" (Deploy) -> "Tùy chọn triển khai mới" (New deployment).
 *    - Chọn loại: "Ứng dụng web" (Web App).
 *    - Ai có quyền truy cập (Who has access): "Bất kỳ ai" (Anyone).
 *    - Sao chép Web App URL nhận được (dạng https://script.google.com/macros/s/.../exec)
 *    - Dán URL đó vào ô "Web API Cập nhật từ" (ApiUrl) trên ứng dụng Garmin Connect!
 * ==============================================================================
 */

// Hàm API chính phục vụ cho đồng hồ Garmin (HTTP GET)
function doGet(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var data = sheet.getDataRange().getValues();
    
    // Đọc tham số lọc theo topic từ URL nếu có (ví dụ: ?topic=hotel)
    var requestedTopic = (e && e.parameter && e.parameter.topic) ? e.parameter.topic.toLowerCase().trim() : "";
    
    var words = [];
    
    // Bỏ qua dòng tiêu đề (hàng 0), duyệt từ hàng 1
    for (var i = 1; i < data.length; i++) {
      var row = data[i];
      var w = String(row[0] || "").trim();
      if (!w) continue;
      
      var p = String(row[1] || "").trim();
      var ph = String(row[2] || "").trim();
      var m = String(row[3] || "").trim();
      var topic = String(row[4] || "").toLowerCase().trim();
      
      // Lọc theo topic nếu người dùng yêu cầu
      if (requestedTopic && topic && topic !== requestedTopic) {
        continue;
      }
      
      // Nếu thiếu loại từ hoặc phiên âm, tự động gọi từ điển bổ sung
      if (!p || !ph) {
        var autoInfo = fetchDictionaryInfo(w);
        if (!p && autoInfo.pos) p = autoInfo.pos;
        if (!ph && autoInfo.phonetic) ph = autoInfo.phonetic;
      }
      
      // Nếu thiếu nghĩa tiếng Việt, tự động dịch bằng Google Translate
      if (!m) {
        try {
          m = LanguageApp.translate(w, 'en', 'vi');
        } catch (err) {
          m = "";
        }
      }
      
      words.push({
        "w": w.toUpperCase(),
        "p": p || "n.",
        "ph": ph || ("/" + w.toLowerCase() + "/"),
        "m": m
      });
    }
    
    var jsonOutput = JSON.stringify(words);
    return ContentService.createTextOutput(jsonOutput)
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify([
      { "w": "ERROR", "p": "err.", "ph": "/ˈer.ər/", "m": "Lỗi lấy dữ liệu Sheet: " + error.toString() }
    ])).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Tự động tra cứu loại từ và phiên âm IPA từ Free Dictionary API
 */
function fetchDictionaryInfo(word) {
  var cleanWord = word.trim().toLowerCase();
  var result = { pos: "", phonetic: "" };
  try {
    var url = "https://api.dictionaryapi.dev/api/v2/entries/en/" + encodeURIComponent(cleanWord);
    var response = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
    if (response.getResponseCode() === 200) {
      var json = JSON.parse(response.getContentText());
      if (json && json.length > 0) {
        var entry = json[0];
        
        // 1. Tìm phiên âm IPA
        if (entry.phonetic) {
          result.phonetic = entry.phonetic;
        } else if (entry.phonetics && entry.phonetics.length > 0) {
          for (var k = 0; k < entry.phonetics.length; k++) {
            if (entry.phonetics[k].text) {
              result.phonetic = entry.phonetics[k].text;
              break;
            }
          }
        }
        
        // 2. Tìm loại từ (noun -> n., verb -> v., adjective -> adj., adverb -> adv.)
        if (entry.meanings && entry.meanings.length > 0) {
          var part = entry.meanings[0].partOfSpeech;
          if (part === "noun") result.pos = "n.";
          else if (part === "verb") result.pos = "v.";
          else if (part === "adjective") result.pos = "adj.";
          else if (part === "adverb") result.pos = "adv.";
          else result.pos = part ? (part.substring(0, 3) + ".") : "n.";
        }
      }
    }
  } catch (e) {
    // Bỏ qua nếu lỗi mạng
  }
  return result;
}

/**
 * Hàm tùy chỉnh trong Google Sheet: =GET_IPA(A2)
 * Trả về phiên âm IPA của từ ở ô A2
 */
function GET_IPA(word) {
  if (!word) return "";
  var info = fetchDictionaryInfo(word);
  return info.phonetic || ("/" + String(word).toLowerCase() + "/");
}

/**
 * Hàm tùy chỉnh trong Google Sheet: =GET_POS(A2)
 * Trả về loại từ (n., v., adj., adv.) của từ ở ô A2
 */
function GET_POS(word) {
  if (!word) return "";
  var info = fetchDictionaryInfo(word);
  return info.pos || "n.";
}
