load test_helper

@test "float8 sorted percentile empty" {
  result="$(query "SELECT sorted_array_to_percentile('{}'::double precision[], 0.2)")";
  [ "$result" = "NULL" ]
}

@test "int16 sorted percentile" {
  # query "SELECT sorted_array_to_percentile('{0,1,1,2,5}'::smallint[], 0.2)"
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::smallint[], 0.2)")";
  [ "$result" = "1" ]
}

@test "int32 sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::integer[], 0.2)")";
  [ "$result" = "1" ]
}

@test "int64 sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::bigint[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float4 sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::real[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float8 sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::double precision[], 0.2)")";
  [ "$result" = "1" ]
}

@test "float8 0th sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::double precision[], 0)")";
  [ "$result" = "0" ]
}

@test "float8 100th sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::double precision[], 1)")";
  [ "$result" = "7" ]
}

@test "float8 0.5 sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,2,3,5}'::double precision[], 0.5)")";
  [ "$result" = "2" ]
}

@test "float8 in-between sorted percentile" {
  result="$(query "SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::double precision[], 0.5)")";
  [ "$result" = "1.5" ]
}

@test "float8 sorted percentile less than zero" {
  run query "SELECT sorted_array_to_percentile('{0,1,1,2,5}'::double precision[], -0.2)"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "float8 sorted percentile greater than one" {
  run query "SELECT sorted_array_to_percentile('{0,1,1,2,5}'::double precision[], 1.2)"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "string sorted percentile" {
  run query "SELECT sorted_array_to_percentile('{0,1,1,2,5}'::text[], 0.2)"
  [ "${lines[0]}" = "ERROR:  Percentile subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}
