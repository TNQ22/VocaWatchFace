#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
==============================================================================
VocaWatchFace - Backend API Server Mẫu (Python 3)
==============================================================================
Chức năng:
1. Cung cấp API từ vựng JSON chuẩn cho đồng hồ Garmin qua HTTP GET.
2. Hỗ trợ phân loại chủ đề linh hoạt:
   - GET /daily-words (Toàn bộ hoặc mặc định)
   - GET /daily-words?topic=hospitality (Chuyên ngành Khách sạn)
   - GET /daily-words?topic=hotel_it    (IT Khách sạn & Công nghệ)
   - GET /daily-words?topic=ielts       (IELTS / Học thuật)
   - GET /daily-words?topic=general     (Giao tiếp)
   - GET /daily-words?topic=fitness     (Chạy bộ / Thể thao)
3. TỰ ĐỘNG HÓA PHIÊN ÂM IPA & NGHĨA TIẾNG VIỆT:
   - Tự động tra cứu Free Dictionary API để lấy IPA và loại từ (n., v., adj.).
   - Tự động dịch nghĩa tiếng Việt qua Google Translate endpoint.
==============================================================================
"""

import http.server
import socketserver
import json
import urllib.request
import urllib.parse
from typing import Dict, List, Any

PORT = 8080

# Kho từ vựng mẫu theo các chủ đề chuyên sâu
TOPIC_DATABASE: Dict[str, List[Dict[str, str]]] = {
    "hospitality": [
        {"w": "CONCIERGE", "p": "n.", "ph": "/kɔːn.siˈeəʒ/", "m": "Lễ tân hỗ trợ khách, dịch vụ trợ giúp"},
        {"w": "OCCUPANCY", "p": "n.", "ph": "/ˈɒk.jə.pən.si/", "m": "Công suất phòng, tỷ lệ lấp đầy"},
        {"w": "AMENITIES", "p": "n.", "ph": "/əˈmiː.nə.tiz/", "m": "Tiện nghi phòng (minibar, đồ dùng)"},
        {"w": "CHECK-IN", "p": "n./v.", "ph": "/ˈtʃek.ɪn/", "m": "Thủ tục nhận phòng của khách"},
        {"w": "UPGRADE", "p": "v./n.", "ph": "/ʌpˈɡreɪd/", "m": "Nâng cấp lên hạng phòng cao hơn"},
        {"w": "HOSPITALITY", "p": "n.", "ph": "/ˌhɒs.pɪˈtæl.ə.ti/", "m": "Ngành khách sạn, lòng hiếu khách"},
        {"w": "BELLHOP", "p": "n.", "ph": "/ˈbel.hɒp/", "m": "Nhân viên hỗ trợ hành lý khách sạn"},
        {"w": "HOUSEKEEPING", "p": "n.", "ph": "/ˈhaʊsˌkiː.pɪŋ/", "m": "Bộ phận buồng phòng, dọn dẹp vệ sinh"},
        {"w": "FOLIO", "p": "n.", "ph": "/ˈfəʊ.li.əʊ/", "m": "Hồ sơ chi tiêu, hóa đơn tổng của phòng"},
        {"w": "COMPLIMENTARY", "p": "adj.", "ph": "/ˌkɒm.plɪˈmen.tər.i/", "m": "Miễn phí kèm theo dịch vụ"},
        {"w": "TURNDOWN", "p": "n.", "ph": "/ˈtɜːn.daʊn/", "m": "Dịch vụ dọn giường buổi tối cho khách"}
    ],
    "hotel_it": [
        {"w": "PMS", "p": "n.", "ph": "/ˌpiː.emˈes/", "m": "Hệ thống quản lý khách sạn tổng thể"},
        {"w": "POS", "p": "n.", "ph": "/ˌpiː.əʊˈes/", "m": "Hệ thống bán hàng quầy bar / nhà hàng"},
        {"w": "CHANNEL MGR", "p": "n.", "ph": "/ˈtʃæn.əl ˈmæn.ɪ.dʒər/", "m": "Phần mềm quản lý kênh bán phòng online"},
        {"w": "KEYCARD", "p": "n.", "ph": "/ˈkiː.kɑːd/", "m": "Thẻ từ mở khóa phòng điện tử"},
        {"w": "DOOR LOCK", "p": "n.", "ph": "/dɔːr lɒk/", "m": "Hệ thống khóa cửa RFID / Bluetooth"},
        {"w": "HSIA", "p": "n.", "ph": "/ˌeɪtʃ.es.aɪˈeɪ/", "m": "Hệ thống Internet tốc độ cao khách sạn"},
        {"w": "PAYMENT GATE", "p": "n.", "ph": "/ˈpeɪ.mənt ɡeɪt/", "m": "Cổng thanh toán thẻ / ví điện tử"},
        {"w": "NIGHT AUDIT", "p": "n.", "ph": "/naɪt ˈɔː.dɪt/", "m": "Kiểm toán đêm, chốt số liệu hệ thống"},
        {"w": "OTA SYNC", "p": "n.", "ph": "/ˌəʊ.tiːˈeɪ sɪŋk/", "m": "Đồng bộ phòng với Agoda, Booking..."},
        {"w": "KIOSK", "p": "n.", "ph": "/ˈkiː.ɒsk/", "m": "Máy tự làm thủ tục nhận / trả phòng"},
        {"w": "INTERFACE", "p": "n.", "ph": "/ˈɪn.tə.feɪs/", "m": "Giao diện kết nối các hệ thống phần mềm"},
        {"w": "PBX", "p": "n.", "ph": "/ˌpiː.biːˈeks/", "m": "Tổng đài điện thoại nội bộ khách sạn"}
    ],
    "general": [
        {"w": "APPRECIATE", "p": "v.", "ph": "/əˈpriː.ʃi.eɪt/", "m": "Trân trọng, cảm kích, đánh giá cao"},
        {"w": "COLLABORATE", "p": "v.", "ph": "/kəˈlæb.ə.reɪt/", "m": "Hợp tác, cùng làm việc"},
        {"w": "PERSPECTIVE", "p": "n.", "ph": "/pəˈspek.tɪv/", "m": "Góc nhìn, quan điểm cá nhân"},
        {"w": "OPPORTUNITY", "p": "n.", "ph": "/ˌɒp.əˈtʃuː.nə.ti/", "m": "Cơ hội, thời cơ thuận lợi"},
        {"w": "COMMUNICATE", "p": "v.", "ph": "/kəˈmjuː.nɪ.keɪt/", "m": "Giao tiếp, trao đổi thông tin"},
        {"w": "COURTESY", "p": "n.", "ph": "/ˈkɜː.tə.si/", "m": "Lịch sự, nhã nhặn, tôn trọng"}
    ],
    "ielts": [
        {"w": "METICULOUS", "p": "adj.", "ph": "/məˈtɪk.jə.ləs/", "m": "Tỉ mỉ, cẩn thận từng chi tiết"},
        {"w": "SUBSTANTIATE", "p": "v.", "ph": "/səbˈstæn.ʃi.eɪt/", "m": "Chứng minh, xác thực luận điểm"},
        {"w": "UBIQUITOUS", "p": "adj.", "ph": "/juːˈbɪk.wɪ.təs/", "m": "Phổ biến, có mặt khắp nơi"},
        {"w": "PARADIGM", "p": "n.", "ph": "/ˈpær.ə.daɪm/", "m": "Mô hình, khuôn mẫu chuẩn mực"},
        {"w": "INEVITABLE", "p": "adj.", "ph": "/ɪnˈev.ɪ.tə.bəl/", "m": "Không thể tránh khỏi, tất yếu"}
    ],
    "fitness": [
        {"w": "CADENCE", "p": "n.", "ph": "/ˈkeɪ.dəns/", "m": "Nhịp chân (bước/phút khi chạy)"},
        {"w": "ENDURANCE", "p": "n.", "ph": "/ɪnˈdʊr.əns/", "m": "Sức bền, độ dẻo dai thể lực"},
        {"w": "PACE", "p": "n./v.", "ph": "/peɪs/", "m": "Tốc độ chạy (phút/km)"},
        {"w": "RECOVERY", "p": "n.", "ph": "/rɪˈkʌv.ɚ.i/", "m": "Hồi phục cơ thể sau tập luyện"},
        {"w": "HYDRATION", "p": "n.", "ph": "/haɪˈdreɪ.ʃən/", "m": "Bổ sung nước cho cơ thể"}
    ]
}


def auto_enrich_word(word_text: str) -> Dict[str, str]:
    """
    Tự động tra cứu loại từ, phiên âm IPA từ Free Dictionary API
    và tự động dịch nghĩa tiếng Việt qua Google Translate endpoint.
    Chỉ cần cung cấp đúng từ tiếng Anh!
    """
    clean_w = word_text.strip().lower()
    res = {
        "w": word_text.strip().upper(),
        "p": "n.",
        "ph": f"/{clean_w}/",
        "m": ""
    }

    # 1. Tra cứu Free Dictionary API
    try:
        dict_url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{urllib.parse.quote(clean_w)}"
        req = urllib.request.Request(dict_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=3) as response:
            data = json.loads(response.read().decode('utf-8'))
            if data and isinstance(data, list) and len(data) > 0:
                item = data[0]
                if item.get("phonetic"):
                    res["ph"] = item["phonetic"]
                elif item.get("phonetics"):
                    for ph in item["phonetics"]:
                        if ph.get("text"):
                            res["ph"] = ph["text"]
                            break
                if item.get("meanings") and len(item["meanings"]) > 0:
                    pos = item["meanings"][0].get("partOfSpeech", "n.")
                    if pos == "noun": res["p"] = "n."
                    elif pos == "verb": res["p"] = "v."
                    elif pos == "adjective": res["p"] = "adj."
                    elif pos == "adverb": res["p"] = "adv."
                    else: res["p"] = pos[:3] + "."
    except Exception:
        pass

    # 2. Dịch tự động sang tiếng Việt
    try:
        trans_url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q={urllib.parse.quote(clean_w)}"
        req = urllib.request.Request(trans_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=3) as response:
            tdata = json.loads(response.read().decode('utf-8'))
            if tdata and len(tdata) > 0 and tdata[0] and len(tdata[0]) > 0:
                res["m"] = tdata[0][0][0]
    except Exception:
        res["m"] = clean_w

    return res


class VocabRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        query = urllib.parse.parse_qs(parsed.query)

        # Endpoint trả về danh sách từ vựng
        if parsed.path.startswith("/daily-words"):
            topic = query.get("topic", [""])[0].lower().strip()
            
            # Nếu có tham số ?enrich=WORD thì tự động tạo đầy đủ p, ph, m
            enrich_word = query.get("enrich", [""])[0].strip()
            if enrich_word:
                word_data = [auto_enrich_word(enrich_word)]
                self._send_json(word_data)
                return

            if topic in TOPIC_DATABASE:
                words = TOPIC_DATABASE[topic]
            elif topic == "all":
                words = []
                for t_words in TOPIC_DATABASE.values():
                    words.extend(t_words)
            else:
                # Mặc định kết hợp khách sạn và IT khách sạn
                words = TOPIC_DATABASE["hospitality"] + TOPIC_DATABASE["hotel_it"]

            self._send_json(words)
        else:
            super().do_GET()

    def _send_json(self, data: Any):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response_bytes = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.wfile.write(response_bytes)


if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), VocabRequestHandler) as httpd:
        print(f"================================================================")
        print(f"🚀 VocaWatchFace API Server đang chạy tại: http://localhost:{PORT}")
        print(f"================================================================")
        print(f"1. Khách sạn:      http://localhost:{PORT}/daily-words?topic=hospitality")
        print(f"2. IT Khách sạn:   http://localhost:{PORT}/daily-words?topic=hotel_it")
        print(f"3. Giao tiếp:      http://localhost:{PORT}/daily-words?topic=general")
        print(f"4. IELTS:          http://localhost:{PORT}/daily-words?topic=ielts")
        print(f"5. Thể thao:       http://localhost:{PORT}/daily-words?topic=fitness")
        print(f"6. Tự động tra từ: http://localhost:{PORT}/daily-words?enrich=CONCIERGE")
        print(f"================================================================")
        httpd.serve_forever()
