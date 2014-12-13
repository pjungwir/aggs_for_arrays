
/*
 *  This Quickselect routine is based on the algorithm described in
 *  "Numerical recipes in C", Second Edition,
 *  Cambridge University Press, 1992, Section 8.5, ISBN 0-521-43108-5
 *  This code adapted from Public domain code by Nicolas Devillard - 1998 from here:
 *  http://ndevilla.free.fr/median/median/index.html
 */

#define ELEM_SWAP(a,b) { register float8 t=(a);(a)=(b);(b)=t; }

float8 select_kth_value(float8 *arr, int n, int k);

float8 select_kth_value(float8 *arr, int n, int k) {
  int low, high;
  int middle, ll, hh;

  low = 0;
  high = n-1;

  for (;;) {
    // One element only
    if (high <= low) return arr[k];

    // Two elements only
    if (high == low + 1) {
      if (arr[low] > arr[high]) ELEM_SWAP(arr[low], arr[high]);
      return arr[k];
    }

    // Find median of low, middle and high items; swap into position low
    middle = (low + high) / 2;
    if (arr[middle] > arr[high])    ELEM_SWAP(arr[middle], arr[high]) ;
    if (arr[low] > arr[high])       ELEM_SWAP(arr[low], arr[high]) ;
    if (arr[middle] > arr[low])     ELEM_SWAP(arr[middle], arr[low]) ;

    // Swap low item (now in position middle) into position (low+1)
    ELEM_SWAP(arr[middle], arr[low+1]) ;

    // Nibble from each end towards middle, swapping items when stuck
    ll = low + 1;
    hh = high;
    for (;;) {
      do ll++; while (arr[low] > arr[ll]);
      do hh--; while (arr[hh]  > arr[low]);

      if (hh < ll) break;

      ELEM_SWAP(arr[ll], arr[hh]);
    }

    // Swap middle item (in position low) back into correct position
    ELEM_SWAP(arr[low], arr[hh]);

    // Re-set active partition
    if (hh <= k) low = ll;
    if (hh >= k) high = hh - 1;
  }
}

#undef ELEM_SWAP



typedef struct {
  float8 value;
  int count;
} valcount;
 
int compare_float8(const void *a, const void *b);
int compare_valcount(const void *a, const void *b);

int compare_float8(const void *a, const void *b) {
  float8 x = *(const float8*)a - *(const float8*)b;
  return x < 0 ? -1 : x > 0;
}
 
int compare_valcount(const void *a, const void *b) {
  return ((const valcount*)b)->count - ((const valcount*)a)->count;
}

