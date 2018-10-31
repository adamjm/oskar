#!/usr/bin/env fish

function download
  set -l user "mchacki"
  set -l server "c$argv[1]"
  set -l login "$user@$server"
  set -l folder "c0$argv[1]-linux.performance"
  set -l csvFold "$login:/home/jenkins/performance/workspace/nightly-performance-javabench-matrix/machine/$folder/outputFiles"
  mkdir "$server"_logs_db
  mkdir "$server"_logs_coor
  echo "Downloading from $server..."
  and scp -o StrictHostKeyChecking=no "$login:/home/jenkins/$folder/oskar/work/perfCluster/dbserver8530/arangod.log*" "$server"_logs_db/
  and scp -o StrictHostKeyChecking=no "$login:/home/jenkins/$folder/oskar/work/perfCluster/coordinator8529/arangod.log*" "$server"_logs_coor/
  and scp -o StrictHostKeyChecking=no "$csvFold/insert.csv" "$server"_insert.csv
  and scp -o StrictHostKeyChecking=no "$csvFold/replace.csv" "$server"_replace.csv
  and scp -o StrictHostKeyChecking=no "$csvFold/get.csv" "$server"_get.csv
  and scp -o StrictHostKeyChecking=no "$csvFold/errors.csv" "$server"_errors.csv
  and echo "Download from $server done"
end

function collectRemoteOutput
  set -l OUTDIR "/graphs"
  set -l TOOLS "/tools"
  if test (count $argv) -gt 1
    set TOOLS "$argv[2]"
  end
  mkdir -p $OUTDIR
  and cd $OUTDIR
  and download 6
  and download 7
  and download 8
  and eval gnuplot -c $TOOLS/combined.gnu insert
  and eval gnuplot -c $TOOLS/combined.gnu replace
  and eval gnuplot -c $TOOLS/combined.gnu get
  and eval $TOOLS/validateValues
  set -l s $status
  cd ..
  return $s
end

function collectLocalOutput
  set -l csvFold "/work/outputFiles"
  set -l graphsFold "/work/graphs"
  set -l TOOLS "/tools"
  mkdir -p $graphsFold
  and cd $graphsFold
  and eval gnuplot -c $TOOLS/single.gnu insert
  and eval gnuplot -c $TOOLS/single.gnu replace
  and eval gnuplot -c $TOOLS/single.gnu get
  and tar czf raw_data.tar.gz "$csvFold/"
  and eval $TOOLS/validateSingleValues
  set -l s $status
  cd ..
  return $s
end

echo "Downloading data"
and collectLocalOutput
