
Datum sorted_array_to_median(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(sorted_array_to_median);

/**
 * Returns a median from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
sorted_array_to_median(PG_FUNCTION_ARGS)
{
  // Our arguments:
  ArrayType *vals;

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

  float8 v = 0;
  int mid;

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
    ereport(ERROR, (errmsg("Median subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // Pull the middle item,
  // or if the list is even the two middles:

  if (valsLength == 0) PG_RETURN_NULL();

  mid = valsLength / 2;
  switch (valsType) {
    case INT2OID:
      v = DatumGetInt16(valsContent[mid]);
      if (valsLength % 2 == 0) {
        v += (DatumGetInt16(valsContent[mid - 1]) - v) / 2;
      }
      break;
    case INT4OID:
      v = DatumGetInt32(valsContent[mid]);
      if (valsLength % 2 == 0) {
        v += (DatumGetInt32(valsContent[mid - 1]) - v) / 2;
      }
      break;
    case INT8OID:
      v = DatumGetInt64(valsContent[mid]);
      if (valsLength % 2 == 0) {
        v += (DatumGetInt64(valsContent[mid - 1]) - v) / 2;
      }
      break;
    case FLOAT4OID:
      v = DatumGetFloat4(valsContent[mid]);
      if (valsLength % 2 == 0) {
        v += (DatumGetFloat4(valsContent[mid - 1]) - v) / 2;
      }
      break;
    case FLOAT8OID:
      v = DatumGetFloat8(valsContent[mid]);
      if (valsLength % 2 == 0) {
        v += (DatumGetFloat8(valsContent[mid - 1]) - v) / 2;
      }
      break;
    default:
      ereport(ERROR, (errmsg("Median subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
      break;
  }
  PG_RETURN_FLOAT8(v);
}

