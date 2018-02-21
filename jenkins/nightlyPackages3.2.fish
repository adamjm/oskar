#!/usr/bin/fish
mkdir -p "$HOME/$NODE_NAME" ; cd "$HOME/$NODE_NAME"
if not cd oskar ^ /dev/null 
  git clone https://github.com/neunhoef/oskar ; and cd oskar
end
and source helper.fish
if test $status != 0 ; echo Did not find oskar and helpers ; exit 1 ; end

updateOskar ; lockDirectory ; clearResults

switchBranches 3.2 3.2
and makeRelease

set -l s $status ; moveResultsToWorkspace ; unlockDirectory ; exit $s

