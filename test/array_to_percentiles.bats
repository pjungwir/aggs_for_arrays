load test_helper

@test "float8 many-percentiles empty data" {
  result="$(query "SELECT array_to_percentiles('{}'::float[], '{0.2, 0.4}'::float[])")";
  [ "$result" = "NULL" ]
}

@test "float8 many-percentiles empty percents" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{}'::float[])")";
  [ "$result" = "NULL" ]
}

@test "int16 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::smallint[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "int32 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::integer[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "int64 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::bigint[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float4 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::real[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float8 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.2,0.4}'::float[])")";
  [ "$result" = "{1,1}" ]
}

@test "float8 0th many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0,0.2}'::float[])")";
  [ "$result" = "{0,1}" ]
}

@test "float8 100th many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.2,1}'::float[])")";
  [ "$result" = "{1,7}" ]
}

@test "float8 0.5 many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,2,5,3,0}'::float[], '{0.5}'::float[])")";
  [ "$result" = "{2}" ]
}

@test "float8 in-between many-percentiles" {
  result="$(query "SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.5}'::float[])")";
  [ "$result" = "{1.5}" ]
}

@test "float8 many-percentiles less than zero" {
  query "SELECT array_to_percentiles('{1,1,5,2,0}'::float[], '{-0.2,0.4}'::float[])"
  run query "SELECT array_to_percentiles('{1,1,5,2,0}'::float[], '{-0.2,0.4}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "float8 many-percentiles greater than one" {
  run query "SELECT array_to_percentiles('{1,1,5,2,0}'::float[], '{1.2}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percent must be between 0 and 1" ]
}

@test "string many-percentiles" {
  run query "SELECT array_to_percentiles('{1,1,5,2,0}'::text[], '{0.2}'::float[])"
  [ "${lines[0]}" = "ERROR:  Percentiles subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
}

