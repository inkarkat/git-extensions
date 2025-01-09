set multiplot title graphTitle layout 2,1

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

# Mark long-lived branches.
set object 1 rect from graph 0, first 2 * 86400 to graph 1,1 behind fc rgb "gray70"
set label 1 "long-lived" at graph 0,1 offset character 2,-1
# Mark short-lived branches.
set object 2 rect from graph 0,0 to graph 1, first 2 * 3600 behind fc rgb "gray90"
set label 2 "short-lived" at graph 0,0 offset character 2,1

set bmargin 0
set format x ""
set ylabel durationLabel
set logscale y
plot data using 0:3:2:7:6 with candlesticks linestyle 1, \
    '' using 0:4 with points lc "black" pt 7 pointsize 1, \
    '' using 0:4:(sqrt($20)) with points lc "black" pt 6 pointsize variable linewidth 2


stats '' using 16:17 nooutput
min(a, b) = (a < b) ? a : b # Compatibility: Built-in min() is a Gnuplot 5.4 feature.
set yrange [0:min(STATS_max_x * 1.5, STATS_max_y + 1)]

unset object 1
unset label 1
unset object 2
unset label 2

# Mark large branches.
set object 3 rect from graph 0, first 7 to graph 1,1 behind fc rgb "gray80"
set label 3 "large" at graph 0,1 offset character 2,-1

set key
set bmargin
set format x "%g"
set xlabel "Authors"
unset ytics; set ytics
set ylabel "number of commits"
unset logscale y
plot '' using 0:13:12:17:16:xtic(1) title "1st .. 3rd quartile" with candlesticks linestyle 1, \
    '' using 0:14 title "median" with points lc "black" pt 7 pointsize 1, \
    '' using 0:14:(sqrt($20)) title 'area \~ # of branches' with points lc "black" pt 6 pointsize variable linewidth 2


unset multiplot
