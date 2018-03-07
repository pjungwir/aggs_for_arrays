load test_helper

@test "float8 max empty" {
  result="$(query "SELECT array_to_max('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 max" {
  result="$(query "SELECT array_to_max('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "5" ]
}

@test "int32 max" {
  result="$(query "SELECT array_to_max('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "5" ]
}

@test "int64 max" {
  result="$(query "SELECT array_to_max('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "5" ]
}

@test "float4 max" {
  result="$(query "SELECT array_to_max('{1,1,5,2,0}'::real[])")";
  [ "$result" = "5" ]
}

@test "float8 max" {
  result="$(query "SELECT array_to_max('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "5" ]
}

@test "float8 max only one null" {
  result="$(query "SELECT array_to_max('{NULL}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "float8 max one null mixed" {
  result="$(query "SELECT array_to_max('{1,1,NULL,2,0}'::double precision[])")";
  [ "$result" = "2" ]
}

@test "float8 max one leading null" {
  result="$(query "SELECT array_to_max('{NULL,-1,-1,-2}'::double precision[])")";
  [ "$result" = "-1" ]
}

@test "float8 max one trailing null" {
  result="$(query "SELECT array_to_max('{-1,-1,-2,NULL}'::double precision[])")";
  [ "$result" = "-1" ]
}

@test "string max" {
  run query "SELECT array_to_max('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Max subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
