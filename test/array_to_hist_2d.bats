load test_helper

@test "int32 2d histogram empty" {
  result="$(query "SELECT array_to_hist_2d('{}'::integer[], '{}'::integer[], 1, 1, 2, 2, 4, 4)")";
  echo $result
  [ "$result" = "{{0,0,0,0},{0,0,0,0},{0,0,0,0},{0,0,0,0}}" ]
}

@test "simple 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}', '{6,28,30,5,2}', 1, 1, 2, 10, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "int16 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}'::smallint[], '{6,28,30,5,2}'::smallint[], 1::smallint, 1::smallint, 2::smallint, 10::smallint, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "int32 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}'::integer[], '{6,28,30,5,2}'::integer[], 1::integer, 1::integer, 2::integer, 10::integer, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "int64 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}'::bigint[], '{6,28,30,5,2}'::bigint[], 1::bigint, 1::bigint, 2::bigint, 10::bigint, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "float4 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}'::real[], '{6,28,30,5,2}'::real[], 1::real, 1::real, 2::real, 10::real, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "float8 2d histogram" {
  result="$(query "SELECT array_to_hist_2d('{1,1,5,2,0}'::float[], '{6,28,30,5,2}'::float[], 1::float, 1::float, 2::float, 10::float, 4, 4)")";
  echo $result
  [ "$result" = "{{2,0,0,0},{0,0,0,0},{1,0,1,0},{0,0,0,0}}" ]
}

@test "string 2d histogram" {
  run query "SELECT array_to_hist_2d('{1,1,5,2,0}'::text[], '{6,28,30,5,2}'::text[], 1::text, 1::text, 2::text, 10::text, 4, 4)"
  [ "${lines[0]}" = "ERROR:  Histogram subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
  # [ "$status" -eq 1 ]
}
