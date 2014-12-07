#include <postgres.h>
#include <fmgr.h>
#include <utils/array.h>
#include <catalog/pg_type.h>
#include <utils/lsyscache.h>

PG_MODULE_MAGIC;

Datum array_to_hist(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_hist);

/**
 * Returns a histogram from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_hist(PG_FUNCTION_ARGS)
{
  // Our arguments:
  ArrayType *vals;
  float8 bucketsStart;
  float8 bucketsSize;
  int32 bucketsCount;

  // The array element type (should always be FLOAT8OID):
  Oid valsType;

  // The array element type widths for our input and output arrays:
  int16 valsTypeWidth;
  int16 histTypeWidth;

  // The array element type "is passed by value" flags (not really used):
  bool valsTypeByValue;
  bool histTypeByValue;

  // The array element type alignment codes (not really used):
  char valsTypeAlignmentCode;
  char histTypeAlignmentCode;

  // The array contents, as PostgreSQL "Datum" objects:
  Datum *valsContent;
  Datum *histContent;

  // List of "is null" flags for the array contents (not used):
  bool *valsNullFlags;

  // The size of the input array:
  int valsLength;

  // The output array:
  ArrayType* histArray;

  int i;

  if (PG_ARGISNULL(0) || PG_ARGISNULL(1) || PG_ARGISNULL(2) || PG_ARGISNULL(3)) {
    ereport(ERROR, (errmsg("Null arrays not accepted")));
  }

  vals = PG_GETARG_ARRAYTYPE_P(0);
  bucketsStart = PG_GETARG_FLOAT8(1);
  bucketsSize = PG_GETARG_FLOAT8(2);
  bucketsCount = PG_GETARG_INT32(3);

  if (ARR_NDIM(vals) != 1) {
    ereport(ERROR, (errmsg("One-dimesional arrays are required")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  if (array_contains_nulls(vals)) {
    ereport(ERROR, (errmsg("Array contains null elements")));
  }

  // Determine the array element types.
  valsType = ARR_ELEMTYPE(vals);

  if (valsType != FLOAT8OID) {
    ereport(ERROR, (errmsg("Histogram subject must be DOUBLE PRECISION values")));
  }

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // Create a new array of histogram bins (as Datum objects).
  // Memory we palloc is freed automatically at the end of the transaction.
  histContent = palloc0(sizeof(Datum) * bucketsCount);

  // Generate the histogram
  float8 histMax = bucketsStart + (bucketsSize * bucketsCount);
  for (i = 0; i < valsLength; i++) {
    float8 v = DatumGetFloat8(valsContent[i]);
    if (v >= bucketsStart && v <= histMax) {
      int b = (v - bucketsStart) / bucketsSize;
      if (b >= 0 && b < bucketsCount) {
        histContent[b] = Int32GetDatum(DatumGetInt32(histContent[b]) + 1);
      }
    }
  }

  // Wrap the buckets in a new PostgreSQL array object.
  get_typlenbyvalalign(INT4OID, &histTypeWidth, &histTypeByValue, &histTypeAlignmentCode);
  histArray = construct_array(histContent, bucketsCount, INT4OID, histTypeWidth, histTypeByValue, histTypeAlignmentCode);

  // Return the final PostgreSQL array object.
  PG_RETURN_ARRAYTYPE_P(histArray);
}

