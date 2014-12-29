

Datum array_to_median(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_median);

/**
 * Returns a median from an (unsorted) array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_median(PG_FUNCTION_ARGS)
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

  float8 v1 = 0;
  float8 v2 = 0;
  float8 *arr1;
  float8 *arr2;
  int i;
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

  if (valsLength == 0) PG_RETURN_NULL();

  // Compute the median without doing a full sort,
  // using the QuickSelect algorithm.
  // O(n).

  mid = valsLength / 2;

  arr1 = palloc0(sizeof(float8) * valsLength);
  switch (valsType) {
    case INT2OID:
      for (i = 0; i < valsLength; i++) {
        arr1[i] = DatumGetInt16(valsContent[i]);
      }
      break;
    case INT4OID:
      for (i = 0; i < valsLength; i++) {
        arr1[i] = DatumGetInt32(valsContent[i]);
      }
      break;
    case INT8OID:
      for (i = 0; i < valsLength; i++) {
        arr1[i] = DatumGetInt64(valsContent[i]);
      }
      break;
    case FLOAT4OID:
      for (i = 0; i < valsLength; i++) {
        arr1[i] = DatumGetFloat4(valsContent[i]);
      }
      break;
    case FLOAT8OID:
      for (i = 0; i < valsLength; i++) {
        arr1[i] = DatumGetFloat8(valsContent[i]);
      }
      break;
    default:
      ereport(ERROR, (errmsg("Median subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
      break;
  }

  if (valsLength % 2 == 1) {
    v1 = select_kth_value(arr1, valsLength, mid);
    PG_RETURN_FLOAT8(v1);

  } else {
    arr2 = palloc(sizeof(float8) * valsLength);
    memcpy(arr2, arr1, sizeof(float8) * valsLength);
    v1 = select_kth_value(arr1, valsLength, mid);
    v2 = select_kth_value(arr2, valsLength, mid - 1);
    v1 += (v2 - v1) / 2.0;
    PG_RETURN_FLOAT8(v1);
  }

}

