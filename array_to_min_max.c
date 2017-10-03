
Datum array_to_min_max(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_min_max);

/**
 * Returns a min and max from an (unsorted) array of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_min_max(PG_FUNCTION_ARGS)
{
  // Our arguments:
  ArrayType *vals;

  // The array element type:
  Oid valsType;

  // The array element type widths for our input array:
  int16 valsTypeWidth;
  int16 retTypeWidth;

  // The array element type "is passed by value" flags:
  bool valsTypeByValue;
  bool retTypeByValue;

  // The array element type alignment codes:
  char valsTypeAlignmentCode;
  char retTypeAlignmentCode;

  // The array contents, as PostgreSQL "Datum" objects:
  Datum *valsContent;
  Datum retContent[2];
  bool retNulls[2] = {true, true};

  // List of "is null" flags for the array contents:
  bool *valsNullFlags;

  // The size of the input array:
  int valsLength;

  // The output array:
  ArrayType* retArray;

  bool resultIsNull = true;
  int i;
  pgnum minV, maxV;
  int dims[1];
  int lbs[1];     // Lower Bounds of each dimension

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

  // Determine the array element types.
  valsType = ARR_ELEMTYPE(vals);

  if (valsType != INT2OID &&
      valsType != INT4OID &&
      valsType != INT8OID &&
      valsType != FLOAT4OID &&
      valsType != FLOAT8OID) {
    ereport(ERROR, (errmsg("Minmax subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  if (valsLength == 0) PG_RETURN_NULL();

  // Compute the max.

  switch (valsType) {
    case INT2OID:
      for (i = 0; i < valsLength; i++) {
        if (valsNullFlags[i]) {
          continue;
        } else if (resultIsNull) {
          minV.i16 = DatumGetInt16(valsContent[0]);
          maxV.i16 = DatumGetInt16(valsContent[0]);
          resultIsNull = false;
        } else {
          if (DatumGetInt16(valsContent[i]) < minV.i16) minV.i16 = DatumGetInt16(valsContent[i]);
          if (DatumGetInt16(valsContent[i]) > maxV.i16) maxV.i16 = DatumGetInt16(valsContent[i]);
        }
      }
      retContent[0] = Int16GetDatum(minV.i16);
      retContent[1] = Int16GetDatum(maxV.i16);
      get_typlenbyvalalign(INT2OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
      break;
    case INT4OID:
      for (i = 0; i < valsLength; i++) {
        if (valsNullFlags[i]) {
          continue;
        } else if (resultIsNull) {
          minV.i32 = DatumGetInt32(valsContent[0]);
          maxV.i32 = DatumGetInt32(valsContent[0]);
          resultIsNull = false;
        } else {
          if (DatumGetInt32(valsContent[i]) < minV.i32) minV.i32 = DatumGetInt32(valsContent[i]);
          if (DatumGetInt32(valsContent[i]) > maxV.i32) maxV.i32 = DatumGetInt32(valsContent[i]);
        }
      }
      retContent[0] = Int32GetDatum(minV.i32);
      retContent[1] = Int32GetDatum(maxV.i32);
      get_typlenbyvalalign(INT4OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
      break;
    case INT8OID:
      for (i = 0; i < valsLength; i++) {
        if (valsNullFlags[i]) {
          continue;
        } else if (resultIsNull) {
          minV.i64 = DatumGetInt64(valsContent[0]);
          maxV.i64 = DatumGetInt64(valsContent[0]);
          resultIsNull = false;
        } else {
          if (DatumGetInt64(valsContent[i]) < minV.i64) minV.i64 = DatumGetInt64(valsContent[i]);
          if (DatumGetInt64(valsContent[i]) > maxV.i64) maxV.i64 = DatumGetInt64(valsContent[i]);
        }
      }
      retContent[0] = Int64GetDatum(minV.i64);
      retContent[1] = Int64GetDatum(maxV.i64);
      get_typlenbyvalalign(INT8OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
      break;
    case FLOAT4OID:
      for (i = 0; i < valsLength; i++) {
        if (valsNullFlags[i]) {
          continue;
        } else if (resultIsNull) {
          minV.f4 = DatumGetFloat4(valsContent[0]);
          maxV.f4 = DatumGetFloat4(valsContent[0]);
          resultIsNull = false;
        } else {
          if (DatumGetFloat4(valsContent[i]) < minV.f4) minV.f4 = DatumGetFloat4(valsContent[i]);
          if (DatumGetFloat4(valsContent[i]) > maxV.f4) maxV.f4 = DatumGetFloat4(valsContent[i]);
        }
      }
      retContent[0] = Float4GetDatum(minV.f4);
      retContent[1] = Float4GetDatum(maxV.f4);
      get_typlenbyvalalign(FLOAT4OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
      break;
    case FLOAT8OID:
      for (i = 0; i < valsLength; i++) {
        if (valsNullFlags[i]) {
          continue;
        } else if (resultIsNull) {
          minV.f8 = DatumGetFloat8(valsContent[0]);
          maxV.f8 = DatumGetFloat8(valsContent[0]);
          resultIsNull = false;
        } else {
          if (DatumGetFloat8(valsContent[i]) < minV.f8) minV.f8 = DatumGetFloat8(valsContent[i]);
          if (DatumGetFloat8(valsContent[i]) > maxV.f8) maxV.f8 = DatumGetFloat8(valsContent[i]);
        }
      }
      retContent[0] = Float8GetDatum(minV.f8);
      retContent[1] = Float8GetDatum(maxV.f8);
      get_typlenbyvalalign(FLOAT8OID, &retTypeWidth, &retTypeByValue, &retTypeAlignmentCode);
      break;
    default:
      ereport(ERROR, (errmsg("Minmax subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  lbs[0] = 1;
  dims[0] = 2;
  if (!resultIsNull) {
    retNulls[0] = false;
    retNulls[1] = false;
  }
  retArray = construct_md_array(retContent, retNulls, 1, dims, lbs, valsType, retTypeWidth, retTypeByValue, retTypeAlignmentCode);

  PG_RETURN_ARRAYTYPE_P(retArray);
}

