set datafile separator ','
set xtics nomirror
set ytics nomirror
set fit quiet nolog
set key autotitle columnhead

set border 3 # Just bottom and left
set size ratio 0.5
set terminal png size 1200,600

iteratorLoop(x) = a*x + b
fit iteratorLoop(x) 'csv/IteratorLoopPerformanceScenario.csv' via a,b 

integerLoop(x) = c*x + d
fit integerLoop(x) 'csv/IntegerLoopPerformanceScenario.csv' via c,d 

integerLoopStoredSize(x) = e*x + g
fit integerLoopStoredSize(x) 'csv/IntegerStoredSizeLoopPerformanceScenario.csv' via e,g 

set style fill solid
set style circle radius 5

set ylabel "CPU Time (ms)"
set xlabel "# records"

set output 'graphs/loops.png'
plot iteratorLoop(x) linecolor 1 notitle, "csv/IteratorLoopPerformanceScenario.csv" with circle linecolor 1 title "Iterator", \
 integerLoop(x) linecolor 2 notitle, "csv/IntegerLoopPerformanceScenario.csv" linecolor 2 with circle title "Integer", \
  integerLoopStoredSize(x) linecolor 3 notitle, "csv/IntegerStoredSizeLoopPerformanceScenario.csv" linecolor 3 with circle title "Integer with stored size"
