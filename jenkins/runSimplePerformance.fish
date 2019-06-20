#!/usr/bin/env fish
set -xg simple (pwd)/performance
set -xg date (date +%Y%m%d)
set -xg datetime (date +%Y%m%d%H%M)

if test -z "$ARANGODB_TEST_CONFIG"
  set -xg ARANGODB_TEST_CONFIG run-small-edges.js
end

source jenkins/helper.jenkins.fish ; prepareOskar

lockDirectory ; updateOskar ; clearResults

echo Working on branch $ARANGODB_BRANCH of main repository and
echo on branch $ENTERPRISE_BRANCH of enterprise repository.

switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH true
and enterprise
and maintainerOff
and releaseMode
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem

and rm -rf work/database $simple/results.csv
and echo "==== starting performance run ===="
and docker run \
  -e ARANGO_LICENSE_KEY=$ARANGODB_LICENSE_KEY \
  -v (pwd)/work/ArangoDB:/ArangoDB \
  -v (pwd)/work:/data \
  -v $simple:/performance \
  arangodb/arangodb \
  sh -c "cd /performance && \
    /ArangoDB/build/bin/arangod \
      -c none \
      --javascript.app-path /tmp/app \
      --javascript.startup-directory /ArangoDB/js \
      --server.rest-server false \
      --javascript.module-directory `pwd` \
      --log.foreground-tty \
      /data/database \
      --javascript.script $ARANGODB_TEST_CONFIG"

set -l s $status
echo "storing results in /mnt/buildfiles/performance/results-$ARANGODB_BRANCH-$datetime.csv"
awk "{print \"$ARANGODB_BRANCH,$date,\" \$0}" \
  < $simple/results.csv \
  > "/mnt/buildfiles/performance/results-$ARANGODB_BRANCH-$datetime.csv"
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory 
exit $s
