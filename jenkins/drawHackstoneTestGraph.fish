#!/usr/bin/env fish


set -g dataBaseDir /mnt/buildfiles/performance/Linux/Hackstone
set -g RUN_DATE (date "+%y%m%d")
set -g rawDir $dataBaseDir/$ARANGODB_BRANCH/$RUN_DATE/RAW
set -g accumDir $dataBaseDir/accumulated

mkdir -p work/images
mkdir -p $accumDir/$ARANGODB_BRANCH/

function createSingleRunDetailGraphs
  set -l plotSingle work/hackstoneOneRun.gnuplot
  echo "Rendering single run graphs ..."
  for type in insert get replace
    set -l outfile work/images/$type.png
    echo "  Now render $type"
    echo > $plotSingle
    begin
      echo 'set lmargin at screen 0.02'
      echo 'set rmargin at screen 0.95'
      echo 'set bmargin at screen 0.10'
      echo 'set tmargin at screen 0.95'
      echo 'set datafile separator ","'
      echo 'set autoscale fix'
      echo 'set key outside right center'
      echo "set title \"$type\""
      echo 'set xlabel "seconds"'
      echo 'set ylabel "requests"'
      echo 'set xtics rotate by 90 right'
      echo 'set key autotitle columnhead'
      echo 'set terminal png size 2048,800'
      echo "set output \"$outfile\""
      echo "plot for [n=6:8] \"source/c\".n.\"_$type.csv\" using 4:xticlabels((int(\$0) % 20)==0?stringcolumn(1):\"\") title \"c\".n with lines"
    end >> $plotSingle
    and docker run -v (pwd)/work:/work -v $rawDir:/source pavlov99/gnuplot gnuplot $plotSingle
  end
end

function createAccumulatedGraphs
  set -l GET_THROUGH 0
  set -l INSERT_THROUGH 0
  set -l REPLACE_THROUGH 0
  for machine in c6 c7 c8
    set GET_THROUGH (math $GET_THROUGH + (tail -1 $rawDir/$machine\_get.csv | cut -d "," -f 5))
    set INSERT_THROUGH (math $INSERT_THROUGH + (tail -1 $rawDir/$machine\_insert.csv | cut -d "," -f 5))
    set REPLACE_THROUGH (math $REPLACE_THROUGH + (tail -1 $rawDir/$machine\_replace.csv | cut -d "," -f 5))
  end
  echo "$RUN_DATE;$GET_THROUGH" >> $accumDir/$ARANGODB_BRANCH/get.csv
  echo "$RUN_DATE;$INSERT_THROUGH" >> $accumDir/$ARANGODB_BRANCH/insert.csv
  echo "$RUN_DATE;$REPLACE_THROUGH" >> $accumDir/$ARANGODB_BRANCH/replace.csv

  set -l plotAccum work/hackstoneAccumulated.gnuplot

  for type in insert get replace
    echo > $plotAccum
    set -l outfile work/images/accumulated_$type.png
    echo "  Now render accumulated $type"
    begin
      echo 'set yrange [0:]'
      echo 'set term png size 2048,800'
      echo 'set key left bottom'
      echo 'set xtics nomirror rotate by 90 right font ",8"'
      echo 'set xlabel "seconds"'
      echo 'set ylabel "throughput"'
      echo "set title \"$type\""
      echo "set output \"$outfile\""
    end >> $plotAccum
    for branchDir in $accumDir/*/
      set branch (string split -- / $branchDir)[-2]
      set -l infile "source/$branch/$type.csv"
      echo "plot \"$infile\" using 2:xticlabels(stringcolumn(1)) title \"$branch\" with lines" >> $plotAccum
    end
    cat $plotAccum
    and echo "docker run -v (pwd)/work:/work -v $accumDir:/source pavlov99/gnuplot gnuplot $plotAccum"
    and docker run -v (pwd)/work:/work -v $accumDir:/source pavlov99/gnuplot gnuplot $plotAccum
  end
end

function createGraphs
  createSingleRunDetailGraphs
  createAccumulatedGraphs
end

createGraphs
