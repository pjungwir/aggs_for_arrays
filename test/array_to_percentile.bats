load test_helper

@test "float8 percentile empty" {
  result="$(query "SELECT array_to_percentile('{}'::double precision[], 0.2)")";
  [ "$result" = "NULL" ]
}

@test "int16 percentile" {
  query "SELECT array_to_percentile('{1,1,5,2,0}'::smallint[], 0.2)"
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::smallint[], 0.2)")";
  [ "$result" = "1" ]
}

@test "int32 percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::integer[], 0.2)")";
  [ "$result" = "1" ]
}

@test "int64 percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::bigint[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float4 percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::real[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float8 percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::double precision[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float8 0th percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::double precision[], 0)")";
  [ "$result" = "0" ]
}

@test "float8 100th percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::double precision[], 1)")";
  [ "$result" = "7" ]
}

@test "float8 0.5 percentile" {
  result="$(query "SELECT array_to_percentile('{1,2,5,3,0}'::double precision[], 0.5)")";
  [ "$result" = "2" ]
}

@test "float8 in-between percentile" {
  result="$(query "SELECT array_to_percentile('{1,1,5,2,0,7}'::double precision[], 0.5)")";
  [ "$result" = "1.5" ]
}

@test "float8 percentile less than zero" {
  run query "SELECT array_to_percentile('{1,1,5,2,0}'::double precision[], -0.2)"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "float8 percentile greater than one" {
  run query "SELECT array_to_percentile('{1,1,5,2,0}'::double precision[], 1.2)"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "string percentile" {
  run query "SELECT array_to_percentile('{1,1,5,2,0}'::text[], 0.2)"
  [ "${lines[0]}" = "ERROR:  Percentile subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
