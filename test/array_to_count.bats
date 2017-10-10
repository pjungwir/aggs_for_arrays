load test_helper

@test "float8 count empty" {
  result="$(query "SELECT array_to_count('{}'::double precision[])")";
  [ "$result" = "NULL" ]
}

@test "int16 count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::smallint[])")";
  [ "$result" = "5" ]
}

@test "int32 count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::integer[])")";
  [ "$result" = "5" ]
}

@test "int64 count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::bigint[])")";
  [ "$result" = "5" ]
}

@test "float4 count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::real[])")";
  [ "$result" = "5" ]
}

@test "float8 count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::double precision[])")";
  [ "$result" = "5" ]
}

@test "float8 count only one null" {
  result="$(query "SELECT array_to_count('{NULL}'::double precision[])")";
  [ "$result" = "0" ]
}

@test "float8 count one null mixed" {
  result="$(query "SELECT array_to_count('{1,1,NULL,2,0}'::double precision[])")";
  [ "$result" = "4" ]
}

@test "string count" {
  result="$(query "SELECT array_to_count('{1,1,5,2,0}'::text[])")";
  [ "$result" = "5" ]
}
