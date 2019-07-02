#!/usr/bin/env fish

source jenkins/helper.jenkins.fish ; prepareOskar
lockDirectory ; updateOskar ; clearResults

set -xl dataBaseDir /mnt/buildfiles/performance/hackstone
set -xl RUN_DATE (date "+%y%m%d")
set -xl plotImage pavlov99/gnuplot
set -xl desc work/description.html
set -xl rawDir $dataBaseDir/$ARANGODB_BRANCH/$RUN_DATE/RAW


function createSingleRunDetailGraphs
  set -l plotSingle work/hackstoneOneRun.gnuplot
  echo "Rendering single run graphs ..."
  for type in insert get replace
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
      echo "set title $type"
      echo 'set xlabel "seconds"'
      echo 'set ylabel "requests"'
      echo 'set xtics rotate by 90 right'
      echo 'set key autotitle columnhead'
      echo 'set terminal png size 4096,480'
      echo "set output \"work/images/$type.png\""
      echo "plot for [n=6:8] \"/source/c\".n.\"_$type.csv\" using 4:xticlabels((int($0) % 20)==0?stringcolumn(1):\"\") title \"c\".n with lines"
    end >> $plotSingle
    and cat $plotSingle
    and docker run -v (pwd)/work:/work -v $rawDir:/source pavlov99/gnuplot gnuplot $plotSingle
  end
end

function createAccumulatedGraphs
  set -l GET_THROUGH 0
  set -l INSERT_THROUGH 0
  set -l REPLACE_THROUGH 0
  for machine in c6 c7 c8
    set GET_THROUGH = $GET_THROUGH + (tail -1 $rawDir/$machine\_get.csv | cut -d "," -f 5)
    set INSERT_THROUGH = $INSERT_THROUGH + (tail -1 $rawDir/$machine\_insert.csv | cut -d "," -f 5)
    set REPLACE_THROUGH = $REPLACE_THROUGH + (tail -1 $rawDir/$machine\_replace.csv | cut -d "," -f 5)
  end
  echo "$ARANGODB_BRANCH;$RUN_DATE;$GET_THROUGH" >> $dataBaseDir/get_accumulated.csv
  echo "$ARANGODB_BRANCH;$RUN_DATE;$INSERT_THROUGH" >> $dataBaseDir/insert_accumulated.csv
  echo "$ARANGODB_BRANCH;$RUN_DATE;$REPLACE_THROUGH" >> $dataBaseDir/replace_accumulated.csv

#  set -l plotAccum work/hackstoneAccumulated.gnuplot
#  set -l dates (cat $results | awk -F, '{print $2}' | sort | uniq)

#  echo > $plotAccum
#  begin
#    echo 'set yrange [0:]'
#    echo 'set term png size 2048,800'
#    echo 'set key left bottom'
#    echo 'set xtics nomirror rotate by 90 right font ",8"'
#    echo -n 'set xtics ('
#    set -l sep ""
#    for i in $dates
#      set -l secs (date -d $i +%s)
#      set -l iso (date -I -d $i)
#  
#      echo -n $sep\"$iso\" $secs
#      set sep ", "
#    end
#    echo ')'
#  end >> $plotAccum
#  and cat $plotAccum
#  and docker run -v (pwd)/work:/work -v $rawDir:/source pavlov99/gnuplot gnuplot $plotAccum
end

function createGraphs
  createSingleRunDetailGraphs
  createAccumulatedGraphs
end

createGraphs
