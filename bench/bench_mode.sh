
############################################################################
echo
echo "array_to_mode"
echo "==============="
############################################################################

assign sql_rows <<EOQ
  SELECT  AVG(value)
  FROM    (
          SELECT  value,
                  RANK() OVER (ORDER BY COUNT(*) DESC) r
          FROM    samples
          WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
          GROUP BY value
          ) x
  WHERE   r = 1
  ;
EOQ

assign sql_array <<'EOQ'
  SELECT  AVG(val)
  FROM    (
          SELECT  val,
                  RANK() OVER (ORDER BY COUNT(*) DESC) r
          FROM    (
                  SELECT  UNNEST(values) val
                  FROM    sample_groups
                  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                  ) y
          GROUP BY val
          ) x
  WHERE   r = 1
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION mode_from_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
BEGIN
  RETURN (
    SELECT  AVG(val)
    FROM    (
            SELECT  val,
                    RANK() OVER (ORDER BY COUNT(*) DESC) r
            FROM    UNNEST(vals) val
            GROUP BY val
            ) x
    WHERE   r = 1
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  mode_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_mode(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

