#include <postgres.h>
#include <fmgr.h>
#include <utils/array.h>
#include <catalog/pg_type.h>
#include <utils/lsyscache.h>

typedef union pgnum {
  int16 i16;
  int32 i32;
  int64 i64;
  float4 f4;
  float8 f8;
} pgnum;

PG_MODULE_MAGIC;

#include "util.c"
#include "array_to_hist.c"
#include "array_to_mean.c"
#include "array_to_median.c"
#include "sorted_array_to_median.c"
#include "array_to_mode.c"
#include "sorted_array_to_mode.c"

