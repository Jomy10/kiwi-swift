#!/usr/bin/env sh

# Run benchmarks
#
# `./bench [benhmark]`
# 
# benchmark: see case (e.g. uot, mutQuery)

# TODO: allow for mutliple benches?

case $1 in
  uot)
    if [ $2 == "report" ]; then
      swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O uot-bench > uot-report.txt
      sed 's/\ /,/g' uot-report.txt > uot-report.csv
    else
      swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O uot-bench
    fi
    ;;
  uot-big)
    echo "Note, this test was made for an earlier version of the libray and has NOT been optimized!"
    swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O uot-bench-big ;;
  mutQuery)
    MUTQUERY=1 swift run -c release -Xswiftc -whole-module-optimization -Xswiftc -O performance-benches ;;
  *)
    if [$1 == ""]; then
      echo "no benchmark provided"
    else
      echo "$1 is not a valid benchmark"
    fi
    ;;
esac
