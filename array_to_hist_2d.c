
Datum array_to_hist_2d(PG_FUNCTION_ARGS);
PG_FUNCTION_INFO_V1(array_to_hist_2d);

/**
 * Returns a 2-D histogram from two arrays of numbers.
 * by Paul A. Jungwirth
 */
Datum
array_to_hist_2d(PG_FUNCTION_ARGS)
{
  ArrayType *xVals, *yVals, *histVals;
  pgnum xStart, yStart;
  pgnum xBucketWidth, yBucketWidth;
  int32 xBucketCount, yBucketCount;
  int xLength, yLength;
  double xPos, yPos;
  int pos;
  int arrayLength;
  Oid elemTypeId;
  int16 valsTypeWidth, histTypeWidth;
  bool valsTypeByValue, histTypeByValue;
  char valsTypeAlignmentCode, histTypeAlignmentCode;
  Datum *xValsContent, *yValsContent, *histContent;
  bool *xNulls, *yNulls, *histNulls;
  int i;
  int dims[2];
  int lbs[2];     // Lower Bounds of each dimension

  if (PG_ARGISNULL(0) || PG_ARGISNULL(1)) PG_RETURN_NULL();

  xVals = PG_GETARG_ARRAYTYPE_P(0);
  yVals = PG_GETARG_ARRAYTYPE_P(1);

  if (ARR_NDIM(xVals) > 1 || ARR_NDIM(yVals) > 1) {
    ereport(ERROR, (errmsg("One-dimesional arrays are required")));
  }

  // Determine the array element types.
  elemTypeId = ARR_ELEMTYPE(xVals);

  if (elemTypeId != INT2OID &&
      elemTypeId != INT4OID &&
      elemTypeId != INT8OID &&
      elemTypeId != FLOAT4OID &&
      elemTypeId != FLOAT8OID) {
    ereport(ERROR, (errmsg("Histogram subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  switch (elemTypeId) {
    case INT2OID:
      xStart.i16 = PG_GETARG_INT16(2);
      yStart.i16 = PG_GETARG_INT16(3);
      xBucketWidth.i16 = PG_GETARG_INT16(4);
      yBucketWidth.i16 = PG_GETARG_INT16(5);
      break;
    case INT4OID:
      xStart.i32 = PG_GETARG_INT32(2);
      yStart.i32 = PG_GETARG_INT32(3);
      xBucketWidth.i32 = PG_GETARG_INT32(4);
      yBucketWidth.i32 = PG_GETARG_INT32(5);
      break;
    case INT8OID:
      xStart.i64 = PG_GETARG_INT64(2);
      yStart.i64 = PG_GETARG_INT64(3);
      xBucketWidth.i64 = PG_GETARG_INT64(4);
      yBucketWidth.i64 = PG_GETARG_INT64(5);
      break;
    case FLOAT4OID:
      xStart.f4 = PG_GETARG_FLOAT4(2);
      yStart.f4 = PG_GETARG_FLOAT4(3);
      xBucketWidth.f4 = PG_GETARG_FLOAT4(4);
      yBucketWidth.f4 = PG_GETARG_FLOAT4(5);
      break;
    case FLOAT8OID:
      xStart.f8 = PG_GETARG_FLOAT8(2);
      yStart.f8 = PG_GETARG_FLOAT8(3);
      xBucketWidth.f8 = PG_GETARG_FLOAT8(4);
      yBucketWidth.f8 = PG_GETARG_FLOAT8(5);
      break;
    default:
      break;
  }
  xBucketCount = PG_GETARG_INT32(6);
  yBucketCount = PG_GETARG_INT32(7);

  get_typlenbyvalalign(elemTypeId, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  deconstruct_array(xVals, elemTypeId, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode, &xValsContent, &xNulls, &xLength); 
  deconstruct_array(yVals, elemTypeId, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode, &yValsContent, &yNulls, &yLength); 

  if (xLength != yLength) {
    ereport(ERROR, (errmsg("Histogram input arrays must be of equal length.")));
  }

  // Create a new 2-D array of histogram bins (as Datum objects).
  // Memory we palloc is freed automatically at the end of the transaction.
  arrayLength = xBucketCount * yBucketCount;
  histContent = palloc0(sizeof(Datum) * arrayLength);
  histNulls = palloc0(sizeof(bool) * arrayLength);

  // Generate the histogram
  for (i = 0; i < xLength; i++) {
    if (xNulls[i] || yNulls[i]) continue;
    switch (elemTypeId) {
      case INT2OID:
        xPos = (double)(DatumGetInt16(xValsContent[i]) - xStart.i16) / xBucketWidth.i16;
        yPos = (double)(DatumGetInt16(yValsContent[i]) - yStart.i16) / yBucketWidth.i16;
        break;
      case INT4OID:
        xPos = (double)(DatumGetInt32(xValsContent[i]) - xStart.i32) / xBucketWidth.i32;
        yPos = (double)(DatumGetInt32(yValsContent[i]) - yStart.i32) / yBucketWidth.i32;
        break;
      case INT8OID:
        xPos = (double)(DatumGetInt64(xValsContent[i]) - xStart.i64) / xBucketWidth.i64;
        yPos = (double)(DatumGetInt64(yValsContent[i]) - yStart.i64) / yBucketWidth.i64;
        break;
      case FLOAT4OID:
        xPos = (double)(DatumGetFloat4(xValsContent[i]) - xStart.f4) / xBucketWidth.f4;
        yPos = (double)(DatumGetFloat4(yValsContent[i]) - yStart.f4) / yBucketWidth.f4;
        break;
      case FLOAT8OID:
        xPos = (double)(DatumGetFloat8(xValsContent[i]) - xStart.f8) / xBucketWidth.f8;
        yPos = (double)(DatumGetFloat8(yValsContent[i]) - yStart.f8) / yBucketWidth.f8;
        break;
    }

    if (xPos >= 0 && xPos < xBucketCount && yPos >= 0 && yPos < yBucketCount) {
      pos = (int)yPos * xBucketCount + (int)xPos;
      // TODO: Any faster to keep everything as straight int32s until we're done?
      // I think these macros are practically noops for Int32, right?
      histContent[pos] = Int32GetDatum(1 + DatumGetInt32(histContent[pos]));
    }
  }

  // Wrap the buckets in a new PostgreSQL array object.
  lbs[0] = 1;
  lbs[1] = 1;
  dims[0] = xBucketCount;
  dims[1] = yBucketCount;
  get_typlenbyvalalign(INT4OID, &histTypeWidth, &histTypeByValue, &histTypeAlignmentCode);
  histVals = construct_md_array(histContent, histNulls, 2, dims, lbs, INT4OID, histTypeWidth, histTypeByValue, histTypeAlignmentCode);
  PG_RETURN_ARRAYTYPE_P(histVals);
}

