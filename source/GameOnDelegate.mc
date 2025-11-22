import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Timer;

class GameOnDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new GameOnMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Handle screen tap - open menu
    function onTap(clickEvent as ClickEvent) as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new GameOnMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    // Handle key press events
    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var app = getApp();
        
        if (!app.gameActive) {
            // If no game is active, open menu on any key
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_UP || key == WatchUi.KEY_DOWN) {
                WatchUi.pushView(new Rez.Menus.MainMenu(), new GameOnMenuDelegate(), WatchUi.SLIDE_UP);
                return true;
            }
        } else {
            // Game is active - handle scoring
            if (key == WatchUi.KEY_UP) {
                // Top-left button - undo
                app.undoLastScore();
                WatchUi.requestUpdate();
                return true;
            } else if (key == WatchUi.KEY_DOWN) {
                // Bottom-left button - always increment home team (player)
                app.incrementPlayerScore();
                WatchUi.requestUpdate();
                return true;
            } else if (key == WatchUi.KEY_ENTER) {
                // Middle button - increment opponent/right score
                app.incrementOpponentScore();
                WatchUi.requestUpdate();
                return true;
            } else if (key == WatchUi.KEY_ESC) {
                // Bottom-right button (back) - increment opponent/right score
                app.incrementOpponentScore();
                WatchUi.requestUpdate();
                return true;
            }
        }
        
        return false;
    }
    
    // Handle back button long press
    function onBack() as Boolean {
        // Back button is now handled in onKey for scoring
        // Return false to allow default back behavior when not handled
        return false;
    }
    
    // Show confirmation dialog
    function showConfirmDialog(stopGame as Boolean) as Void {
        var message = stopGame ? 
            WatchUi.loadResource(Rez.Strings.confirm_stop_game) as String :
            WatchUi.loadResource(Rez.Strings.confirm_quit_app) as String;
        
        WatchUi.pushView(
            new ConfirmView(message),
            new ConfirmDelegate(stopGame),
            WatchUi.SLIDE_UP
        );
    }

}