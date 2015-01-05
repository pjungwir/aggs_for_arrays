
############################################################################
echo
echo "array_to_kurtosis"
echo "================="
############################################################################

assign sql_rows <<EOQ
  WITH stats AS (
    SELECT  AVG(value) AS mean,
            STDDEV(value) AS stddev,
            COUNT(value) AS n
    FROM    samples
    WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  )
  SELECT  SUM((value - mean)^4 / n) / stddev^4
  FROM    samples,
          stats
  WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
  GROUP BY measurement_id, mean, stddev, n
  ;
EOQ

assign sql_array <<EOQ
  WITH stats AS (
    SELECT  AVG(v) AS mean,
            STDDEV(v) AS stddev,
            COUNT(v) AS n
    FROM    (SELECT UNNEST(values) v
             FROM   sample_groups
             WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
            ) y
  )
  SELECT  SUM((v - mean)^4 / n) / stddev^4
  FROM    (SELECT UNNEST(values) v
           FROM   sample_groups
           WHERE   measurement_id = (SELECT MIN(id) FROM measurements)
          ) x,
          stats
  GROUP BY mean, stddev, n
  ;
EOQ

query >/dev/null <<'EOQ'
CREATE OR REPLACE FUNCTION kurtosis_from_array (vals FLOAT[]) RETURNS FLOAT AS $$
DECLARE
BEGIN
  RETURN (
  WITH stats AS (
    SELECT  AVG(v) AS mean,
            STDDEV(v) AS stddev,
            COUNT(v) AS n
    FROM    UNNEST(vals) y(v)
  )
  SELECT  SUM((v - mean)^4 / n) / stddev^4
  FROM    UNNEST(vals) y(v),
          stats
  GROUP BY mean, stddev, n
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;
EOQ
 
assign plpgsql_array <<EOQ
  SELECT  kurtosis_from_array(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

assign c_array <<EOQ
  SELECT  array_to_kurtosis(values)
  FROM    sample_groups s
  WHERE   s.measurement_id = (SELECT MIN(id) FROM measurements)
  ;
EOQ

compare "$sql_rows" "$sql_array" "$plpgsql_array" "$c_array"

