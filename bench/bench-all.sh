#!/bin/bash

set -eu

REPEATS=${REPEATS:-100}

source bench/defaults.sh
export PGPASSWORD="$BENCH_PASSWORD"

function average() {
  awk '{ total += $1; count++ } END { print total/count }'
}

function query() {
  psql --no-psqlrc -U "$BENCH_USER" -h "$BENCH_HOST" -p "$BENCH_PORT" "$BENCH_DATABASE"
}

function query_with_timing() {
  (echo '\timing'; echo "$1") | query
}

function bench() {
  for i in {1..$REPEATS}; do
    query_with_timing "$1" | tail -1
  done | awk '{ print $2 }' | average;
}

function compare() {
  echo SQL rows $(bench "$1") ms
  echo SQL array $(bench "$2") ms
  echo PLPGSQL array $(bench "$3") ms
  echo C array $(bench "$4") ms
}

function assign() {
  read -r -d '' "$1" || true
}

############################################################################
# echo "Noop just to see variance"
# echo "========================="
############################################################################

# compare "SELECT NOW()" "SELECT NOW()" "SELECT NOW()" "SELECT NOW()"
# echo

source bench/bench_hist.sh
source bench/bench_mean.sh
source bench/bench_median.sh
source bench/bench_sorted_median.sh
source bench/bench_mode.sh
source bench/bench_sorted_mode.sh
source bench/bench_percentile.sh
source bench/bench_sorted_percentile.sh
source bench/bench_percentiles.sh
source bench/bench_sorted_percentiles.sh
source bench/bench_max.sh
source bench/bench_min.sh
source bench/bench_min_max.sh
source bench/bench_skewness.sh
source bench/bench_kurtosis.sh

