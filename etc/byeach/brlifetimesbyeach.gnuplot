set multiplot title graphTitle layout 2,1

set bmargin 0
set format x ""

plot data using 0:(logfloor($3)):(logfloor($2)):7:6 with candlesticks linestyle 1, \
    '' using 0:(logfloor($4)) with points lc "black" pt 7 pointsize 1, \
    '' using 0:(logfloor($4)):(sqrt($20)) with points lc "black" pt 6 pointsize variable linewidth 2


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
