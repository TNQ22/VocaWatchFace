import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

class EnglishWatchFaceApp extends Application.AppBase {

    private var watchView as EnglishWatchFaceView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Đăng ký tiến trình chạy ngầm định kỳ (mỗi 6 tiếng hoặc 24 tiếng tải từ mới 1 lần)
        if (Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(6 * 3600)); // 6 giờ
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        watchView = new EnglishWatchFaceView();
        return [ watchView ];
    }

    // Khi người dùng bấm lưu cấu hình trên ứng dụng Garmin Connect trên điện thoại
    function onSettingsChanged() as Void {
        if (watchView != null) {
            watchView.onSettingsChanged();
        }
        WatchUi.requestUpdate();
    }

    // Nhận dữ liệu từ vựng mới được tải về từ Web API thông qua ServiceDelegate
    function onBackgroundData(data) as Void {
        if (data != null && data instanceof Array) {
            Storage.setValue("WebWordsCache", data);
            if (watchView != null) {
                watchView.reloadWordsFromCache();
            }
            WatchUi.requestUpdate();
        }
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [ new WebSyncServiceDelegate() ];
    }
}

function getApp() as EnglishWatchFaceApp {
    return Application.getApp() as EnglishWatchFaceApp;
}
