
Datum sorted_array_to_percentile(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(sorted_array_to_percentile);

/**
 * Returns a percentile from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
sorted_array_to_percentile(PG_FUNCTION_ARGS)
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

  float8 *floatVals;
  int i;
  float8 perc;
  float8 floatPos;
  float8 v = 0;

  if (PG_ARGISNULL(0) || PG_ARGISNULL(1)) {
    ereport(ERROR, (errmsg("Null arguments not accepted")));
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
    ereport(ERROR, (errmsg("Percentile subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  perc = PG_GETARG_FLOAT8(1);

  if (perc < 0 || perc > 1) {
    ereport(ERROR, (errmsg("Percent must be between 0 and 1")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // Compute the percentile:

  floatVals = palloc(sizeof(float8) * valsLength);

  switch (valsType) {
    case INT2OID:
      for (i = 0; i < valsLength; i++) {
        floatVals[i] = DatumGetInt16(valsContent[i]);
      }
      break;
    case INT4OID:
      for (i = 0; i < valsLength; i++) {
        floatVals[i] = DatumGetInt32(valsContent[i]);
      }
      break;
    case INT8OID:
      for (i = 0; i < valsLength; i++) {
        floatVals[i] = DatumGetInt64(valsContent[i]);
      }
      break;
    case FLOAT4OID:
      for (i = 0; i < valsLength; i++) {
        floatVals[i] = DatumGetFloat4(valsContent[i]);
      }
      break;
    case FLOAT8OID:
      for (i = 0; i < valsLength; i++) {
        floatVals[i] = DatumGetFloat8(valsContent[i]);
      }
      break;
    default:
      ereport(ERROR, (errmsg("Percentile subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
      break;
  }

  // no need to sort here

  floatPos = (valsLength - 1) * perc;
  v = floatVals[(int)floatPos];
  if (floorl(floatPos) != floatPos) {
    v += (floatVals[(int)floatPos + 1] - v) * (floatPos - floorl(floatPos));
  }
  PG_RETURN_FLOAT8(v);
}

