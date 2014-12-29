
############################################################################
echo
echo "sorted_array_to_median"
echo "======================"
############################################################################
# Non-C versions all based on:
# https://wiki.postgresql.org/wiki/Aggregate_Median

assign sql_rows <<EOQ
  SELECT AVG(val)
  FROM (
    SELECT  val
    FROM    (SELECT value val
            FROM    sorted_samples
            WHERE   measurement_id = (SELECT MIN(id) FROM measurements)) x
    ORDER BY val
    LIMIT  2 - MOD((SELECT COUNT(value) FROM sorted_samples WHERE measurement_id = (SELECT MIN(id) FROM measurements)), 2)
    OFFSET CEIL((SELECT COUNT(value) FROM sorted_samples WHERE measurement_id = (SELECT MIN(id) FROM measurements)) / 2.0) - 1
  ) sub
  ;
EOQ

assign sql_array <<'EOQ'
  SELECT  CASE WHEN array_length(values, 1) % 2 = 0
          THEN (values[array_length(values, 1) / 2] + values[array_length(values, 1) / 2 + 1])  / 2.0
          ELSE values[array_length(values, 1) / 2]
          END
  FROM    sorted_sample_groups
  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION median_from_sorted_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
  l int;
BEGIN
  l := array_length(vals, 1);
  IF l % 2 = 0 THEN
    RETURN (vals[l / 2] + vals[l / 2 - 1]) / 2.0;
  ELSE
    RETURN vals[l / 2];
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  median_from_sorted_array(values)
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  sorted_array_to_median(values)
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

