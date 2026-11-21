# game-on
Garmin Connect IQ watch app to keep score during a game of Beach Volleyball, Volleyball, Squash or Faustball.

## Features
- Start menu: start with the last sport and end score, change sport (starts right away), choose end score (11, 15, 21, 25), history of the last game
- Records the match as a Garmin activity, one lap per set
- Serve indicator; in beach volleyball it shows which player (1 or 2) serves
- Vibration when sides have to be switched in beach volleyball (every 7 points, every 5 when playing to 15)
- Winner screen after each set; undo still works until the next set starts
- Touchscreen is disabled while the score screen is shown

## Recorded activity
Garmin has no activity type for every sport, so the closest one is used. The activity name in Garmin Connect is always the selected sport.

| Selected sport | Garmin sport | Garmin sub-sport | Default end score |
|---|---|---|---|
| Beach Volleyball | Volleyball | Generic | 21 |
| Volleyball | Volleyball | Generic | 25 |
| Squash | Racket | Squash | 11 |
| Faustball | Team Sport | Generic | 11 |

## Buttons during a game
| Button | Action |
|---|---|
| Middle left | Guest +1 |
| Middle left (hold) | Menu: undo, set score, end score, end game, exit app |
| Bottom left | Home +1 |
| Bottom right | Guest +1 |
| Top right | End game (with confirmation) |
