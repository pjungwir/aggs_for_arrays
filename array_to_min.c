
Datum array_to_min(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_min);

/**
 * Returns a min from an (unsorted) array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_min(PG_FUNCTION_ARGS)
{
  // Our arguments:
  ArrayType *vals;

  // The array element type:
  Oid valsType;

  // The array element type widths for our input array:
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

  int i;
  pgnum v;

  if (PG_ARGISNULL(0)) {
    ereport(ERROR, (errmsg("Null arrays not accepted")));
  }

  vals = PG_GETARG_ARRAYTYPE_P(0);

  if (ARR_NDIM(vals) == 0) {
    PG_RETURN_NULL();
  }
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
    ereport(ERROR, (errmsg("Min subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  if (valsLength == 0) PG_RETURN_NULL();

  // Compute the min.

  switch (valsType) {
    case INT2OID:
      v.i16 = DatumGetInt16(valsContent[0]);
      for (i = 1; i < valsLength; i++) {
        if (DatumGetInt16(valsContent[i]) < v.i16) v.i16 = DatumGetInt16(valsContent[i]);
      }
      PG_RETURN_INT16(v.i16);
      break;
    case INT4OID:
      v.i32 = DatumGetInt32(valsContent[0]);
      for (i = 1; i < valsLength; i++) {
        if (DatumGetInt32(valsContent[i]) < v.i32) v.i32 = DatumGetInt32(valsContent[i]);
      }
      PG_RETURN_INT32(v.i32);
      break;
    case INT8OID:
      v.i64 = DatumGetInt64(valsContent[0]);
      for (i = 1; i < valsLength; i++) {
        if (DatumGetInt64(valsContent[i]) < v.i64) v.i64 = DatumGetInt64(valsContent[i]);
      }
      PG_RETURN_INT64(v.i64);
      break;
    case FLOAT4OID:
      v.f4 = DatumGetFloat4(valsContent[0]);
      for (i = 1; i < valsLength; i++) {
        if (DatumGetFloat4(valsContent[i]) < v.f4) v.f4 = DatumGetFloat4(valsContent[i]);
      }
      PG_RETURN_FLOAT4(v.f4);
      break;
    case FLOAT8OID:
      v.f8 = DatumGetFloat8(valsContent[0]);
      for (i = 1; i < valsLength; i++) {
        if (DatumGetFloat8(valsContent[i]) < v.f8) v.f8 = DatumGetFloat8(valsContent[i]);
      }
      PG_RETURN_FLOAT8(v.f8);
      break;
    default:
      ereport(ERROR, (errmsg("Min subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
      break;
  }

}

