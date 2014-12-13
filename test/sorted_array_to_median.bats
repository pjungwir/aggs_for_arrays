load test_helper

@test "float8 median empty" {
  result="$(query "SELECT sorted_array_to_median('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 median odd" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,5}'::smallint[])")";
  [ "$result" = "1" ]
}

@test "int32 median odd" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,5}'::integer[])")";
  [ "$result" = "1" ]
}

@test "int64 median odd" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,5}'::bigint[])")";
  [ "$result" = "1" ]
}

@test "float4 median odd" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,5}'::real[])")";
  [ "$result" = "1" ]
}

@test "float8 median odd" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,5}'::double precision[])")";
  [ "$result" = "1" ]
}

@test "int16 median even" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::smallint[])")";
  [ "$result" = "1.5" ]
}

@test "int32 median even" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::integer[])")";
  [ "$result" = "1.5" ]
}

@test "int64 median even" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::bigint[])")";
  [ "$result" = "1.5" ]
}

@test "float4 median even" {
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::real[])")";
  [ "$result" = "1.5" ]
}

@test "float8 median even" {
  query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::double precision[])";
  result="$(query "SELECT sorted_array_to_median('{0,1,1,2,2,5}'::double precision[])")";
  [ "$result" = "1.5" ]
}

@test "string median" {
  run query "SELECT sorted_array_to_median('{0,1,1,2,5}'::text[])"
  [ "${lines[0]}" = "ERROR:  Median subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
