import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class StartMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Game On"});
        addItem(new WatchUi.MenuItem("Start", null, :start, null));
        addItem(new WatchUi.MenuItem("Change sport", null, :sport, null));
        addItem(new WatchUi.MenuItem("Score", null, :score, null));
        addItem(new WatchUi.MenuItem("History", "Last game", :history, null));
        refresh();
    }

    function refresh() as Void {
        var app = getApp();
        var endScoreText = app.endScore.format("%d");
        setSubLabel(:start, Sports.name(app.sport) + ", " + endScoreText);
        setSubLabel(:sport, Sports.name(app.sport));
        setSubLabel(:score, endScoreText);
        WatchUi.requestUpdate();
    }

    private function setSubLabel(id as Symbol, text as String) as Void {
        var item = getItem(findItemById(id));
        if (item != null) {
            item.setSubLabel(text);
        }
    }
}

class StartMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as StartMenu;

    function initialize(startMenu as StartMenu) {
        Menu2InputDelegate.initialize();
        menu = startMenu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var app = getApp();
        var id = item.getId();

        if (id == :start) {
            startGame();
        } else if (id == :sport) {
            WatchUi.pushView(buildSportMenu(app.sport), new SportMenuDelegate(menu.method(:refresh)), WatchUi.SLIDE_LEFT);
        } else if (id == :score) {
            WatchUi.pushView(buildEndScoreMenu(app.endScore), new EndScoreMenuDelegate(menu.method(:refresh)), WatchUi.SLIDE_LEFT);
        } else if (id == :history) {
            WatchUi.pushView(History.buildMenu(), new WatchUi.Menu2InputDelegate(), WatchUi.SLIDE_LEFT);
        }
    }
}

function startGame() as Void {
    var app = getApp();
    if (app.sport == Sports.BEACH_VOLLEYBALL) {
        WatchUi.pushView(buildServeMenu(true), new ServeMenuDelegate(true), WatchUi.SLIDE_LEFT);
        return;
    }
    app.startGame();
    WatchUi.pushView(new GameView(), new GameDelegate(), WatchUi.SLIDE_LEFT);
}

function buildServeMenu(homeFocused as Boolean) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => "First serve"});
    menu.addItem(new WatchUi.MenuItem("Home serves", null, :home, null));
    menu.addItem(new WatchUi.MenuItem("Guest serves", null, :guest, null));
    menu.setFocus(homeFocused ? 0 : 1);
    return menu;
}

// Beach volleyball needs to know who served first in a set, otherwise the 1/2 server numbers drift
class ServeMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var newGame as Boolean;

    function initialize(startsNewGame as Boolean) {
        Menu2InputDelegate.initialize();
        newGame = startsNewGame;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var app = getApp();
        var homeServes = item.getId() == :home;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);

        if (newGame) {
            app.startGame();
            WatchUi.pushView(new GameView(), new GameDelegate(), WatchUi.SLIDE_LEFT);
        }
        var game = app.game;
        if (game == null) {
            return;
        }
        if (newGame) {
            game.chooseFirstServer(homeServes);
        } else {
            game.startNextSet(homeServes);
        }
        WatchUi.requestUpdate();
    }
}

function buildSportMenu(selected as Number) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => "Sport"});
    for (var i = 0; i < Sports.ALL.size(); i++) {
        var sport = Sports.ALL[i];
        menu.addItem(new WatchUi.MenuItem(Sports.name(sport), null, sport, null));
    }
    menu.setFocus(Sports.ALL.indexOf(selected));
    return menu;
}

function buildEndScoreMenu(selected as Number) as WatchUi.Menu2 {
    var menu = new WatchUi.Menu2({:title => "Score"});
    for (var i = 0; i < Sports.END_SCORES.size(); i++) {
        var score = Sports.END_SCORES[i];
        menu.addItem(new WatchUi.MenuItem(score.format("%d"), null, score, null));
    }
    var focus = Sports.END_SCORES.indexOf(selected);
    if (focus >= 0) {
        menu.setFocus(focus);
    }
    return menu;
}

class SportMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var onChanged as Method() as Void;

    function initialize(changedCallback as Method() as Void) {
        Menu2InputDelegate.initialize();
        onChanged = changedCallback;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        getApp().selectSport(item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        onChanged.invoke();
        startGame();
    }
}

class EndScoreMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var onChanged as Method() as Void;

    function initialize(changedCallback as Method() as Void) {
        Menu2InputDelegate.initialize();
        onChanged = changedCallback;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        getApp().selectEndScore(item.getId() as Number);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        onChanged.invoke();
    }
}

class GameMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Game"});
        addItem(new WatchUi.MenuItem("Undo last point", null, :undo, null));
        var game = getApp().game;
        if (game != null && !game.setFinished) {
            addItem(new WatchUi.MenuItem("Set score", null, :setScore, null));
        }
        addItem(new WatchUi.MenuItem("End score", null, :endScore, null));
        addItem(new WatchUi.MenuItem("End game", null, :endGame, null));
        addItem(new WatchUi.MenuItem("Exit app", null, :exitApp, null));
        refresh();
    }

    function refresh() as Void {
        var game = getApp().game;
        if (game == null) {
            return;
        }
        var endScoreItem = getItem(findItemById(:endScore));
        if (endScoreItem != null) {
            endScoreItem.setSubLabel(game.endScore.format("%d"));
        }
        WatchUi.requestUpdate();
    }
}

class GameMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as GameMenu;

    function initialize(gameMenu as GameMenu) {
        Menu2InputDelegate.initialize();
        menu = gameMenu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var app = getApp();
        var game = app.game;
        if (game == null) {
            return;
        }
        var id = item.getId();

        if (id == :undo) {
            game.undo();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :setScore) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            var scoreView = new SetScoreView(game.homeScore, game.awayScore);
            WatchUi.pushView(scoreView, new SetScoreDelegate(scoreView), WatchUi.SLIDE_UP);
        } else if (id == :endScore) {
            WatchUi.pushView(buildEndScoreMenu(game.endScore), new EndScoreMenuDelegate(menu.method(:refresh)), WatchUi.SLIDE_LEFT);
        } else if (id == :endGame) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            confirmEndGame();
        } else if (id == :exitApp) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(new WatchUi.Confirmation("Exit app?"), new ExitAppConfirmationDelegate(), WatchUi.SLIDE_UP);
        }
    }
}

function confirmEndGame() as Void {
    WatchUi.pushView(new WatchUi.Confirmation("End game?"), new EndGameConfirmationDelegate(), WatchUi.SLIDE_UP);
}

class EndGameConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var app = getApp();
            app.endGame();
            app.returnToStartMenu();
        }
        return true;
    }
}

class ExitAppConfirmationDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp().endGame();
            System.exit();
        }
        return true;
    }
}
