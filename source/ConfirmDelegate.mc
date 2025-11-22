import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class ConfirmDelegate extends WatchUi.BehaviorDelegate {

    private var isStopGame as Boolean;

    function initialize(stopGame as Boolean) {
        BehaviorDelegate.initialize();
        isStopGame = stopGame;
    }

    // Handle key press events
    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_ENTER) {
            // Top right button (SELECT/ENTER) = YES (confirmed)
            if (isStopGame) {
                // Stop the game
                getApp().stopGame();
            } else {
                // Quit the app
                System.exit();
            }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            // Bottom left button (DOWN) = NO (cancel)
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        
        return false;
    }

    // Handle screen tap to cancel
    function onTap(clickEvent as ClickEvent) as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

}
