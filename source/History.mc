import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

module History {

    const STORAGE_KEY = "lastGame";

    function save(game as Game) as Void {
        var hasOpenSet = !game.setFinished && game.homeScore + game.awayScore > 0;
        if (game.setResults.size() == 0 && !hasOpenSet) {
            return;
        }
        Storage.setValue(STORAGE_KEY, {
            "sport" => game.sport,
            "start" => game.startTime,
            "duration" => game.gameSeconds(),
            "homeSets" => game.homeSets,
            "awaySets" => game.awaySets,
            "sets" => game.setResults,
            "openSet" => hasOpenSet ? [game.homeScore, game.awayScore, game.setSeconds()] : null
        });
    }

    function buildMenu() as WatchUi.Menu2 {
        var saved = Storage.getValue(STORAGE_KEY);
        if (!(saved instanceof Dictionary)) {
            var empty = new WatchUi.Menu2({:title => "History"});
            empty.addItem(new WatchUi.MenuItem("No game yet", null, :none, null));
            return empty;
        }

        var menu = new WatchUi.Menu2({:title => Sports.name(saved["sport"] as Number)});
        var result = (saved["homeSets"] as Number).format("%d") + ":" + (saved["awaySets"] as Number).format("%d");
        menu.addItem(new WatchUi.MenuItem("Result " + result,
            minutes(saved["duration"] as Number) + ", " + dateText(saved["start"] as Number), :result, null));

        var sets = saved["sets"] as Array<Array<Number> >;
        for (var i = 0; i < sets.size(); i++) {
            menu.addItem(setItem(i + 1, sets[i], ""));
        }
        var openSet = saved["openSet"];
        if (openSet instanceof Array) {
            menu.addItem(setItem(sets.size() + 1, openSet as Array<Number>, ", not finished"));
        }
        return menu;
    }

    function setItem(number as Number, set as Array<Number>, note as String) as WatchUi.MenuItem {
        var label = "Set " + number.format("%d") + "   " + set[0].format("%d") + ":" + set[1].format("%d");
        return new WatchUi.MenuItem(label, minutes(set[2]) + note, number, null);
    }

    function dateText(epochSeconds as Number) as String {
        var info = Gregorian.info(new Time.Moment(epochSeconds), Time.FORMAT_SHORT);
        return (info.day as Number).format("%02d") + "." + (info.month as Number).format("%02d") + ". "
            + info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}
