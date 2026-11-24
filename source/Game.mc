import Toybox.Lang;
import Toybox.Time;

class Game {

    private const MAX_UNDO_STEPS = 20;
    private const WIN_MARGIN = 2;

    public var sport as Number;
    public var endScore as Number;
    public var homeScore as Number = 0;
    public var awayScore as Number = 0;
    public var homeSets as Number = 0;
    public var awaySets as Number = 0;
    public var homeServing as Boolean = true;
    // Beach volleyball server per team: 0 = team has not served yet in this set, otherwise 1 or 2
    public var homeServer as Number = 0;
    public var awayServer as Number = 0;
    public var sideSwitchDue as Boolean = false;
    // The finished set stays on screen until the next set is started, so a wrong last point can still be undone
    public var setFinished as Boolean = false;
    // Each entry: [homeScore, awayScore, durationSeconds]
    public var setResults as Array<Array<Number> > = [] as Array<Array<Number> >;
    public var startTime as Number;
    public var warmupSeconds as Number = 0;

    private var homeServedFirstInSet as Boolean = true;
    private var setStartTime as Number;
    private var history as Array<Dictionary> = [] as Array<Dictionary>;

    function initialize(gameSport as Number, gameEndScore as Number) {
        sport = gameSport;
        endScore = gameEndScore;
        startTime = Time.now().value();
        setStartTime = startTime;
        beginSet(true);
    }

    function setNumber() as Number {
        return setFinished ? setResults.size() : setResults.size() + 1;
    }

    function isBeachVolleyball() as Boolean {
        return sport == Sports.BEACH_VOLLEYBALL;
    }

    function currentServer() as Number {
        return homeServing ? homeServer : awayServer;
    }

    function homeWonLastSet() as Boolean {
        var last = setResults[setResults.size() - 1];
        return last[0] > last[1];
    }

    function setSeconds() as Number {
        if (setFinished) {
            return setResults[setResults.size() - 1][2];
        }
        return Time.now().value() - setStartTime;
    }

    function gameSeconds() as Number {
        return Time.now().value() - startTime;
    }

    // Squash: the winner of a game serves first; the other sports alternate the first serve per set
    function defaultNextSetServerIsHome() as Boolean {
        return sport == Sports.SQUASH ? homeWonLastSet() : !homeServedFirstInSet;
    }

    function chooseFirstServer(home as Boolean) as Void {
        beginSet(home);
    }

    function scorePoint(homeScored as Boolean) as Void {
        if (setFinished) {
            return;
        }
        pushSnapshot();
        sideSwitchDue = false;

        if (homeScored) {
            homeScore++;
        } else {
            awayScore++;
        }

        // In Faustball the team that lost the rally serves next
        var homeServesNext = sport == Sports.FAUSTBALL ? !homeScored : homeScored;
        if (homeServesNext != homeServing) {
            giveServeTo(homeServesNext);
        }

        if (!finishSetIfWon()) {
            checkSideSwitch();
        }
    }

    function startNextSet(homeServesFirst as Boolean) as Void {
        if (!setFinished) {
            return;
        }
        pushSnapshot();
        setFinished = false;
        homeScore = 0;
        awayScore = 0;
        setStartTime = Time.now().value();
        beginSet(homeServesFirst);
    }

    function resetSet() as Void {
        if (setFinished) {
            return;
        }
        pushSnapshot();
        homeScore = 0;
        awayScore = 0;
        sideSwitchDue = false;
        setStartTime = Time.now().value();
        beginSet(homeServedFirstInSet);
    }

    function setScore(home as Number, away as Number) as Void {
        pushSnapshot();
        homeScore = home;
        awayScore = away;
        sideSwitchDue = false;
    }

    function undo() as Boolean {
        if (history.size() == 0) {
            return false;
        }
        restoreSnapshot(history[history.size() - 1]);
        history = history.slice(0, history.size() - 1) as Array<Dictionary>;
        return true;
    }

    // Beach volleyball: the two players of a team alternate each time the team wins the serve back
    private function giveServeTo(home as Boolean) as Void {
        homeServing = home;
        if (home) {
            homeServer = nextServer(homeServer);
        } else {
            awayServer = nextServer(awayServer);
        }
    }

    private function nextServer(current as Number) as Number {
        return current == 1 ? 2 : 1;
    }

    private function beginSet(homeServesFirst as Boolean) as Void {
        homeServedFirstInSet = homeServesFirst;
        homeServer = 0;
        awayServer = 0;
        giveServeTo(homeServesFirst);
    }

    private function finishSetIfWon() as Boolean {
        var homeWon = homeScore >= endScore && homeScore - awayScore >= WIN_MARGIN;
        var awayWon = awayScore >= endScore && awayScore - homeScore >= WIN_MARGIN;
        if (!homeWon && !awayWon) {
            return false;
        }
        setResults.add([homeScore, awayScore, Time.now().value() - setStartTime]);
        if (homeWon) {
            homeSets++;
        } else {
            awaySets++;
        }
        sideSwitchDue = false;
        setFinished = true;
        return true;
    }

    private function checkSideSwitch() as Void {
        if (!isBeachVolleyball()) {
            return;
        }
        var interval = endScore <= 15 ? 5 : 7;
        var total = homeScore + awayScore;
        sideSwitchDue = total > 0 && total % interval == 0;
    }

    private function pushSnapshot() as Void {
        history.add({
            :homeScore => homeScore,
            :awayScore => awayScore,
            :homeSets => homeSets,
            :awaySets => awaySets,
            :homeServing => homeServing,
            :homeServer => homeServer,
            :awayServer => awayServer,
            :sideSwitchDue => sideSwitchDue,
            :setFinished => setFinished,
            :setResults => setResults.slice(0, null),
            :homeServedFirst => homeServedFirstInSet,
            :setStart => setStartTime
        });
        if (history.size() > MAX_UNDO_STEPS) {
            history = history.slice(1, null) as Array<Dictionary>;
        }
    }

    private function restoreSnapshot(snapshot as Dictionary) as Void {
        homeScore = snapshot[:homeScore] as Number;
        awayScore = snapshot[:awayScore] as Number;
        homeSets = snapshot[:homeSets] as Number;
        awaySets = snapshot[:awaySets] as Number;
        homeServing = snapshot[:homeServing] as Boolean;
        homeServer = snapshot[:homeServer] as Number;
        awayServer = snapshot[:awayServer] as Number;
        sideSwitchDue = snapshot[:sideSwitchDue] as Boolean;
        setFinished = snapshot[:setFinished] as Boolean;
        setResults = snapshot[:setResults] as Array<Array<Number> >;
        homeServedFirstInSet = snapshot[:homeServedFirst] as Boolean;
        setStartTime = snapshot[:setStart] as Number;
    }
}
