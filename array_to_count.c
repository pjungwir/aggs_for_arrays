
Datum array_to_count(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_count);

/**
 * Returns a count from an array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_count(PG_FUNCTION_ARGS)
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

  // List of "is null" flags for the array contents:
  bool *valsNullFlags;

  // I'd prefer int64 here but deconstruct_array wants a plain int.
  int valsLength;
  int valsCount = 0; 

  int i;

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

  valsType = ARR_ELEMTYPE(vals);
  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  // It's kind of a shame we even need to fill valsContent,
  // but if we pass a NULL it crashes:
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
      &valsContent, &valsNullFlags, &valsLength);

  // Compute the count.

  for (i = 0; i < valsLength; i++) {
    if (!valsNullFlags[i]) valsCount++;
  }

  PG_RETURN_INT64(valsCount);

}

