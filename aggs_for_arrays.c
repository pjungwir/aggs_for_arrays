#include <postgres.h>
#include <fmgr.h>
#include <utils/array.h>
#include <catalog/pg_type.h>
#include <utils/lsyscache.h>
#include <math.h>

PG_MODULE_MAGIC;

#include "util.c"
#include "array_to_hist.c"
#include "array_to_mean.c"
#include "array_to_median.c"
#include "sorted_array_to_median.c"
#include "array_to_mode.c"
#include "sorted_array_to_mode.c"
#include "array_to_max.c"
#include "array_to_min.c"
#include "array_to_min_max.c"
#include "array_to_percentile.c"
#include "array_to_percentiles.c"

