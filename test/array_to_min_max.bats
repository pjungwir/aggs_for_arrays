load test_helper

@test "float8 min_max empty" {
  result="$(query "SELECT array_to_min_max('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 min_max" {
  result="$(query "SELECT array_to_min_max('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "{0,5}" ]
}

@test "int32 min_max" {
  result="$(query "SELECT array_to_min_max('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "{0,5}" ]
}

@test "int64 min_max" {
  result="$(query "SELECT array_to_min_max('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "{0,5}" ]
}

@test "float4 min_max" {
  result="$(query "SELECT array_to_min_max('{1,1,5,2,0}'::real[])")";
  [ "$result" = "{0,5}" ]
}

@test "float8 min_max" {
  result="$(query "SELECT array_to_min_max('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "{0,5}" ]
}

@test "float8 min_max only one null" {
  result="$(query "SELECT array_to_min_max('{NULL}'::double precision[])")";
  [ "$result" = "{NULL,NULL}" ]
}

@test "float8 min_max one null mixed" {
  result="$(query "SELECT array_to_min_max('{1,1,NULL,2,0}'::double precision[])")";
  [ "$result" = "{0,2}" ]
}

@test "float8 min_max one leading null" {
  result="$(query "SELECT array_to_min_max('{NULL,1,1,2}'::double precision[])")";
  [ "$result" = "{1,2}" ]
}

@test "float8 min_max one trailing null" {
  result="$(query "SELECT array_to_min_max('{1,1,2,NULL}'::double precision[])")";
  [ "$result" = "{1,2}" ]
}

@test "float8 min_max all negatives, one leading null" {
  result="$(query "SELECT array_to_min_max('{NULL,-1,-1,-2}'::double precision[])")";
  [ "$result" = "{-2,-1}" ]
}

@test "float8 min_max all negatives, one trailing null" {
  result="$(query "SELECT array_to_min_max('{-1,-1,-2,NULL}'::double precision[])")";
  [ "$result" = "{-2,-1}" ]
}

@test "string min_max" {
  run query "SELECT array_to_min_max('{1,1,5,2,0}'::text[])"
  [ "${lines[0]}" = "ERROR:  Minmax subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
