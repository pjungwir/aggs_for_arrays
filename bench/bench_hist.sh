#!/bin/bash

############################################################################
echo
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

query >/dev/null <<'EOQ'
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
  SELECT  hist_from_array(values, ${bin_start}, ${bin_width}, ${bin_count})
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_hist(values, ${bin_start}::float, ${bin_width}::float, ${bin_count})
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

