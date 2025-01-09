# Set up histograms with candlesticks.
set datafile separator '\t'
set style data histogram
set style histogram clustered gap 1
set style fill solid border -1
set style line 1 linecolor "black"
set style fill pattern 2
set boxwidth 0.2

set xtics rotate by -25
set grid ytics
set auto fix
set xrange [-0.5:*] # Add a margin to the left
set offset graph 0,0.5  # Add a margin to the right
# Size margins equally for all plots.
set lmargin at screen 0.1  # Adjust left margin to fit the widest y-label.
set rmargin at screen 0.9  # Larger right margin to account for overhanging long author names.
