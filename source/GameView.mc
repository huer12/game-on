import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

class GameView extends WatchUi.View {

    private const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    private var refreshTimer as Timer.Timer?;
    private var sportIcon as WatchUi.BitmapResource?;
    private var touchLocked as Boolean = false;

    function initialize() {
        View.initialize();
        var game = getApp().game;
        if (game != null) {
            sportIcon = WatchUi.loadResource(Sports.icon(game.sport)) as WatchUi.BitmapResource;
        }
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

    // Sweat and ball contact must not trigger anything during rallies; menus and dialogs keep touch.
    // Only allowed once the view is in the foreground, which is not yet the case during onShow.
    private function lockTouch() as Void {
        if (!touchLocked) {
            touchLocked = setTouchEnabled(false);
        }
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

    function onRefresh() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        lockTouch();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var game = getApp().game;
        if (game == null) {
            return;
        }

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var homeX = (width * 0.30).toNumber();
        var awayX = (width * 0.70).toNumber();
        var scoreY = (height * 0.50).toNumber();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height * 0.12, Graphics.FONT_SMALL, clockText(), CENTER);
        drawStatusLine(dc, game, centerX, (height * 0.22).toNumber());

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, height * 0.32, Graphics.FONT_SMALL, "Home", CENTER);
        dc.drawText(awayX, height * 0.32, Graphics.FONT_SMALL, "Away", CENTER);

        var homeText = game.homeScore.format("%02d");
        var awayText = game.awayScore.format("%02d");
        dc.drawText(homeX, scoreY, Graphics.FONT_NUMBER_HOT, homeText, CENTER);
        dc.drawText(awayX, scoreY, Graphics.FONT_NUMBER_HOT, awayText, CENTER);
        dc.drawText(centerX, scoreY, Graphics.FONT_MEDIUM, ":", CENTER);

        if (game.setFinished) {
            var homeWon = game.homeWonLastSet();
            var x = besideScore(dc, homeWon, homeX, awayX, homeText, awayText, 28);
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            drawTrophy(dc, x, scoreY);
        } else if (game.isBeachVolleyball() || game.homeScore + game.awayScore > 0) {
            // At 0:0 the first rally decides the serve; only beach volleyball needs to know who started
            drawServeIndicator(dc, game, homeX, awayX, scoreY, homeText, awayText);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(homeX, height * 0.68, Graphics.FONT_SMALL, game.homeSets.format("%d"), CENTER);
        dc.drawText(awayX, height * 0.68, Graphics.FONT_SMALL, game.awaySets.format("%d"), CENTER);

        var icon = sportIcon;
        if (icon != null) {
            dc.drawBitmap(centerX - icon.getWidth() / 2, height * 0.68 - icon.getHeight() / 2, icon);
        }

        drawHeartRate(dc, centerX, (height * 0.86).toNumber());
    }

    private function drawStatusLine(dc as Dc, game as Game, centerX as Number, y as Number) as Void {
        var text = game.setNumber().format("%d") + ". Set - " + minutes(game.setSeconds());
        if (game.setFinished) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            text = game.homeWonLastSet() ? "Home Wins" : "Away Wins";
        } else if (game.sideSwitchDue) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            text = "Switch sides";
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(centerX, y, Graphics.FONT_SMALL, text, CENTER);
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
            var digit = game.currentServer().format("%d");
            var font = Graphics.FONT_XTINY;
            var radius = dc.getFontHeight(font) / 2 + 4;
            dc.fillCircle(x, scoreY, radius);
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, scoreY, font, digit, CENTER);
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

    private function drawHeartRate(dc as Dc, centerX as Number, y as Number) as Void {
        var heartRate = currentHeartRate();
        var text = heartRate != null ? heartRate.format("%d") : "--";
        var textWidth = dc.getTextWidthInPixels(text, Graphics.FONT_SMALL);
        var heartSize = 11;
        var spacing = 10;
        var totalWidth = heartSize * 2 + spacing + textWidth;
        var heartX = centerX - totalWidth / 2 + heartSize;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        drawHeart(dc, heartX, y, heartSize);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(heartX + heartSize + spacing, y, Graphics.FONT_SMALL, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawHeart(dc as Dc, x as Number, y as Number, size as Number) as Void {
        var radius = size / 2;
        dc.fillCircle(x - radius, y - radius / 2, radius);
        dc.fillCircle(x + radius, y - radius / 2, radius);
        dc.fillPolygon([[x - size, y - radius / 3], [x + size, y - radius / 3], [x, y + size]]);
    }

    private function currentHeartRate() as Number? {
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo != null && activityInfo.currentHeartRate != null) {
            return activityInfo.currentHeartRate;
        }
        return Sensor.getInfo().heartRate;
    }

    private function clockText() as String {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12 == 0 ? 12 : hour % 12;
        }
        return hour.format("%02d") + ":" + clock.min.format("%02d");
    }
}

function minutes(seconds as Number) as String {
    return (seconds / 60).format("%d") + "'";
}

class GameDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }

    // Touch is ignored on purpose: sweat and ball contact would trigger it during rallies
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var app = getApp();
        var game = app.game;
        var key = keyEvent.getKey();
        if (game == null) {
            return false;
        }

        if (key == WatchUi.KEY_UP || key == WatchUi.KEY_ESC || key == WatchUi.KEY_DOWN) {
            if (game.setFinished) {
                startNextSet(game);
                return true;
            }
            app.scorePoint(key == WatchUi.KEY_DOWN);
        } else if (key == WatchUi.KEY_ENTER) {
            confirmEndGame();
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
            WatchUi.pushView(buildServeMenu(homeServes), new ServeMenuDelegate(false), WatchUi.SLIDE_UP);
            return;
        }
        game.startNextSet(homeServes);
        WatchUi.requestUpdate();
    }
}
