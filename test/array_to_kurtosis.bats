load test_helper

# '{1,1,5,2,0}':
# mean is 1.8
# stddev is sqrt(14.8/5) or ~1.72046505340852535434
# kurtosis is ((1-1.8)^4/5 + (1-1.8)^4/5 + (5-1.8)^4/5 + (2-1.8)^4/5 + (0-1.8)^4/5) / sqrt(14.8/5)^4
#   or ~2.65193571950328707089

@test "float8 kurtosis empty" {
  result="$(query "SELECT array_to_kurtosis('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 kurtosis" {
  query "SELECT array_to_kurtosis('{1,1,5,2,0}'::smallint[])"
  result="$(query "SELECT array_to_kurtosis('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "2.65193571950329" ]
}

@test "int32 kurtosis" {
  result="$(query "SELECT array_to_kurtosis('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "2.65193571950329" ]
}

@test "int64 kurtosis" {
  result="$(query "SELECT array_to_kurtosis('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "2.65193571950329" ]
}

@test "float4 kurtosis" {
  result="$(query "SELECT array_to_kurtosis('{1,1,5,2,0}'::real[])")";
  [ "$result" = "2.65193571950329" ]
}

@test "float8 kurtosis" {
  result="$(query "SELECT array_to_kurtosis('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "2.65193571950329" ]
}

@test "string kurtosis" {
  run query "SELECT array_to_kurtosis('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Kurtosis subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
