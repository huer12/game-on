import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class GameOnApp extends Application.AppBase {

    public var sport as Number = Sports.BEACH_VOLLEYBALL;
    public var endScore as Number = 21;
    public var game as Game?;

    private var session as ActivityRecording.Session?;
    private var startMenu as StartMenu?;
    private var popTimer as Timer.Timer?;
    private var alertTimer as Timer.Timer?;

    function initialize() {
        AppBase.initialize();

        var savedSport = Storage.getValue("sport");
        var savedEndScore = Storage.getValue("endScore");
        if (savedSport instanceof Number && Sports.isValid(savedSport)) {
            sport = savedSport;
            endScore = Sports.defaultEndScore(sport);
        }
        if (savedEndScore instanceof Number) {
            endScore = savedEndScore;
        }
    }

    function onStop(state as Dictionary?) as Void {
        // Don't lose a recorded match when the system closes the app
        endGame();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var menu = new StartMenu();
        startMenu = menu;
        return [menu, new StartMenuDelegate(menu)];
    }

    function selectSport(newSport as Number) as Void {
        sport = newSport;
        endScore = Sports.defaultEndScore(newSport);
        saveSettings();
    }

    function selectEndScore(newEndScore as Number) as Void {
        endScore = newEndScore;
        if (game != null) {
            game.endScore = newEndScore;
        }
        saveSettings();
    }

    function startGame() as Void {
        game = new Game(sport, endScore);
        startRecording();
    }

    function scorePoint(homeScored as Boolean) as Void {
        var currentGame = game;
        if (currentGame == null) {
            return;
        }
        var setsBefore = currentGame.homeSets + currentGame.awaySets;
        currentGame.scorePoint(homeScored);

        if (currentGame.homeSets + currentGame.awaySets > setsBefore) {
            if (session != null) {
                session.addLap();
            }
            playVibration([new Attention.VibeProfile(100, 1000)]);
        } else if (currentGame.sideSwitchDue) {
            // Started right in the key handler, a short vibration was not noticeable on the fenix 8; delay it past the button press
            if (alertTimer != null) {
                alertTimer.stop();
            }
            var timer = new Timer.Timer();
            timer.start(method(:onSideSwitchAlert), 300, false);
            alertTimer = timer;
        }
    }

    function onSideSwitchAlert() as Void {
        alertTimer = null;
        playVibration([
            new Attention.VibeProfile(100, 300),
            new Attention.VibeProfile(0, 150),
            new Attention.VibeProfile(100, 300),
            new Attention.VibeProfile(0, 150),
            new Attention.VibeProfile(100, 300)
        ]);
    }

    function endGame() as Void {
        stopRecording();
        if (game != null) {
            History.save(game);
        }
        game = null;
        if (startMenu != null) {
            startMenu.refresh();
        }
    }

    // A Confirmation pops itself after its response, so the game view underneath can only be popped afterwards
    function returnToStartMenu() as Void {
        if (popTimer != null) {
            popTimer.stop();
        }
        var timer = new Timer.Timer();
        timer.start(method(:popGameView), 50, false);
        popTimer = timer;
    }

    function popGameView() as Void {
        popTimer = null;
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    private function saveSettings() as Void {
        Storage.setValue("sport", sport);
        Storage.setValue("endScore", endScore);
    }

    private function startRecording() as Void {
        stopRecording();

        var activitySport = Activity.SPORT_VOLLEYBALL;
        var activitySubSport = Activity.SUB_SPORT_GENERIC;
        if (sport == Sports.SQUASH) {
            activitySport = Activity.SPORT_RACKET;
            activitySubSport = Activity.SUB_SPORT_SQUASH;
        } else if (sport == Sports.FAUSTBALL) {
            activitySport = Activity.SPORT_TEAM_SPORT;
        }

        var newSession = ActivityRecording.createSession({
            :name => Sports.name(sport),
            :sport => activitySport,
            :subSport => activitySubSport
        });
        newSession.start();
        session = newSession;
    }

    private function stopRecording() as Void {
        if (session != null && session.isRecording()) {
            session.stop();
            session.save();
        }
        session = null;
    }

    private function playVibration(pattern as Array<Attention.VibeProfile>) as Void {
        if (Attention has :vibrate) {
            Attention.vibrate(pattern);
        }
    }
}

function getApp() as GameOnApp {
    return Application.getApp() as GameOnApp;
}
