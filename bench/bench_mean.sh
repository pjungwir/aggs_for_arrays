
############################################################################
echo
echo "array_to_mean"
echo "============="
############################################################################

assign sql_rows <<EOQ
  SELECT  AVG(value)
  FROM    samples
  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign sql_array <<EOQ
  SELECT  AVG(a)
  FROM    (SELECT UNNEST(values) a
           FROM   sample_groups
           WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
          ) x
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION mean_from_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
  sum FLOAT;
  v FLOAT;
BEGIN
  sum := 0;
  FOREACH v IN ARRAY vals LOOP
    sum := sum + v;
  END LOOP;
 
  RETURN sum / array_length(vals, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  mean_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_mean(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

