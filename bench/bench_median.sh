
############################################################################
echo
echo "array_to_median"
echo "==============="
############################################################################
# Non-C versions all based on:
# https://wiki.postgresql.org/wiki/Aggregate_Median

assign sql_rows <<EOQ
  SELECT AVG(val)
  FROM (
    SELECT  val
    FROM    (SELECT value val
            FROM    samples
            WHERE   measurement_id = (SELECT MIN(id) FROM measurements)) x
    ORDER BY val
    LIMIT  2 - MOD((SELECT COUNT(value) FROM samples WHERE measurement_id = (SELECT MIN(id) FROM measurements)), 2)
    OFFSET CEIL((SELECT COUNT(value) FROM samples WHERE measurement_id = (SELECT MIN(id) FROM measurements)) / 2.0) - 1
  ) sub
  ;
EOQ

assign sql_array <<'EOQ'
  SELECT AVG(val)
  FROM (
    SELECT  val
    FROM    (SELECT unnest(values) val
            FROM    sample_groups
            WHERE   measurement_id = (SELECT MIN(id) FROM measurements)) x
    ORDER BY val
    LIMIT  2 - MOD((SELECT array_upper(values, 1) FROM sample_groups WHERE measurement_id = (SELECT MIN(id) FROM measurements)), 2)
    OFFSET CEIL((SELECT array_upper(values, 1) FROM sample_groups WHERE measurement_id = (SELECT MIN(id) FROM measurements)) / 2.0) - 1
  ) sub
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION median_from_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
BEGIN
  RETURN (SELECT AVG(val)
          FROM (
            SELECT  val
            FROM    UNNEST(vals) val
            ORDER BY val
            LIMIT  2 - MOD(array_upper(vals, 1), 2)
            OFFSET CEIL(array_upper(vals, 1) / 2.0) - 1
          ) sub
         );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  median_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_median(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

