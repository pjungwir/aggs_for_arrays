load test_helper

@test "float8 sorted many-percentiles empty data" {
  result="$(query "SELECT sorted_array_to_percentiles('{}'::float[], '{0.2, 0.4}'::float[])")";
  [ "$result" = "NULL" ]
}

@test "float8 sorted many-percentiles empty percents" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::float[], '{}'::float[])")";
  [ "$result" = "NULL" ]
}

@test "int16 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::smallint[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "int32 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::integer[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "int64 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::bigint[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float4 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::real[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float8 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::float[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float8 0th sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::float[], '{0,0.2}'::float[])")";
  [ "$result" = "{0,1}" ]
}

@test "float8 100th sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::float[], '{0.2,1}'::float[])")";
  [ "$result" = "{1,7}" ]
}

@test "float8 0.5 sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,2,3,5}'::float[], '{0.5}'::float[])")";
  [ "$result" = "{2}" ]
}

@test "float8 in-between sorted many-percentiles" {
  result="$(query "SELECT sorted_array_to_percentiles('{0,1,1,2,5,7}'::float[], '{0.5}'::float[])")";
  [ "$result" = "{1.5}" ]
}

@test "float8 sorted many-percentiles less than zero" {
  query "SELECT sorted_array_to_percentiles('{0,1,1,2,5}'::float[], '{-0.2,0.4}'::float[])"
  run query "SELECT sorted_array_to_percentiles('{0,1,1,2,5}'::float[], '{-0.2,0.4}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "float8 sorted many-percentiles greater than one" {
  run query "SELECT sorted_array_to_percentiles('{0,1,1,2,5}'::float[], '{1.2}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "string sorted many-percentiles" {
  run query "SELECT sorted_array_to_percentiles('{0,1,1,2,5}'::text[], '{0.2}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percentiles subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}

