import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
const INFO_FONT = Graphics.FONT_MEDIUM;

// Shared by the warmup and the game screen: redraws every second and blocks touch while shown
class ActiveView extends WatchUi.View {

    private var refreshTimer as Timer.Timer?;
    private var touchLocked as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE] as Array<Sensor.SensorType>);
        var timer = new Timer.Timer();
        timer.start(method(:onRefresh), 1000, true);
        refreshTimer = timer;
    }

    function onHide() as Void {
        if (refreshTimer != null) {
            refreshTimer.stop();
            refreshTimer = null;
        }
        if (touchLocked) {
            touchLocked = !setTouchEnabled(true);
        }
    }

    function onRefresh() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        // Sweat and ball contact must not trigger anything; menus and dialogs keep touch.
        // Only allowed once the view is in the foreground, which is not yet the case during onShow.
        if (!touchLocked) {
            touchLocked = setTouchEnabled(false);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
    }

    private function setTouchEnabled(enabled as Boolean) as Boolean {
        if (!(WatchUi has :configureTouchEvents)) {
            return false;
        }
        try {
            return WatchUi.configureTouchEvents({:enabled => enabled});
        } catch (e) {
            return false;
        }
    }

    protected function drawClock(dc as Dc, y as Number) as Void {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12 == 0 ? 12 : hour % 12;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, y, INFO_FONT, hour.format("%02d") + ":" + clock.min.format("%02d"), CENTER);
    }

    protected function drawHeartRate(dc as Dc, y as Number) as Void {
        var heartRate = currentHeartRate();
        var text = heartRate != null ? heartRate.format("%d") : "--";
        var textWidth = dc.getTextWidthInPixels(text, INFO_FONT);
        var heartSize = 13;
        var spacing = 10;
        var totalWidth = heartSize * 2 + spacing + textWidth;
        var heartX = dc.getWidth() / 2 - totalWidth / 2 + heartSize;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        var radius = heartSize / 2;
        dc.fillCircle(heartX - radius, y - radius / 2, radius);
        dc.fillCircle(heartX + radius, y - radius / 2, radius);
        dc.fillPolygon([[heartX - heartSize, y - radius / 3], [heartX + heartSize, y - radius / 3], [heartX, y + heartSize]]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(heartX + heartSize + spacing, y, INFO_FONT, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function currentHeartRate() as Number? {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            return activityInfo.currentHeartRate;
        }
        return Sensor.getInfo().heartRate;
    }
}

class WarmupView extends ActiveView {

    function initialize() {
        ActiveView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        ActiveView.onUpdate(dc);
        var height = dc.getHeight();
        var centerX = dc.getWidth() / 2;
        var seconds = getApp().warmupSeconds();

        drawClock(dc, (height * 0.11).toNumber());
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.27, INFO_FONT, "Warmup", CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.48, Graphics.FONT_NUMBER_HOT,
            (seconds / 60).format("%02d") + ":" + (seconds % 60).format("%02d"), CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.68, Graphics.FONT_SMALL, "START: begin game", CENTER);

        drawHeartRate(dc, (height * 0.88).toNumber());
    }
}

class WarmupDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            beginPlay(true);
        } else if (key == WatchUi.KEY_ESC) {
            WatchUi.pushView(new WatchUi.Confirmation("Cancel warmup?"), new CancelWarmupConfirmationDelegate(), WatchUi.SLIDE_UP);
        }
        return true;
    }
}

class GameView extends ActiveView {

    private var sportIcon as WatchUi.BitmapResource?;

    function initialize() {
        ActiveView.initialize();
        var game = getApp().game;
        if (game != null) {
            sportIcon = WatchUi.loadResource(Sports.icon(game.sport)) as WatchUi.BitmapResource;
        }
    }

