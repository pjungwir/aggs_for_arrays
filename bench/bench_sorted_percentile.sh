
############################################################################
echo
echo "sorted_array_to_percentile"
echo "=========================="
############################################################################
# These non-C implementations don't really take advantage
# of the index or the pre-sorted array,
# so I assume they could be improved,
# but I'm not really sure how.

assign sql_rows <<'EOQ'
SELECT  v1 + (v2 - v1) * (0.3 * m - floor(0.3 * m))
FROM    (
        SELECT  MIN(value) v1,
                MAX(value) v2,
                m
        FROM    (
                SELECT  value,
                        row_number() OVER (ORDER BY value ASC) - 1 r
                FROM    sorted_samples
                WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                ) x,
                (
                SELECT  COUNT(*) - 1 m
                FROM    sorted_samples
                WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                ) y
        WHERE   r = ceiling(0.3 * m)
        OR      r = floor(0.3 * m)
        GROUP BY m
        ) z
;
EOQ

assign sql_array <<'EOQ'
  WITH y AS (
    SELECT  array_length(values, 1) - 1 m
    FROM    sample_groups
    WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  )
  SELECT  v1 + (v2 - v1) * (0.3 * m - floor(0.3 * m))
  FROM    (
          SELECT  MIN(value) v1,
                  MAX(value) v2
          FROM    (
                  SELECT  value,
                          row_number() OVER (ORDER BY value ASC) - 1 r
                  FROM    (
                          SELECT  UNNEST(values) AS value
                          FROM    sorted_sample_groups
                          WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                          ) a
                  ) x
          WHERE   r = ceiling(0.3 * (SELECT m FROM y))
          OR      r = floor(0.3 * (SELECT m FROM y))
          ) z,
          y
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION percentile_from_sorted_array (vals FLOAT[], perc FLOAT) RETURNS FLOAT AS $$
DECLARE
  m integer;
BEGIN
  m := array_length(vals, 1);
  RETURN (
    SELECT  v1 + (v2 - v1) * (perc * m - floor(perc * m))
    FROM    (
            SELECT  MIN(value) v1,
                    MAX(value) v2
            FROM    (
                    SELECT  value,
                            row_number() OVER (ORDER BY value ASC) - 1 r
                    FROM    UNNEST(vals) AS value
                    ) x
            WHERE   r = ceiling(perc * m)
            OR      r = floor(perc * m)
            ) z
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  percentile_from_sorted_array(values, 0.3)
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  sorted_array_to_percentile(values, 0.3)
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

