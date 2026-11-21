import Toybox.Lang;

module Sports {

    const BEACH_VOLLEYBALL = 0;
    const VOLLEYBALL = 1;
    const SQUASH = 2;
    const FAUSTBALL = 3;

    const ALL = [BEACH_VOLLEYBALL, VOLLEYBALL, SQUASH, FAUSTBALL] as Array<Number>;
    const END_SCORES = [11, 15, 21, 25] as Array<Number>;

    function name(sport as Number) as String {
        if (sport == BEACH_VOLLEYBALL) {
            return "Beach Volleyball";
        } else if (sport == VOLLEYBALL) {
            return "Volleyball";
        } else if (sport == SQUASH) {
            return "Squash";
        }
        return "Faustball";
    }

    function defaultEndScore(sport as Number) as Number {
        if (sport == BEACH_VOLLEYBALL) {
            return 21;
        } else if (sport == VOLLEYBALL) {
            return 25;
        }
        return 11;
    }

    function icon(sport as Number) as ResourceId {
        if (sport == BEACH_VOLLEYBALL) {
            return Rez.Drawables.IconBeachVolleyball;
        } else if (sport == VOLLEYBALL) {
            return Rez.Drawables.IconVolleyball;
        } else if (sport == SQUASH) {
            return Rez.Drawables.IconSquash;
        }
        return Rez.Drawables.IconFaustball;
    }

    function isValid(sport as Number) as Boolean {
        return ALL.indexOf(sport) >= 0;
    }
}
