
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
  pgnum bucketsStart;
  pgnum bucketsSize;
  int32 bucketsCount;

  // The array element type:
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

  pgnum histMax;
  pgnum v;
  int i;

  if (PG_ARGISNULL(0) || PG_ARGISNULL(1) || PG_ARGISNULL(2) || PG_ARGISNULL(3)) {
    ereport(ERROR, (errmsg("Null arguments not accepted")));
  }

  vals = PG_GETARG_ARRAYTYPE_P(0);

  if (ARR_NDIM(vals) > 1) {
    ereport(ERROR, (errmsg("One-dimesional arrays are required")));
  }

  if (array_contains_nulls(vals)) {
    ereport(ERROR, (errmsg("Array contains null elements")));
  }

  // Determine the array element types.
  valsType = ARR_ELEMTYPE(vals);

  if (valsType != INT2OID &&
      valsType != INT4OID &&
      valsType != INT8OID &&
      valsType != FLOAT4OID &&
      valsType != FLOAT8OID) {
    ereport(ERROR, (errmsg("Histogram subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  switch (valsType) {
    case INT2OID:
      bucketsStart.i16 = PG_GETARG_INT16(1);
      bucketsSize.i16 = PG_GETARG_INT16(2);
      break;
    case INT4OID:
      bucketsStart.i32 = PG_GETARG_INT32(1);
      bucketsSize.i32 = PG_GETARG_INT32(2);
      break;
    case INT8OID:
      bucketsStart.i64 = PG_GETARG_INT64(1);
      bucketsSize.i64 = PG_GETARG_INT64(2);
      break;
    case FLOAT4OID:
      bucketsStart.f4 = PG_GETARG_FLOAT4(1);
      bucketsSize.f4 = PG_GETARG_FLOAT4(2);
      break;
    case FLOAT8OID:
      bucketsStart.f8 = PG_GETARG_FLOAT8(1);
      bucketsSize.f8 = PG_GETARG_FLOAT8(2);
      break;
    default:
      ereport(ERROR, (errmsg("Unexpected array type: %u", valsType)));
  }
  bucketsCount = PG_GETARG_INT32(3);

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // Create a new array of histogram bins (as Datum objects).
  // Memory we palloc is freed automatically at the end of the transaction.
  histContent = palloc0(sizeof(Datum) * bucketsCount);

  // Generate the histogram
  switch (valsType) {
    case INT2OID:
      histMax.i16 = bucketsStart.i16 + (bucketsSize.i16 * bucketsCount);
      for (i = 0; i < valsLength; i++) {
        v.i16 = DatumGetInt16(valsContent[i]);
        if (v.i16 >= bucketsStart.i16 && v.i16 <= histMax.i16) {
          int b = (v.i16 - bucketsStart.i16) / bucketsSize.i16;
          if (b >= 0 && b < bucketsCount) {
            histContent[b] = Int16GetDatum(DatumGetInt16(histContent[b]) + 1);
          }
        }
      }
      break;
    case INT4OID:
      histMax.i32 = bucketsStart.i32 + (bucketsSize.i32 * bucketsCount);
      for (i = 0; i < valsLength; i++) {
        v.i32 = DatumGetInt32(valsContent[i]);
        if (v.i32 >= bucketsStart.i32 && v.i32 <= histMax.i32) {
          int b = (v.i32 - bucketsStart.i32) / bucketsSize.i32;
          if (b >= 0 && b < bucketsCount) {
            histContent[b] = Int32GetDatum(DatumGetInt32(histContent[b]) + 1);
          }
        }
      }
      break;
    case INT8OID:
      histMax.i64 = bucketsStart.i64 + (bucketsSize.i64 * bucketsCount);
      for (i = 0; i < valsLength; i++) {
        v.i64 = DatumGetInt64(valsContent[i]);
        if (v.i64 >= bucketsStart.i64 && v.i64 <= histMax.i64) {
          int b = (v.i64 - bucketsStart.i64) / bucketsSize.i64;
          if (b >= 0 && b < bucketsCount) {
            histContent[b] = Int64GetDatum(DatumGetInt64(histContent[b]) + 1);
          }
        }
      }
      break;
    case FLOAT4OID:
      histMax.f4 = bucketsStart.f4 + (bucketsSize.f4 * bucketsCount);
      for (i = 0; i < valsLength; i++) {
        v.f4 = DatumGetFloat4(valsContent[i]);
        if (v.f4 >= bucketsStart.f4 && v.f4 <= histMax.f4) {
          int b = (v.f4 - bucketsStart.f4) / bucketsSize.f4;
          if (b >= 0 && b < bucketsCount) {
            histContent[b] = Int32GetDatum(DatumGetInt32(histContent[b]) + 1);
          }
        }
      }
      break;
    case FLOAT8OID:
      histMax.f8 = bucketsStart.f8 + (bucketsSize.f8 * bucketsCount);
      for (i = 0; i < valsLength; i++) {
        v.f8 = DatumGetFloat8(valsContent[i]);
        if (v.f8 >= bucketsStart.f8 && v.f8 <= histMax.f8) {
          int b = (v.f8 - bucketsStart.f8) / bucketsSize.f8;
          if (b >= 0 && b < bucketsCount) {
            histContent[b] = Int32GetDatum(DatumGetInt32(histContent[b]) + 1);
          }
        }
      }
      break;
    default:
      ereport(ERROR, (errmsg("Unexpected array type: %u", valsType)));
  }

  // Wrap the buckets in a new PostgreSQL array object.
  get_typlenbyvalalign(INT4OID, &histTypeWidth, &histTypeByValue, &histTypeAlignmentCode);
  histArray = construct_array(histContent, bucketsCount, INT4OID, histTypeWidth, histTypeByValue, histTypeAlignmentCode);

  // Return the final PostgreSQL array object.
  PG_RETURN_ARRAYTYPE_P(histArray);
}

