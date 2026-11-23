import http.server
import socketserver
import json

PORT = 8080

# Danh sách từ vựng bạn muốn nạp vào đồng hồ
DAILY_VOCABULARY = [
    {
        "w": "CADENCE",
        "p": "n.",
        "ph": "/ˈkeɪ.dəns/",
        "m": "Nhịp chân (bước/phút)",
        "ex": "Aim for 170-180 cadence."
    },
    {
        "w": "ENDURANCE",
        "p": "n.",
        "ph": "/ɪnˈdʊr.əns/",
        "m": "Sức bền, khả năng chịu đựng",
        "ex": "Long slow runs build endurance."
    },
    {
        "w": "RECOVERY",
        "p": "n.",
        "ph": "/rɪˈkʌv.ɚ.i/",
        "m": "Hồi phục sau tập luyện",
        "ex": "Sleep is crucial for recovery."
    },
    {
        "w": "DISCIPLINE",
        "p": "n.",
        "ph": "/ˈdɪs.ə.plɪn/",
        "m": "Kỷ luật bản thân",
        "ex": "Discipline beats motivation."
    },
    {
        "w": "GRATITUDE",
        "p": "n.",
        "ph": "/ˈɡræt̬.ə.tuːd/",
        "m": "Lòng biết ơn",
        "ex": "Run with a sense of gratitude."
    }
]

class VocabHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response_bytes = json.dumps(DAILY_VOCABULARY, ensure_ascii=False).encode('utf-8')
        self.wfile.write(response_bytes)

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), VocabHandler) as httpd:
        print(f"API Server từ vựng đang chạy tại: http://localhost:{PORT}")
        print("Đồng hồ Garmin có thể gọi vào endpoint này để cập nhật từ vựng mới!")
        httpd.serve_forever()
