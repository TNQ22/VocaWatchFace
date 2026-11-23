import Toybox.Background;
import Toybox.System;
import Toybox.Communications;
import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;

// ServiceDelegate chạy ngầm theo định kỳ (Background Service) để gọi Web API
(:background)
class WebSyncServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var apiUrl = Application.Properties.getValue("ApiUrl");
        if (apiUrl != null && apiUrl instanceof String && apiUrl.length() > 8) {
            makeWebRequest(apiUrl);
        } else {
            Background.exit(null);
        }
    }

    private function makeWebRequest(url as String) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(
            url,
            null,
            options,
            method(:onReceiveWebResponse)
        );
    }

    function onReceiveWebResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Array) {
            // Trả dữ liệu từ vựng mới về cho Watch Face lưu vào Storage
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}
