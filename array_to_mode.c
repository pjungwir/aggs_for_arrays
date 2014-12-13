
Datum array_to_mode(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_mode);

/**
 * Returns a mode from an (unsorted) array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_mode(PG_FUNCTION_ARGS)
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
  int i, j;
  valcount *counts;
  float8 v;

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
    ereport(ERROR, (errmsg("Mode subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  if (valsLength == 0) PG_RETURN_NULL();

  // Compute the mode.

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
      ereport(ERROR, (errmsg("Mode subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
      break;
  }

  qsort(floatVals, valsLength, sizeof(float8), compare_float8);

  // Count how many distinct values there are:
  for (i = 0, j = 1; i < valsLength - 1; i++, j += (floatVals[i] != floatVals[i + 1]));

  counts = palloc0(sizeof(valcount) * j);
  counts[0].value = floatVals[0];
  counts[0].count = 1;

  // Generate counts for each distinct value:
  for (i = j = 0; i < valsLength - 1; i++, counts[j].count++) {
    if (floatVals[i] != floatVals[i + 1]) counts[++j].value = floatVals[i + 1];
  }

  qsort(counts, j + 1, sizeof(valcount), compare_valcount);

  for (i = 0; i <= j && counts[i].count == counts[0].count; i++);

  // Now i has the number of the winners.
  // Average all the winners:

  v = counts[0].value;
  for (j = 1; j < i; j++) {
    v += (counts[j].value - v) / (j + 1);
  }

  PG_RETURN_FLOAT8(v);
}

