#!/usr/bin/env bats

load test_helper

@test "simple histogram" {
  result="$(query "SELECT array_to_hist('{1,1,5,2,0}', 1, 2, 4)")";
  [ "$result" = "{3,0,1,0}" ]
}


