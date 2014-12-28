
############################################################################
echo
echo "array_to_min"
echo "============="
############################################################################

assign sql_rows <<EOQ
  SELECT  MAX(value)
  FROM    samples
  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign sql_array <<EOQ
  SELECT  MAX(a)
  FROM    (SELECT UNNEST(values) a
           FROM   sample_groups
           WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
          ) x
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION min_from_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
  ret FLOAT;
  v FLOAT;
BEGIN
  ret := NULL;
  FOREACH v IN ARRAY vals LOOP
    IF ret IS NULL OR ret > v THEN
      ret := v;
    END IF;
  END LOOP;
 
  RETURN ret;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  min_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_min(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

