#!/usr/bin/env fish
source jenkins/helper/jenkins.fish

cleanPrepareLockUpdateClear
and community
and switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and buildDockerImage arangodb/arangodb-preview:3.3
and docker push arangodb/arangodb-preview:3.3
and docker tag arangodb/arangodb-preview:3.3 registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3
and docker push registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3

if test $status -ne 0
  echo Production of community image failed, giving up...
  cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
  exit 1
end

enterprise
and switchBranches $ARANGODB_BRANCH $ENTERPRISE_BRANCH true
and findArangoDBVersion
and buildStaticArangoDB -DTARGET_ARCHITECTURE=nehalem
and downloadStarter
and downloadSyncer
and buildDockerImage registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY
and docker push registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY
and docker tag registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3
and docker push registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3

and begin
  rm -rf $WORKSPACE/imagenames.log
  echo arangodb/arangodb-preview:3.3 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-community-maintainer:3.3 >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/arangodb-preview:3.3-$KEY >> $WORKSPACE/imagenames.log
  echo registry.arangodb.biz:5000/arangodb/linux-enterprise-maintainer:3.3 >> $WORKSPACE/imagenames.log
end

set -l s $status
cd "$HOME/$NODE_NAME/$OSKAR" ; moveResultsToWorkspace ; unlockDirectory
exit $s