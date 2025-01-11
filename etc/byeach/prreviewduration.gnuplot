set xlabel xLabel
plot data using 0:(logfloor($3)):(logfloor($2)):7:6:xtic(1) with candlesticks linestyle 1, \
    '' using 0:(logfloor($4)) with points lc "black" pt 7 pointsize 1, \
    '' using 0:(logfloor($4)):(sqrt($10)) with points lc "black" pt 6 pointsize variable linewidth 2
