#!/usr/bin/env bats

load test_helper

@test "simple histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}', 1, 2, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "int16 histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}'::smallint[], 1::smallint, 2::smallint, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "int32 histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}'::integer[], 1, 2, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "int64 histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}'::bigint[], 1::bigint, 2::bigint, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "float4 histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}'::real[], 1::real, 2::real, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "float8 histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}'::double precision[], 1::double precision, 2::double precision, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}

@test "string histogram" {
  run query "SELECT array_to_hist('{1,1,5,2,0}'::text[], '1'::text, '2'::text, 4)"
  [ "${lines[0]}" = "ERROR:  Histogram subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values" ]
  # [ "$status" -eq 1 ]
}
