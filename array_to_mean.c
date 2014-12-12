
Datum array_to_mean(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_mean);

/**
 * Returns a mean from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_mean(PG_FUNCTION_ARGS)
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

  // The array element type "is passed by value" flags (not really used):
  bool valsTypeByValue;

  // The array element type alignment codes (not really used):
  char valsTypeAlignmentCode;

  // The array contents, as PostgreSQL "Datum" objects:
  Datum *valsContent;

  // List of "is null" flags for the array contents (not used):
  bool *valsNullFlags;

  // The size of the input array:
  int valsLength;

  pgnum v;
  int i;

  if (PG_ARGISNULL(0)) {
    ereport(ERROR, (errmsg("Null arrays not accepted")));
  }

  vals = PG_GETARG_ARRAYTYPE_P(0);

  if (ARR_NDIM(vals) != 1) {
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
      v.i16 = 0;
      break;
    case INT4OID:
      v.i32 = 0;
      break;
    case INT8OID:
      v.i64 = 0;
      break;
    case FLOAT4OID:
      v.f4 = 0;
      break;
    case FLOAT8OID:
      v.f8 = 0;
      break;
    default:
      break;
  }

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // TODO: Iterate through the contents and sum things up.
  
  // Return the mean:
  switch (valsType) {
    case INT2OID:
      PG_RETURN_INT16(v.i16 / valsLength);
      break;
    case INT4OID:
      PG_RETURN_INT32(v.i32 / valsLength);
      break;
    case INT8OID:
      PG_RETURN_INT64(v.i64 / valsLength);
      break;
    case FLOAT4OID:
      PG_RETURN_FLOAT4(v.f4 / valsLength);
      break;
    case FLOAT8OID:
      PG_RETURN_FLOAT8(v.f8 / valsLength);
      break;
    default:
      PG_RETURN_FLOAT8(0);
      break;
  }
}

