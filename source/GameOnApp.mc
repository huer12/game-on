import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.ActivityRecording;
import Toybox.Activity;

class GameOnApp extends Application.AppBase {
    
    // Game state variables
    public var playerScore as Number = 0;
    public var opponentScore as Number = 0;
    public var playerSets as Number = 0;
    public var opponentSets as Number = 0;
    public var maxScore as Number = 21;
    public var sportName as String = "";
    public var gameActive as Boolean = false;
    public var playerServing as Boolean = true; // true = player serves, false = opponent serves
    public var servingFromRight as Boolean = true; // true = right side, false = left side
    
    // Undo history - stores last 5 actions (1 = player, 2 = opponent)
    private var actionHistory as Array<Number> = [] as Array<Number>;
    
    // Activity recording session
    public var session as ActivityRecording.Session?;

    function initialize() {
        AppBase.initialize();
        
        // Load last sport selection from storage
        var savedSport = Storage.getValue("lastSport");
        var savedMaxScore = Storage.getValue("lastMaxScore");
        
        if (savedSport != null && savedMaxScore != null) {
            sportName = savedSport as String;
            maxScore = savedMaxScore as Number;
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new GameOnView(), new GameOnDelegate() ];
    }

    // Start a new game with the selected sport
    function startNewGame(sport as String, maxScoreValue as Number) as Void {
        sportName = sport;
        maxScore = maxScoreValue;
        playerScore = 0;
        opponentScore = 0;
        playerSets = 0;
        opponentSets = 0;
        gameActive = true;
        
        // Save sport selection to storage
        Storage.setValue("lastSport", sport);
        Storage.setValue("lastMaxScore", maxScoreValue);
        
        // Start activity recording
        startActivityRecording(sport);
    }
    // Start activity recording session
    function startActivityRecording(sport as String) as Void {
        // Use SPORT_GENERIC for both sports (Garmin doesn't have specific types for all sports)
        var sportType = Activity.SPORT_RACKET;
        if (sport.equals("Beach Volleyball")) {
            sportType = Activity.SPORT_VOLLEYBALL;
        }
        
        session = ActivityRecording.createSession({
            :name => sport,
            :sport => sportType
        });
        
        if (session != null && session.isRecording() == false) {
            session.start();
        }    
    }

    // Increment player score
    function incrementPlayerScore() as Void {
        if (gameActive) {
            // If opponent was serving and player scores, player gets serve
            if (!playerServing) {
                playerServing = true;
            } else {
                // Player was already serving, toggle side after scoring
                servingFromRight = !servingFromRight;
            }
            playerScore++;
            addToHistory(1);
            checkSetWinner();
        }
    }

    // Decrement player score (prevent negative)
    function decrementPlayerScore() as Void {
        if (gameActive && playerScore > 0) {
            playerScore--;
        }
    }

    // Increment opponent score
    function incrementOpponentScore() as Void {
        if (gameActive) {
            // If player was serving and opponent scores, opponent gets serve
            if (playerServing) {
                playerServing = false;
            } else {
                // Opponent was already serving, toggle side after scoring
                servingFromRight = !servingFromRight;
            }
            opponentScore++;
            addToHistory(2);
            checkSetWinner();
        }
    }

    // Decrement opponent score (prevent negative)
    function decrementOpponentScore() as Void {
        if (gameActive && opponentScore > 0) {
            opponentScore--;
        }
    }

    // Check if a set has been won
    function checkSetWinner() as Void {
        var winMargin = 2;
        
        // Check if either player has reached the max score with at least 2 point lead
        if (playerScore >= maxScore && (playerScore - opponentScore) >= winMargin) {
            playerSets++;
            playerScore = 0;
            opponentScore = 0;
            playerServing = true; // Winner serves first in new set
            servingFromRight = true; // Reset to right side
        } else if (opponentScore >= maxScore && (opponentScore - playerScore) >= winMargin) {
            opponentSets++;
            playerScore = 0;
            opponentScore = 0;
            playerServing = false; // Winner serves first in new set
            servingFromRight = true; // Reset to right side
        }
    }

    // Add action to history (keep max 5)
    function addToHistory(action as Number) as Void {
        actionHistory.add(action);
        if (actionHistory.size() > 5) {
            actionHistory = actionHistory.slice(1, null) as Array<Number>;
        }
    }
    
    // Undo last score change
    function undoLastScore() as Void {
        if (gameActive && actionHistory.size() > 0) {
            var lastAction = actionHistory[actionHistory.size() - 1];
            if (lastAction == 1 && playerScore > 0) {
                playerScore--;
                actionHistory = actionHistory.slice(0, actionHistory.size() - 1) as Array<Number>;
            } else if (lastAction == 2 && opponentScore > 0) {
                opponentScore--;
                actionHistory = actionHistory.slice(0, actionHistory.size() - 1) as Array<Number>;
            }
        }
    }
    
    // Stop current game but keep set scores
    function stopGame() as Void {
        playerScore = 0;
        opponentScore = 0;
        gameActive = false;
        actionHistory = [] as Array<Number>;
        
        // Stop and save activity recording
        stopActivityRecording();
    }
    
    // Stop activity recording session
    function stopActivityRecording() as Void {
        if (session != null && session.isRecording()) {
            session.stop();
            session.save();
            session = null;
        }
    }
    
    // Reset the entire game
    function resetGame() as Void {
        playerScore = 0;
        opponentScore = 0;
        playerSets = 0;
        opponentSets = 0;
        gameActive = false;
        sportName = "";
        actionHistory = [] as Array<Number>;
        
        // Discard activity recording if active
        if (session != null && session.isRecording()) {
            session.stop();
            session.discard();
            session = null;
        }
    }

}

function getApp() as GameOnApp {
    return Application.getApp() as GameOnApp;
}