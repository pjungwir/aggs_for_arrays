load test_helper

# '{1,1,5,2,0}':
# mean is 1.8
# stddev is sqrt(14.8/5) or ~1.72046505340852535434
# skewness is ((1-1.8)^3/5 + (1-1.8)^3/5 + (5-1.8)^3/5 + (2-1.8)^3/5 + (0-1.8)^3/5) / sqrt(14.8/5)^3
#   or ~1.01795229602695802559

@test "float8 skewness empty" {
  result="$(query "SELECT array_to_skewness('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 skewness" {
  query "SELECT array_to_skewness('{1,1,5,2,0}'::smallint[])"
  result="$(query "SELECT array_to_skewness('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "1.01795229602696" ]
}

@test "int32 skewness" {
  result="$(query "SELECT array_to_skewness('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "1.01795229602696" ]
}

@test "int64 skewness" {
  result="$(query "SELECT array_to_skewness('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "1.01795229602696" ]
}

@test "float4 skewness" {
  result="$(query "SELECT array_to_skewness('{1,1,5,2,0}'::real[])")";
  [ "$result" = "1.01795229602696" ]
}

@test "float8 skewness" {
  result="$(query "SELECT array_to_skewness('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "1.01795229602696" ]
}

@test "string skewness" {
  run query "SELECT array_to_skewness('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Skewness subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
