import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class ConfirmView extends WatchUi.View {

    private var message as String;
    private var messageLabel as WatchUi.Text?;

    function initialize(confirmMessage as String) {
        View.initialize();
        message = confirmMessage;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConfirmLayout(dc));
        messageLabel = View.findDrawableById("ConfirmMessage") as WatchUi.Text;
        if (messageLabel != null) {
            messageLabel.setText(message);
        }
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
    }

    function onHide() as Void {
    }

}
