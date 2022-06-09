#!/usr/bin/env sh

# Run benchmarks
#
# `./bench [benhmark]`
# 
# benchmark: see case (e.g. uot, mutQuery)

# TODO: allow for mutliple benches?

case $1 in
  uot)
    swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O uot-bench ;;
  uot-big)
    swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O uot-bench-big ;;
  mutQuery)
    MUTQUERY=1 swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O performance-benches ;;
  doubleQuery)
    DOUBLEQUERY=1 swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O performance-benches ;;
  mutClosure)
    MUTCLOSURE=1 swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O performance-benches ;;
  *)
    if [$1 == ""]; then
      echo "no benchmark provided"
    else
      echo "$1 is not a valid benchmark"
    fi
    ;;
esac
