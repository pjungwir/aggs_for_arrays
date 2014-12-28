
############################################################################
echo
echo "array_to_min_max"
echo "============="
############################################################################

assign sql_rows <<EOQ
  SELECT  MIN(value), MAX(value)
  FROM    samples
  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign sql_array <<EOQ
  SELECT  MIN(a), MAX(a)
  FROM    (SELECT UNNEST(values) a
           FROM   sample_groups
           WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
          ) x
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION min_max_from_array (vals FLOAT[]) RETURNS FLOAT[] AS $$
DECLARE
  ret_min FLOAT;
  ret_max FLOAT;
  v FLOAT;
BEGIN
  ret_min := NULL;
  ret_max := NULL;
  FOREACH v IN ARRAY vals LOOP
    IF ret_min IS NULL OR ret_min > v THEN
      ret_min := v;
    END IF;
    IF ret_max IS NULL OR ret_max < v THEN
      ret_max := v;
    END IF;
  END LOOP;
 
  RETURN ARRAY[ret_min, ret_max];
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  min_max_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_min_max(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

