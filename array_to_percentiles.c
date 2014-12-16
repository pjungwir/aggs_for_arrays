
Datum array_to_percentiles(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_percentiles);

/**
 * Returns a list of percentiles from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_percentiles(PG_FUNCTION_ARGS)
{
  // Our arguments:
  ArrayType *vals;
  ArrayType *percs;
  ArrayType *ret;

  // The array element type:
  Oid valsType;
  Oid percsType;

  // The array element type widths for our input array:
  int16 valsTypeWidth;
  int16 percsTypeWidth;
  int16 retTypeWidth;

  // The array element type "is passed by value" flags (not really used):
  bool valsTypeByValue;
  bool percsTypeByValue;
  bool retTypeByValue;

  // The array element type alignment codes (not really used):
  char valsTypeAlignmentCode;
  char percsTypeAlignmentCode;
  char retTypeAlignmentCode;

  // The array contents, as PostgreSQL "Datum" objects:
  Datum *valsContent;
  Datum *percsContent;
  Datum *retContent;

  // List of "is null" flags for the array contents (not used):
  bool *valsNullFlags;
  bool *percsNullFlags;

  // The size of the input array:
  int valsLength;
  int percsLength;

  float8 *floatVals;
  int i;
  float8 perc;
  float8 floatPos;
  float8 v = 0;

  if (PG_ARGISNULL(0) || PG_ARGISNULL(1)) {
    ereport(ERROR, (errmsg("Null arguments not accepted")));
  }

  vals = PG_GETARG_ARRAYTYPE_P(0);
  percs = PG_GETARG_ARRAYTYPE_P(1);

  if (ARR_NDIM(vals) == 0 || ARR_NDIM(percs) == 0) {
    PG_RETURN_NULL();
  }
  if (ARR_NDIM(vals) > 1 || ARR_NDIM(percs) > 1) {
    ereport(ERROR, (errmsg("One-dimesional arrays are required")));
  }

  if (array_contains_nulls(vals) || array_contains_nulls(percs)) {
    ereport(ERROR, (errmsg("Array contains null elements")));
  }

  // Determine the array element types.
  valsType = ARR_ELEMTYPE(vals);

  if (valsType != INT2OID &&
      valsType != INT4OID &&
      valsType != INT8OID &&
      valsType != FLOAT4OID &&
      valsType != FLOAT8OID) {
    ereport(ERROR, (errmsg("Percentiles subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  percsType = ARR_ELEMTYPE(percs);

  if (percsType != FLOAT8OID) {
    ereport(ERROR, (errmsg("Percentiles list must have DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];
  percsLength = (ARR_DIMS(percs))[0];

  if (percsLength == 0) {
    ereport(ERROR, (errmsg("Percentiles list must contain at least one entry")));
  }

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);
  get_typlenbyvalalign(percsType, &percsTypeWidth, &percsTypeByValue, &percsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);
  deconstruct_array(percs, percsType, percsTypeWidth, percsTypeByValue, percsTypeAlignmentCode,
&percsContent, &percsNullFlags, &percsLength);

  // Compute the percentiles:

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

  qsort(floatVals, valsLength, sizeof(float8), compare_float8);

  retContent = palloc0(sizeof(Datum) * percsLength);

  for (i = 0; i < percsLength; i++) {
    perc = DatumGetFloat8(percsContent[i]);
    if (perc < 0 || perc > 1) {
      ereport(ERROR, (errmsg("Percent must be between 0 and 1")));
    }

    floatPos = (valsLength - 1) * perc;
    v = floatVals[(int)floatPos];
    if (floorl(floatPos) != floatPos) {
      v += (floatVals[(int)floatPos + 1] - v) * (floatPos - floorl(floatPos));
    }

    retContent[i] = Float8GetDatum(v);
  }

  // Wrap the buckets in a new PostgreSQL array object.
  get_typlenbyvalalign(FLOAT8OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
  ret = construct_array(retContent, percsLength, FLOAT8OID, retTypeWidth, retTypeByValue, retTypeAlignmentCode);

  // Return the final PostgreSQL array object.
  PG_RETURN_ARRAYTYPE_P(ret);
}

