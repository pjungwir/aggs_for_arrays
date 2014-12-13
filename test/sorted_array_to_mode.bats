load test_helper

@test "float8 mode empty" {
  result="$(query "SELECT sorted_array_to_mode('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 mode one winner" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::smallint[])")";
  [ "$result" = "1" ]
}

@test "int32 mode one winner" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::integer[])")";
  [ "$result" = "1" ]
}

@test "int64 mode one winner" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::bigint[])")";
  [ "$result" = "1" ]
}

@test "float4 mode one winner" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::real[])")";
  [ "$result" = "1" ]
}

@test "float8 mode one winner" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::double precision[])")";
  [ "$result" = "1" ]
}

@test "int16 mode two winners" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,2,5}'::smallint[])")";
  [ "$result" = "1.5" ]
}

@test "int32 mode two winners" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,2,5}'::integer[])")";
  [ "$result" = "1.5" ]
}

@test "int64 mode two winners" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,2,5}'::bigint[])")";
  [ "$result" = "1.5" ]
}

@test "float4 mode two winners" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,2,5}'::real[])")";
  [ "$result" = "1.5" ]
}

@test "float8 mode two winners" {
  result="$(query "SELECT sorted_array_to_mode('{0,1,1,2,2,5}'::double precision[])")";
  [ "$result" = "1.5" ]
}

@test "string mode" {
  run query "SELECT sorted_array_to_mode('{0,1,1,2,5}'::text[])"
  [ "${lines[0]}" = "ERROR:  Mode subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
