MIN = 60
HOUR = 60 * MIN
DAY = 24 * HOUR
MONTH = 30 * DAY
YEAR = 365 * DAY
set ytics ( \
    "10 sec" 10, "30 sec" 30, \
    "1 min" MIN, "5 min" 5 * MIN, "15 min" 15 * MIN, "30 min" 30 * MIN, \
    "1 hr" HOUR, "2 hr" 2 * HOUR, "6 hr" 6 * HOUR, "12 hr" 12 * HOUR, \
    "1 day" DAY, "2 days" 2 * DAY, "4 days" 4 * DAY, "7 days" 7 * DAY, "14 days" 14 * DAY, \
    "1 month" MONTH, "2 months" 2 * MONTH, "6 months" 0.5 * YEAR, \
    "1 year" YEAR, "2 years" 2 * YEAR, "10 years" 10 * YEAR \
)
unset key

# Mark long-lived stuff.
set object 1 rect from graph 0, first 2 * 86400 to graph 1,1 behind fc rgb "gray70"
set label 1 "long-lived" at graph 0,1 offset character 2,-1
# Mark short-lived stuff.
set object 2 rect from graph 0,0 to graph 1, first 2 * 3600 behind fc rgb "gray90"
set label 2 "short-lived" at graph 0,0 offset character 2,1

set ylabel durationLabel
set logscale y

logfloor(x) = (x == 0 ? 10 : x)
