#!/bin/zsh

if (( # == 0 )); then
   print >&2 "Usage: $0 TestSuiteName"
   exit 1
fi

suiteName=${1};

mkdir -p csv;
mkdir -p graphs;
mkdir -p gnuplot;

# Get the experiment names
experiments=()
while IFS='' read -r line; do experiments+=("$line"); done < <(sf data query --query "SELECT ExperimentName__c FROM PerformanceMeasureResult__c WHERE SuiteName__c = '$suiteName' GROUP BY ExperimentName__c" --json | jq -r '.result.records[].ExperimentName__c')

# Extract each experiment as a CSV file
for ((i = 1; i <= $#experiments; i++)); do
  thisExperiment=${experiments[i]};
  experiments[i]=${experiments[i]:gs/\./_/};
  echo "Fetching $thisExperiment"
  sf data query -q "SELECT Size__c, CpuTimeInMs__c FROM PerformanceMeasureResult__c WHERE ExperimentName__c = '$thisExperiment' AND Result__c = 'SUCCESS' ORDER BY Size__c" -r csv > "csv/${experiments[i]}.csv"
  echo "Wrote to csv/${experiments[i]}.csv"
done

gnuplot_commands="gnuplot/$suiteName.gnuplot"

# General gnuplot config

cat <<-EOF > "$gnuplot_commands"
set datafile separator ','
set xtics nomirror
set ytics nomirror
set fit quiet nolog
set key autotitle columnhead

set border 3 # Just bottom and left
set size ratio 0.5
set terminal png size 1200,600
set style fill solid
set style circle radius 2

set ylabel "CPU Time (ms)"
set xlabel "Size"

set output 'graphs/$suiteName.png'
EOF

# Fit a line to each experiment

for ((i = 1; i <= $#experiments; i++)); do
  thisExperiment=${experiments[i]};
  echo "$thisExperiment(x) = a$i*x + b$i" >> "$gnuplot_commands"
  echo "fit $thisExperiment(x) 'csv/$thisExperiment.csv' via a$i,b$i" >> "$gnuplot_commands"
done

# Plot all the experiments and lines
echo "" >> "$gnuplot_commands"
echo "plot \\" >> "$gnuplot_commands"

for ((i = 1; i <= $#experiments; i++)); do
  thisExperiment=${experiments[i]};
  if [[ "$thisExperiment" != "${experiments[-1]}" ]]; then
    echo "    $thisExperiment(x) linecolor $i notitle, \"csv/$thisExperiment.csv\" using 1:2 with circle linecolor $i title '${thisExperiment:gs/_/./}', \\" >> "$gnuplot_commands"
  else
    echo "    $thisExperiment(x) linecolor $i notitle, \"csv/$thisExperiment.csv\" using 1:2 with circle linecolor $i title '${thisExperiment:gs/_/./}'" >> "$gnuplot_commands"
  fi
done

echo "Plotting with gnuplot to graphs/$suiteName.png"
gnuplot "$gnuplot_commands"