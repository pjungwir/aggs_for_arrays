load test_helper

@test "float8 median empty" {
  result="$(query "SELECT array_to_median('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 median odd" {
  result="$(query "SELECT array_to_median('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "1" ]
}

@test "int32 median odd" {
  result="$(query "SELECT array_to_median('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "1" ]
}

@test "int64 median odd" {
  result="$(query "SELECT array_to_median('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "1" ]
}

@test "float4 median odd" {
  result="$(query "SELECT array_to_median('{1,1,5,2,0}'::real[])")";
  [ "$result" = "1" ]
}

@test "float8 median odd" {
  result="$(query "SELECT array_to_median('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "1" ]
}

@test "int16 median even" {
  result="$(query "SELECT array_to_median('{1,1,5,2,2,0}'::smallint[])")";
  [ "$result" = "1.5" ]
}

@test "int32 median even" {
  result="$(query "SELECT array_to_median('{1,1,5,2,2,0}'::integer[])")";
  [ "$result" = "1.5" ]
}

@test "int64 median even" {
  result="$(query "SELECT array_to_median('{1,1,5,2,2,0}'::bigint[])")";
  [ "$result" = "1.5" ]
}

@test "float4 median even" {
  result="$(query "SELECT array_to_median('{1,1,5,2,2,0}'::real[])")";
  [ "$result" = "1.5" ]
}

@test "float8 median even" {
  result="$(query "SELECT array_to_median('{1,1,5,2,2,0}'::double precision[])")";
  [ "$result" = "1.5" ]
}

@test "string median" {
  run query "SELECT array_to_median('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Median subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
