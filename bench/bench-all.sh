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
  (echo '\timing'; echo $1) | query
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
  read -r -d '' $1 || true
}

############################################################################
# echo "Noop just to see variance"
# echo "========================="
############################################################################

# compare "SELECT NOW()" "SELECT NOW()" "SELECT NOW()" "SELECT NOW()"
# echo


############################################################################
echo "array_to_hist"
echo "============="
############################################################################

bin_start=-1000000000
bin_width=5000000
bin_count=1000

assign sql_rows <<EOQ
  SELECT  b.a,
          COALESCE(c, 0)
  FROM    generate_series(0, ${bin_count}) AS b(a)
  LEFT OUTER JOIN (
          SELECT  ((s.value - ${bin_start}) / ${bin_width})::bigint AS bin,
                  COUNT(*) c
          FROM    samples s
          WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
          GROUP BY bin
          ) x
  ON      b.a = x.bin
  ORDER BY b.a
  ;
EOQ

assign sql_array <<EOQ
  SELECT  b.a,
          COALESCE(c, 0)
  FROM    generate_series(0, ${bin_count}) AS b(a)
  LEFT OUTER JOIN (
          SELECT  ((value - ${bin_start}) / ${bin_width})::bigint AS bin,
                  COUNT(*) c
          FROM    (SELECT UNNEST(s.values) AS value
                  FROM    sample_groups s
                  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)) x
          GROUP BY bin
          ) y
  ON      b.a = y.bin
  ORDER BY b.a
  ;
EOQ

query <<'EOQ'
CREATE OR REPLACE FUNCTION hist_from_array (vals FLOAT[], bin_start REAL, bin_size REAL, bin_count INTEGER) RETURNS INTEGER[] AS $$
DECLARE
  result INTEGER[];
  i INTEGER;
  b INTEGER;
  v FLOAT;
BEGIN
  -- Init the array with the correct number of 0's so the caller doesn't see NULLs
  FOR i IN 1 .. bin_count LOOP
    result[i] := 0;
  END LOOP;
 
  FOREACH v IN ARRAY vals LOOP
    b := ((v - bin_start) / bin_size)::int;
    result[b] := result[b] + 1;
  END LOOP;
 
  RETURN result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  array_to_string(hist_from_array(values, ${bin_start}, ${bin_width}, ${bin_count}), ',')
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_hist(values, ${bin_start}::float, ${bin_width}::float, ${bin_count})
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

