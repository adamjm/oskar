#!/bin/sh

# if command starts with an option, prepend arangod
case "$1" in
  -*) set -- collect "$@" ;;
  *) ;;
esac

if [ "$1" = 'collect' ]; then
  cd /tools
  go build validateValues.go
  go build validateSingleValues.go
  set -- /tools/collectPerftestOutput.fish "$@"
fi

exec "$@"
