set key
set bmargin
set format x "%g"
set xlabel "Authors"
unset ytics; set ytics
set ylabel "number of words in commit message"
set logscale y
stats data using 10 nooutput
plot '' using 0:3:2:7:6:xtic(1) title "1st .. 3rd quartile" with candlesticks linestyle 1, \
    '' using 0:4 title "median" with points lc "black" pt 7 pointsize 1, \
    '' using 0:4:(15 * sqrt($10/STATS_max)) title 'area \~ # of commits' with points lc "black" pt 6 pointsize variable linewidth 2
