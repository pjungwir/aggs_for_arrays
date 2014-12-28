
############################################################################
echo
echo "array_to_percentile"
echo "==================="
############################################################################

assign sql_rows <<'EOQ'
SELECT  v1 + (v2 - v1) * (0.3 * m - floor(0.3 * m))
FROM    (
        SELECT  MIN(value) v1,
                MAX(value) v2,
                m
        FROM    (
                SELECT  value,
                        row_number() OVER (ORDER BY value ASC) - 1 r
                FROM    samples
                WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                ) x,
                (
                SELECT  COUNT(*) - 1 m
                FROM    samples
                WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                ) y
        WHERE   r = ceiling(0.3 * m)
        OR      r = floor(0.3 * m)
        GROUP BY m
        ) z
;
EOQ

assign sql_array <<'EOQ'
  SELECT  v1 + (v2 - v1) * (0.3 * m - floor(0.3 * m))
  FROM    (
          SELECT  MIN(value) v1,
                  MAX(value) v2,
                  m
          FROM    (
                  SELECT  value,
                          row_number() OVER (ORDER BY value ASC) - 1 r
                  FROM    (
                          SELECT  UNNEST(values) AS value
                          FROM    sample_groups
                          WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                          ) a
                  ) x,
                  (
                  SELECT  COUNT(*) - 1 m
                  FROM    samples
                  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                  ) y
          WHERE   r = ceiling(0.3 * m)
          OR      r = floor(0.3 * m)
          GROUP BY m
          ) z
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION percentile_from_array (vals FLOAT[], perc FLOAT) RETURNS FLOAT AS $$
DECLARE
BEGIN
  RETURN (
    SELECT  v1 + (v2 - v1) * (perc * m - floor(perc * m))
    FROM    (
            SELECT  MIN(value) v1,
                    MAX(value) v2,
                    m
            FROM    (
                    SELECT  value,
                            row_number() OVER (ORDER BY value ASC) - 1 r
                    FROM    UNNEST(vals) AS value
                    ) x,
                    (
                    SELECT  COUNT(*) - 1 m
                    FROM    samples
                    WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                    ) y
            WHERE   r = ceiling(perc * m)
            OR      r = floor(perc * m)
            GROUP BY m
            ) z
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  percentile_from_array(values, 0.3)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_percentile(values, 0.3)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

