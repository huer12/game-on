import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SetScoreView extends WatchUi.View {

    public var home as Number;
    public var away as Number;
    public var editingHome as Boolean = true;

    function initialize(homeScore as Number, awayScore as Number) {
        View.initialize();
        home = homeScore;
        away = awayScore;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var homeX = (width * 0.30).toNumber();
        var awayX = (width * 0.70).toNumber();
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.18, Graphics.FONT_SMALL, "Set score", center);
        dc.drawText(homeX, height * 0.31, Graphics.FONT_SMALL, "Home", center);
        dc.drawText(awayX, height * 0.31, Graphics.FONT_SMALL, "Away", center);

        var scoreY = height * 0.47;
        dc.setColor(editingHome ? Graphics.COLOR_GREEN : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, scoreY, Graphics.FONT_NUMBER_HOT, home.format("%02d"), center);
        dc.setColor(editingHome ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(awayX, scoreY, Graphics.FONT_NUMBER_HOT, away.format("%02d"), center);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, height * 0.68, Graphics.FONT_XTINY, "UP + / DOWN -", center);
        dc.drawText(width / 2, height * 0.76, Graphics.FONT_XTINY, editingHome ? "START: next" : "START: save", center);
    }

    function change(delta as Number) as Void {
        if (editingHome) {
            home = clamp(home + delta);
        } else {
            away = clamp(away + delta);
        }
    }

    private function clamp(value as Number) as Number {
        return value < 0 ? 0 : value;
    }
}

class SetScoreDelegate extends WatchUi.InputDelegate {

    private var view as SetScoreView;

    function initialize(scoreView as SetScoreView) {
        InputDelegate.initialize();
        view = scoreView;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_UP) {
            view.change(1);
        } else if (key == WatchUi.KEY_DOWN) {
            view.change(-1);
        } else if (key == WatchUi.KEY_ENTER) {
            if (view.editingHome) {
                view.editingHome = false;
            } else {
                var game = getApp().game;
                if (game != null) {
                    game.setScore(view.home, view.away);
                }
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
        } else if (key == WatchUi.KEY_ESC) {
            if (view.editingHome) {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                return true;
            }
            view.editingHome = true;
        } else {
            return false;
        }
        WatchUi.requestUpdate();
        return true;
    }
}
