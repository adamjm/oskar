set lmargin at screen 0.02
set rmargin at screen 0.95
set bmargin at screen 0.10
set tmargin at screen 0.95
set datafile separator ","
set autoscale fix
set key outside right center
set title ARG1
set xlabel "seconds"
set ylabel "requests"
set xtics rotate by 90 right
set key autotitle columnhead
set terminal png size 4096,480
set output ARG1.".png"
plot "/work/outputFiles/".ARG1.".csv" using 4:xticlabels((int($0) % 20)==0?stringcolumn(1):"") with lines
