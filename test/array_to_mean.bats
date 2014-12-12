load test_helper

@test "int16 mean" {
  result="$(query "SELECT array_to_mean('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "1" ]
}

@test "int32 mean" {
  result="$(query "SELECT array_to_mean('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "1" ]
}

@test "int64 mean" {
  result="$(query "SELECT array_to_mean('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "1" ]
}

@test "float4 mean" {
  result="$(query "SELECT array_to_mean('{1,1,5,2,0}'::real[])")";
  [ "$result" = "1.8" ]
}

@test "float8 mean" {
  result="$(query "SELECT array_to_mean('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "1.8" ]
}

@test "string mean" {
  run query "SELECT array_to_mean('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Mean subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