    function onUpdate(dc as Dc) as Void {
        ActiveView.onUpdate(dc);

        var game = getApp().game;
        if (game == null) {
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var homeX = (width * 0.30).toNumber();
        var awayX = (width * 0.70).toNumber();
        var scoreY = (height * 0.54).toNumber();

        drawClock(dc, (height * 0.11).toNumber());
        drawStatusLine(dc, game, centerX, (height * 0.24).toNumber());

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, height * 0.37, Graphics.FONT_SMALL, "Home", CENTER);
        dc.drawText(awayX, height * 0.37, Graphics.FONT_SMALL, "Away", CENTER);

        var homeText = game.homeScore.format("%02d");
        var awayText = game.awayScore.format("%02d");
        dc.drawText(homeX, scoreY, Graphics.FONT_NUMBER_HOT, homeText, CENTER);
        dc.drawText(awayX, scoreY, Graphics.FONT_NUMBER_HOT, awayText, CENTER);
        dc.drawText(centerX, scoreY, Graphics.FONT_MEDIUM, ":", CENTER);

        if (game.setFinished) {
            var x = besideScore(dc, game.homeWonLastSet(), homeX, awayX, homeText, awayText, 28);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            drawTrophy(dc, x, scoreY);
        } else if (game.isBeachVolleyball() || game.homeScore + game.awayScore > 0) {
            // At 0:0 the first rally decides the serve; only beach volleyball needs to know who started
            drawServeIndicator(dc, game, homeX, awayX, scoreY, homeText, awayText);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, height * 0.72, INFO_FONT, game.homeSets.format("%d"), CENTER);
        dc.drawText(awayX, height * 0.72, INFO_FONT, game.awaySets.format("%d"), CENTER);

        var icon = sportIcon;
        if (icon != null) {
            dc.drawBitmap(centerX - icon.getWidth() / 2, height * 0.72 - icon.getHeight() / 2, icon);
        }

        drawHeartRate(dc, (height * 0.88).toNumber());
    }

    private function drawStatusLine(dc as Dc, game as Game, centerX as Number, y as Number) as Void {
        var text = game.setNumber().format("%d") + ". Set - " + minutes(game.setSeconds());
        var font = INFO_FONT;
        if (game.setFinished) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            text = game.homeWonLastSet() ? "Home Wins" : "Away Wins";
        } else if (game.sideSwitchDue) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            text = "Switch sides";
            font = Graphics.FONT_SMALL;
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(centerX, y, font, text, CENTER);
    }

    private function besideScore(dc as Dc, home as Boolean, homeX as Number, awayX as Number,
            homeText as String, awayText as String, gap as Number) as Number {
        return home
            ? homeX - dc.getTextWidthInPixels(homeText, Graphics.FONT_NUMBER_HOT) / 2 - gap
            : awayX + dc.getTextWidthInPixels(awayText, Graphics.FONT_NUMBER_HOT) / 2 + gap;
    }

    private function drawServeIndicator(dc as Dc, game as Game, homeX as Number, awayX as Number,
            scoreY as Number, homeText as String, awayText as String) as Void {
        var beach = game.isBeachVolleyball();
        var x = besideScore(dc, game.homeServing, homeX, awayX, homeText, awayText, beach ? 28 : 22);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (beach) {
            var font = Graphics.FONT_XTINY;
            dc.fillCircle(x, scoreY, dc.getFontHeight(font) / 2 + 4);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, scoreY, font, game.currentServer().format("%d"), CENTER);
        } else {
            dc.fillCircle(x, scoreY, 9);
        }
    }

    private function drawTrophy(dc as Dc, x as Number, y as Number) as Void {
        var size = 14;
        var top = y - size;
        dc.fillRectangle(x - size, top, size * 2, size);
        dc.fillCircle(x, y, size);
        dc.setPenWidth(3);
        dc.drawCircle(x - size, top + size / 2, size / 2);
        dc.drawCircle(x + size, top + size / 2, size / 2);
        dc.setPenWidth(1);
        dc.fillRectangle(x - 3, y + size - 2, 6, size / 2);
        dc.fillRectangle(x - size * 2 / 3, y + size + size / 2 - 2, size * 4 / 3, 5);
    }
}

function minutes(seconds as Number) as String {
    return (seconds / 60).format("%d") + "'";
}

class GameDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var app = getApp();
        var game = app.game;
        var key = keyEvent.getKey();
        if (game == null) {
            return false;
        }

        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ESC || key == WatchUi.KEY_DOWN) {
            if (game.setFinished) {
                app.click();
                startNextSet(game);
                return true;
            }
            app.scorePoint(key == WatchUi.KEY_DOWN);
        } else if (key == WatchUi.KEY_ENTER) {
            // A running set with points is reset first; the game itself only ends from the winner screen or at 0:0
            if (!game.setFinished && game.homeScore + game.awayScore > 0) {
                confirmResetSet();
            } else {
                confirmEndGame();
            }
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            var menu = new GameMenu();
            WatchUi.pushView(menu, new GameMenuDelegate(menu), WatchUi.SLIDE_UP);
            return true;
        } else {
            return false;
        }
        WatchUi.requestUpdate();
        return true;
    }

    private function startNextSet(game as Game) as Void {
        var homeServes = game.defaultNextSetServerIsHome();
        if (game.isBeachVolleyball()) {
            WatchUi.pushView(buildServeMenu(homeServes), new ServeMenuDelegate(false, false), WatchUi.SLIDE_UP);
            return;
        }
        game.startNextSet(homeServes);
        WatchUi.requestUpdate();
    }
}
