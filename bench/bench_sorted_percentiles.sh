
############################################################################
echo
echo "sorted_array_to_percentiles"
echo "==========================="
############################################################################
# These non-C implementations don't really take advantage
# of the index or the pre-sorted array,
# so I assume they could be improved,
# but I'm not really sure how.

assign sql_rows <<'EOQ'
SELECT  perc,
        v1 + (v2 - v1) * (perc * m - floor(perc * m))
FROM    (
        SELECT  MIN(value) v1,
                MAX(value) v2,
                perc,
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
                ) y,
                (
                SELECT  a * 0.20 AS perc
                FROM    generate_series(0, 5) s(a)
                ) z
        WHERE   r = ceiling(perc * m)
        OR      r = floor(perc * m)
        GROUP BY perc, m
        ) w
;
EOQ

assign sql_array <<'EOQ'
  WITH y AS (
    SELECT  array_length(values, 1) - 1 m
    FROM    sample_groups
    WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  )
  SELECT  perc,
          v1 + (v2 - v1) * (perc * m - floor(perc * m))
  FROM    (
          SELECT  MIN(value) v1,
                  MAX(value) v2,
                  perc
          FROM    (
                  SELECT  value,
                          row_number() OVER (ORDER BY value ASC) - 1 r
                  FROM    (
                          SELECT  UNNEST(values) AS value
                          FROM    sorted_sample_groups
                          WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
                          ) a
                  ) x,
                  (
                  SELECT  a * 0.20 AS perc
                  FROM    generate_series(0, 5) s(a)
                  ) z
          WHERE   r = ceiling(perc * (SELECT m FROM y))
          OR      r = floor(perc * (SELECT m FROM y))
          GROUP BY perc
          ) w,
          y
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION percentiles_from_sorted_array (vals FLOAT[], percs FLOAT[]) RETURNS FLOAT[] AS $$
DECLARE
  m integer;
BEGIN
  m := array_length(vals, 1);
  RETURN (
    SELECT  array_agg(v1 + (v2 - v1) * (perc * m - floor(perc * m)))
    FROM    (
            SELECT  MIN(value) v1,
                    MAX(value) v2,
                    perc
            FROM    (
                    SELECT  value,
                            row_number() OVER (ORDER BY value ASC) - 1 r
                    FROM    UNNEST(vals) AS value
                    ) x,
                    UNNEST(percs) AS perc
            WHERE   r = ceiling(perc * m)
            OR      r = floor(perc * m)
            GROUP BY perc, m
            ) w
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  percentiles_from_sorted_array(values, ARRAY[0, 0.2, 0.4, 0.6, 0.8, 1])
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  sorted_array_to_percentiles(values, ARRAY[0, 0.2, 0.4, 0.6, 0.8, 1])
  FROM    sorted_sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

