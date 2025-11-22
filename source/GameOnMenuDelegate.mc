import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class GameOnMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        var app = getApp();
        
        if (item == :item_beachvolleyball) {
            // Beach volleyball: typically played to 21 points
            app.startNewGame("Beach Volleyball", 21);
        } else if (item == :item_squash) {
            // Squash: typically played to 11 points
            app.startNewGame("Squash", 11);
        } else if (item == :item_stop) {
            // Stop the current game (keeps sets)
            app.stopGame();
        } else if (item == :item_reset) {
            // Reset the game
            app.resetGame();
        }
    }

}