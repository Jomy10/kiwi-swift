#!/usr/bin/env sh

# Run demos
#
# `./demo.sh [demo]`
#
# demo's:
# - pong

case $1 in
  pong)
    swift run pong-demo ;;
esac
