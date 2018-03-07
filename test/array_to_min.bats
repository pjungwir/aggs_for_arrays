load test_helper

@test "float8 min empty" {
  result="$(query "SELECT array_to_min('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 min" {
  result="$(query "SELECT array_to_min('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "0" ]
}

@test "int32 min" {
  result="$(query "SELECT array_to_min('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "0" ]
}

@test "int64 min" {
  result="$(query "SELECT array_to_min('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "0" ]
}

@test "float4 min" {
  result="$(query "SELECT array_to_min('{1,1,5,2,0}'::real[])")";
  [ "$result" = "0" ]
}

@test "float8 min" {
  result="$(query "SELECT array_to_min('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "0" ]
}

@test "float8 min only one null" {
  result="$(query "SELECT array_to_min('{NULL}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "float8 min one null mixed" {
  result="$(query "SELECT array_to_min('{1,1,NULL,2,0}'::double precision[])")";
  [ "$result" = "0" ]
}

@test "float8 min one leading null" {
  result="$(query "SELECT array_to_min('{NULL,1,1,2}'::double precision[])")";
  [ "$result" = "1" ]
}

@test "float8 min one trailing null" {
  result="$(query "SELECT array_to_min('{1,1,2,NULL}'::double precision[])")";
  [ "$result" = "1" ]
}

@test "string min" {
  run query "SELECT array_to_min('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Min subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
