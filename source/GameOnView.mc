import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.Sensor;

class GameOnView extends WatchUi.View {

    private var sportLabel as WatchUi.Text?;
    private var scoreLabel as WatchUi.Text?;
    private var setsLabel as WatchUi.Text?;
    private var heartRateLabel as WatchUi.Text?;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
        sportLabel = View.findDrawableById("SportLabel") as WatchUi.Text;
        scoreLabel = View.findDrawableById("ScoreLabel") as WatchUi.Text;
        setsLabel = View.findDrawableById("SetsLabel") as WatchUi.Text;
        heartRateLabel = View.findDrawableById("HeartRateLabel") as WatchUi.Text;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE] as Array<SensorType>);
        Sensor.enableSensorEvents(method(:onSensor) as Method(info as Sensor.Info) as Void);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var app = getApp();
        
        // Clear the screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Draw simple score view for all sports
        if (app.gameActive) {
            drawSimpleScoreView(dc, app);
        } else {
            drawDefaultView(dc, app);
        }
    }
    
    // Draw simple score view with serving indicators
    function drawSimpleScoreView(dc as Dc, app as GameOnApp) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Draw "Home" and "Guest" labels at top
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var leftX = centerX - 60;
        var rightX = centerX + 60;
        var labelY = 30;
        
        dc.drawText(leftX, labelY, Graphics.FONT_SMALL, "Home", 
                   Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightX, labelY, Graphics.FONT_SMALL, "Guest", 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw scores (big numbers)
        var scoreY = centerY - 20;
        dc.drawText(leftX, scoreY, Graphics.FONT_NUMBER_HOT, 
                   app.playerScore.format("%d"), 
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(rightX, scoreY, Graphics.FONT_NUMBER_HOT, 
                   app.opponentScore.format("%d"), 
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Draw serving indicator boxes below scores
        var boxY = centerY + 30;
        var boxWidth = 40;
        var boxHeight = 30;
        
        // Determine which side serves and what to display
        var servingX = app.playerServing ? leftX : rightX;
        var boxLeft = servingX - boxWidth / 2;
        var servingText = "";
        
        if (app.sportName.equals("Beach Volleyball")) {
            // Show player number (1 or 2)
            servingText = app.servingFromRight ? "2" : "1";
        } else if (app.sportName.equals("Squash")) {
            // Show L or R for left/right
            servingText = app.servingFromRight ? "R" : "L";
        }
        
        // Draw box
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(boxLeft, boxY, boxWidth, boxHeight);
        
        // Draw text in box
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(servingX, boxY + boxHeight / 2, Graphics.FONT_MEDIUM, 
                   servingText, 
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Draw sets at bottom
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 25, Graphics.FONT_SMALL, 
                   "Sets: " + app.playerSets.format("%d") + " - " + app.opponentSets.format("%d"), 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw heart rate in top left corner
        var heartRate = getHeartRate();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (heartRate != null) {
            dc.drawText(5, 5, Graphics.FONT_XTINY, heartRate.format("%d") + " bpm", 
                       Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(5, 5, Graphics.FONT_XTINY, "-- bpm", 
                       Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    
    // Draw volleyball court with serving indicator
    function drawVolleyballCourt(dc as Dc, app as GameOnApp) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Draw court rectangle (smaller, centered)
        var courtWidth = width * 0.4;
        var courtHeight = height * 0.6;
        var courtLeft = (width - courtWidth) / 2;
        var courtTop = (height - courtHeight) / 2;
        
        // Fill serving side with light green
        if (app.playerServing) {
            // Player serves - bottom half green
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
            dc.fillRectangle(courtLeft, centerY, courtWidth, courtHeight / 2);
        } else {
            // Opponent serves - top half green
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
            dc.fillRectangle(courtLeft, courtTop, courtWidth, courtHeight / 2);
        }
        
        // Draw court outline
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawRectangle(courtLeft, courtTop, courtWidth, courtHeight);
        
        // Draw center line (net)
        dc.drawLine(courtLeft, centerY, courtLeft + courtWidth, centerY);
        
        // Draw scores - opponent on top, player on bottom
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Opponent score (top)
        dc.drawText(centerX, courtTop + courtHeight * 0.25, Graphics.FONT_NUMBER_HOT, 
                   app.opponentScore.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Player score (bottom)
        dc.drawText(centerX, courtTop + courtHeight * 0.75, Graphics.FONT_NUMBER_HOT, 
                   app.playerScore.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Draw sets at bottom
        dc.drawText(centerX, height - 20, Graphics.FONT_SMALL, 
                   "Sets: " + app.playerSets.format("%d") + " - " + app.opponentSets.format("%d"), 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw heart rate in top left
        var heartRate = getHeartRate();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (heartRate != null) {
            dc.drawText(5, 5, Graphics.FONT_XTINY, heartRate.format("%d") + " bpm", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(5, 5, Graphics.FONT_XTINY, "-- bpm", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    
    // Draw squash court with serving side indicator
    function drawSquashCourt(dc as Dc, app as GameOnApp) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Draw court rectangle (smaller, centered)
        var courtWidth = width * 0.7;
        var courtHeight = height * 0.6;
        var courtLeft = (width - courtWidth) / 2;
        var courtTop = (height - courtHeight) / 2;
        
        // Fill serving side with light green (left = player, right = opponent)
        if (app.playerServing) {
            // Player serves - left half green
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
            dc.fillRectangle(courtLeft, courtTop, courtWidth / 2, courtHeight);
        } else {
            // Opponent serves - right half green
            dc.setColor(Graphics.COLOR_DK_GREEN, Graphics.COLOR_DK_GREEN);
            dc.fillRectangle(centerX, courtTop, courtWidth / 2, courtHeight);
        }
        
        // Draw court outline
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawRectangle(courtLeft, courtTop, courtWidth, courtHeight);
        
        // Draw center line (T-line)
        dc.drawLine(centerX, courtTop, centerX, courtTop + courtHeight);
        
        // Draw scores - player on left, opponent on right
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Player score (left)
        var playerScoreX = courtLeft + courtWidth * 0.25;
        dc.drawText(playerScoreX, centerY, Graphics.FONT_NUMBER_HOT, 
                   app.playerScore.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Opponent score (right)
        var opponentScoreX = courtLeft + courtWidth * 0.75;
        dc.drawText(opponentScoreX, centerY, Graphics.FONT_NUMBER_HOT, 
                   app.opponentScore.format("%d"), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        
        // Draw small green square below serving player's score
        var squareSize = 12;
        var squareY = centerY + 35;
        var squareX = 0;
        
        if (app.playerServing) {
            // Below player's score (left side)
            if (app.servingFromRight) {
                squareX = playerScoreX + 15; // Right aligned
            } else {
                squareX = playerScoreX - 15 - squareSize; // Left aligned
            }
        } else {
            // Below opponent's score (right side)
            if (app.servingFromRight) {
                squareX = opponentScoreX + 15; // Right aligned
            } else {
                squareX = opponentScoreX - 15 - squareSize; // Left aligned
            }
        }
        
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(squareX, squareY, squareSize, squareSize);
        
        // Draw sets at bottom
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 20, Graphics.FONT_SMALL, 
                   "Sets: " + app.playerSets.format("%d") + " - " + app.opponentSets.format("%d"), 
                   Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw heart rate in top left
        var heartRate = getHeartRate();
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        if (heartRate != null) {
            dc.drawText(5, 5, Graphics.FONT_XTINY, heartRate.format("%d") + " bpm", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(5, 5, Graphics.FONT_XTINY, "-- bpm", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
    
    // Draw default view for non-volleyball or inactive games
    function drawDefaultView(dc as Dc, app as GameOnApp) as Void {      
        // Update sport label
        if (sportLabel != null) {
            if (app.gameActive) {
                sportLabel.setText(app.sportName);
            } else {
                sportLabel.setText(WatchUi.loadResource(Rez.Strings.prompt) as String);
            }
        }
        
        // Update score label
        if (scoreLabel != null) {
            scoreLabel.setText(app.playerScore.format("%d") + " - " + app.opponentScore.format("%d"));
        }
        
        // Update sets label
        if (setsLabel != null) {
            setsLabel.setText("Sets: " + app.playerSets.format("%d") + " - " + app.opponentSets.format("%d"));
        }
        
        // Update heart rate label
        if (heartRateLabel != null) {
            var heartRate = getHeartRate();
            if (heartRate != null) {
                heartRateLabel.setText(heartRate.format("%d") + " bpm");
            } else {
                heartRateLabel.setText("-- bpm");
            }
        }
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }
    
    // Get current heart rate
    function getHeartRate() as Number? {
        var info = ActivityMonitor.getInfo();
        if (info has :currentHeartRate && info.currentHeartRate != null) {
            return info.currentHeartRate;
        }
        
        var sensorInfo = Sensor.getInfo();
        if (sensorInfo has :heartRate && sensorInfo.heartRate != null) {
            return sensorInfo.heartRate;
        }
        
        return null;
    }
    
    // Handle sensor events
    function onSensor(sensorInfo as Sensor.Info) as Void {
        WatchUi.requestUpdate();
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
        Sensor.enableSensorEvents(null);
    }

}
