
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

  float8 v = 0;
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
    ereport(ERROR, (errmsg("Mean subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
  }

  valsLength = (ARR_DIMS(vals))[0];

  if (valsLength == 0) PG_RETURN_NULL();

  get_typlenbyvalalign(valsType, &valsTypeWidth, &valsTypeByValue, &valsTypeAlignmentCode);

  // Extract the array contents (as Datum objects).
  deconstruct_array(vals, valsType, valsTypeWidth, valsTypeByValue, valsTypeAlignmentCode,
&valsContent, &valsNullFlags, &valsLength);

  // Iterate through the contents and sum things up,
  // then return the mean:
  // Watch out for overflow:
  // http://stackoverflow.com/questions/1930454/what-is-a-good-solution-for-calculating-an-average-where-the-sum-of-all-values-e/1934266#1934266

// #if defined(__SSE2__) && defined(WITH_SIMD)
#if defined(__AVX__)
  if (__builtin_cpu_supports("avx")) {
    switch (valsType) {
      case INT2OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt16(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt32(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT8OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt64(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetFloat4(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT8OID:
        // Compute two means, and then take the mean of those.
        // If we have an odd number of elements, leave the last one until the end.
        // simd_sum = __builtin_ia32_loadlpd(simd_sum, &v);
        // TODO: Make sure to align everything!!
        iplus1 = 0;     // TODO: make this a vector too?
        __mm256d simd_val;
        __mm256d simd_sum = _mm_set1_pd(0.0);
        __mm256d simd_tmp;
        // TODO: Duff's device to get started?:
        for (i = 0; i < valsLength - valsLength % 4; i+=4) {
          // v += (DatumGetFloat8(valsContent[i]) - v) / (i + 1);
          iplus1 += 1;
          // TODO: Load val doubles at once: only works if FLOATs are by-value, so check for that.
          simd_val = _mm_load_pd(&valsContent[i]);
          simd_val = _mm_sub_pd(simd_val, simd_sum);
          simd_tmp = _mm_set_pd(iplus1);
          simd_val = _mm_div_pd(simd_val, simd_tmp);
          simd_sum = _mm_add_pd(simd_sum, simd_val);
        }
        // Now we have the mean of the odds in the low spot, and the mean of the evens in the high spot.
        // Since they are based on the same number of elements we can just take their mean.
        // Move the high half of simd_sum into the low half of simd_val,
        // so that we can do math against them.
        // So simd_sum = a + (b - a)/2
        // where a is the mean of the evens (0,2,4,...) and b is the mean of the odds (1,2,5...).
        simd_val = __builtin_ia32_unpckhpd(simd_sum, simd_val);  // simd_val input is ignored
        simd_val = __builtin_ia32_subsd(simd_val, simd_sum);
        simd_tmp = __builtin_ia32_loadlpd(simd_tmp, &two);
        simd_val = __builtin_ia32_divsd(simd_val, simd_tmp);
        simd_sum = __builtin_ia32_addsd(simd_sum, simd_val);

        if (valsLength % 2) {
          elemVal1 = DatumGetFloat8(valsContent[valsLength - 1]);
          simd_val = __builtin_ia32_loadlpd(simd_val, &elemVal1);
          simd_val = __builtin_ia32_subsd(simd_val, simd_sum);
          valsLengthDouble = valsLength;
          simd_tmp = __builtin_ia32_loadlpd(simd_tmp, &valsLengthDouble);
          simd_val = __builtin_ia32_divsd(simd_val, simd_tmp);
          simd_sum = __builtin_ia32_addsd(simd_sum, simd_val);
        }

        __builtin_ia32_storeupd(&v, simd_sum);
        break;
      default:
        ereport(ERROR, (errmsg("Mean subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
        break;
    }
  } else
#endif

#if defined(__SSE2__)
  if (__builtin_cpu_supports("sse2")) {
    /*
    double zero __attribute__((aligned(16))) = 0;
    double two __attribute__((aligned(16))) = 2;
    v2df simd_sum __attribute__((aligned(16))) = __builtin_ia32_loadupd(&zero);
    v2df simd_val __attribute__((aligned(16))) = __builtin_ia32_loadupd(&zero);
    v2df simd_tmp __attribute__((aligned(16))) = __builtin_ia32_loadupd(&zero);
    float8 elemVal1 __attribute__((aligned(16)));
    float8 elemVal2 __attribute__((aligned(16)));
    double iplus1 __attribute__((aligned(16)));
    double valsLengthDouble __attribute__((aligned(16)));
    */
    double zero = 0;
    double two = 2;
    v2df simd_sum = __builtin_ia32_loadupd(&zero);
    v2df simd_val = __builtin_ia32_loadupd(&zero);
    v2df simd_tmp = __builtin_ia32_loadupd(&zero);
    float8 elemVal1;
    float8 elemVal2;
    double iplus1;
    double valsLengthDouble;
    switch (valsType) {
      case INT2OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt16(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt32(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT8OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt64(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetFloat4(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT8OID:
        // Compute two means, and then take the mean of those.
        // If we have an odd number of elements, leave the last one until the end.
        // simd_sum = __builtin_ia32_loadlpd(simd_sum, &v);
        // TODO: Make sure to align everything!!
        iplus1 = 0;
        for (i = 0; i < valsLength - valsLength % 2; i+=2) {
          // v += (DatumGetFloat8(valsContent[i]) - v) / (i + 1);
          iplus1 += 1;
          elemVal1 = DatumGetFloat8(valsContent[i]);
          elemVal2 = DatumGetFloat8(valsContent[i+1]);
          simd_val = __builtin_ia32_loadlpd(simd_val, &elemVal1);
          simd_val = __builtin_ia32_loadhpd(simd_val, &elemVal2);
          simd_val = __builtin_ia32_subpd(simd_val, simd_sum);
          simd_tmp = __builtin_ia32_loadlpd(simd_tmp, &iplus1);
          simd_tmp = __builtin_ia32_loadhpd(simd_tmp, &iplus1);
          simd_val = __builtin_ia32_divpd(simd_val, simd_tmp);  // TODO: simd_tmp can be a &double instead I think....
          simd_sum = __builtin_ia32_addpd(simd_sum, simd_val);
        }
        // Now we have the mean of the odds in the low spot, and the mean of the evens in the high spot.
        // Since they are based on the same number of elements we can just take their mean.
        // Move the high half of simd_sum into the low half of simd_val,
        // so that we can do math against them.
        // So simd_sum = a + (b - a)/2
        // where a is the mean of the evens (0,2,4,...) and b is the mean of the odds (1,2,5...).
        simd_val = __builtin_ia32_unpckhpd(simd_sum, simd_val);  // simd_val input is ignored
        simd_val = __builtin_ia32_subsd(simd_val, simd_sum);
        simd_tmp = __builtin_ia32_loadlpd(simd_tmp, &two);
        simd_val = __builtin_ia32_divsd(simd_val, simd_tmp);
        simd_sum = __builtin_ia32_addsd(simd_sum, simd_val);

        if (valsLength % 2) {
          elemVal1 = DatumGetFloat8(valsContent[valsLength - 1]);
          simd_val = __builtin_ia32_loadlpd(simd_val, &elemVal1);
          simd_val = __builtin_ia32_subsd(simd_val, simd_sum);
          valsLengthDouble = valsLength;
          simd_tmp = __builtin_ia32_loadlpd(simd_tmp, &valsLengthDouble);
          simd_val = __builtin_ia32_divsd(simd_val, simd_tmp);
          simd_sum = __builtin_ia32_addsd(simd_sum, simd_val);
        }

        __builtin_ia32_storeupd(&v, simd_sum);
        break;
      default:
        ereport(ERROR, (errmsg("Mean subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
        break;
    }
  } else
#endif

  {
    switch (valsType) {
      case INT2OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt16(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt32(valsContent[i]) - v) / (i + 1);
        }
        break;
      case INT8OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetInt64(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT4OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetFloat4(valsContent[i]) - v) / (i + 1);
        }
        break;
      case FLOAT8OID:
        for (i = 0; i < valsLength; i++) {
          v += (DatumGetFloat8(valsContent[i]) - v) / (i + 1);
        }
        break;
      default:
        ereport(ERROR, (errmsg("Mean subject must be SMALLINT, INTEGER, BIGINT, REAL, or DOUBLE PRECISION values")));
        break;
    }
  }

  PG_RETURN_FLOAT8(v);
}

