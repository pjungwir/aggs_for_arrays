`aggs_for_arrays`
=================

This Postgres extension provides various functions for operating on arrays,
for instance taking the histogram of an array of numbers.

These functions are useful because if you have a lot values you want to aggregate,
queries that fetch each value from a separate row can have poor performance.
Storing all the values in a single row as a Postgres array
can drastically improve query performance.
For instance, computing a 1000-bucket histogram on one million float values
stored in separate rows took 12 seconds in a simple benchmark,
compared to 27 milliseconds with the `array_to_hist` function.

Using arrays in this way is a bit like a poor-man's column-store database:
it lets you keep all the values for one attribute in one place.
(It's also a bit like how in R and Pandas you often see parallel arrays rather than arrays of objects.)
To simplify a little, imagine pulling one million floats off disk in a single 8MB chunk
instead of asking the drive for one million separate reads.
I wouldn't use this pattern if your arrays get updated a lot,
lest you take a hit on writes (At least test first!),
but if they are pretty stable then using arrays can greatly speed up reads.

With such an approach you could still use SQL or PLPGSQL,
but these functions outperform such code,
because the Postgres C API lets you skip a lot of the work
for interfacing at those higher levels.
For instance, the same benchmark gave 398ms for a SQL solution
and 12 seconds for a plpgsql solution.
We show further benchmark results below.

Note that despite the name, these functions are not true aggregate functions
(summarizing multiple rows).
Rather they do aggregate-like calculations on a single input array.
If you want actual aggregates that take multiple input arrays,
then you might be looking for my other extension, [`aggs_for_vecs`](https://github.com/pjungwir/aggs_for_vecs).
If this extension takes a column-store approach to your data, that one takes a row-store approach.

Installing
----------

This package installs like any Postgres extension. First say:

    make && sudo make install

You will need to have `pg_config` in your path,
but normally that is already the case.
You can check with `which pg_config`.

Then in the database of your choice say:

    CREATE EXTENSION aggs_for_arrays;


Functions
---------

The available functions are described below.
In general, these functions accept arrays of any integer or floating-point type,
namely `SMALLINT`, `INTEGER`, `BIGINT`, `REAL`, or `DOUBLE PRECISION` (aka `FLOAT`).
The return value will either be the same type (e.g. for a minimum),
a FLOAT (e.g. for a mean),
or an `INTEGER` type (e.g. for histogram bucket counts).
If a function can take any numeric type,
its types are shown as `T`.

#### `INTEGER[] array_to_hist(values T[], bucket_start T, bucket_width T, bucket_count INTEGER)`

Returns the bucket count based on the values and bucket characteristics you request.

#### `INTEGER[] array_to_hist_2d(x_values T[], y_values T[], x_bucket_start T, y_bucket_start T, x_bucket_width T, y_bucket_width T, x_bucket_count INTEGER, y_bucket_count INTEGER)`

Returns the bucket count as a 2-D array based on the values and bucket characteristics you request.
The data arrays `x_values` and `y_values` must be the same length.
We compare each array's first element and plot it, then their second element, etc.
If either `x_values` or `y_values` is `NULL`, the whole result is `NULL`. If either contains a `NULL`, then that position isn't plotted.

#### `FLOAT array_to_mean(values T[])`

Returns the mean of all the values in the array.

#### `FLOAT array_to_median(values T[])`

Returns the median.
Does not require a pre-sorted input.
If there are an even number of values,
returns the mean of the two middle values.

#### `FLOAT sorted_array_to_median(values T[])`

Just like `array_to_median`, but assumes `values` is already sorted.

#### `FLOAT array_to_mode(values T[])`

Returns the mode.
Does not require a pre-sorted input.
If there are several values tied for most common,
returns their mean.

#### `FLOAT sorted_array_to_mode(values T[])`

Just like `array_to_mode`, but assumes `values` is already sorted.

#### `FLOAT array_to_percentile(values T[], percentile FLOAT)`

Returns the percentile you request,
where `percentile` is a number from 0 to 1 inclusive.
Asking for 0 will always give the minimum,
1 for maximum, and 0.5 the median.
If you ask for a percentile that lands between two data points,
we return a linear interpolation between them.

#### `FLOAT sorted_array_to_percentile(values T[], percentile FLOAT)`

Just like `array_to_percentile`, but assumes `values` is already sorted.

#### `FLOAT[] array_to_percentiles(values T[], percentiles FLOAT[])`

Just like `array_to_percentile`,
but you can pass several percentiles
and get the result for each in a single call.

#### `FLOAT[] sorted_array_to_percentiles(values T[], percentiles FLOAT[])`

Just like `array_to_percentiles`, but assumes `values` is already sorted.

#### `T array_to_max(values T[])`

Returns the greatest value in the array.

#### `T array_to_min(values T[])`

Returns the least value in the array.

#### `T[] array_to_min_max(values T[])`

Returns a tuple with the min in position 1 and the max in position 2.

#### `FLOAT array_to_skewness(values T[])`

Computes the [skewness](http://www.itl.nist.gov/div898/handbook/eda/section3/eda35b.htm)
of the given values.

#### `FLOAT array_to_kurtosis(values T[])`

Computes the [kurtosis](http://www.itl.nist.gov/div898/handbook/eda/section3/eda35b.htm)
of the given values.


Benchmarks
----------

Assume you have two tables:

    CREATE TABLE samples (
      id INTEGER PRIMARY KEY,
      measurement_id INTEGER NOT NULL,
      value FLOAT NOT NULL
    );

    CREATE TABLE sample_groups {
      id INTEGER PRIMARY KEY,
      measurement_id INTEGER NOT NULL,
      values FLOAT[] NOT NULL
    };

These tables store the same information,
but `samples` stores each sample in a separate row,
and `sample_groups` stores a whole group in just one row.

You can run `bench.sh` to test the performance of various approaches:

- SQL on `samples`.
- SQL on `sample_groups`.
- PLPGSQL on `sample_groups`.
- The `aggs_for_arrays` function on `sample_groups`.

The `sorted_array_to_*` methods use `sorted_samples` and `sorted_sample_groups` instead.

| function                      | SQL row-based | SQL array-based | PLPGSQL array-based | `aggs_for_arrays` |
|:------------------------------|--------------:|----------------:|--------------------:|------------------:|
| `array_to_hist`               |    12218.1 ms |      398.235 ms |        12310.800 ms |         26.936 ms |
| `array_to_mean`               |    10630.0 ms |      121.677 ms |          390.983 ms |         25.226 ms |
| `array_to_median`             |    33587.0 ms |     1163.070 ms |         1258.160 ms |         47.996 ms |
| `sorted_array_to_median`      |    23239.5 ms |       30.107 ms |           41.225 ms |         14.835 ms |
| `array_to_mode`               |    13724.1 ms |     1505.310 ms |         1552.610 ms |        201.943 ms |
| `sorted_array_to_mode`        |    13195.2 ms |     1474.130 ms |         1577.770 ms |         45.171 ms |
| `array_to_percentile`         |    24218.2 ms |     2591.240 ms |         1698.570 ms |        179.916 ms |
| `sorted_array_to_percentile`  |    24305.5 ms |     2102.520 ms |         1204.140 ms |         21.947 ms |
| `array_to_percentiles`        |    32367.0 ms |    10735.300 ms |         3608.800 ms |        188.752 ms |
| `sorted_array_to_percentiles` |    32294.3 ms |    10153.300 ms |         3120.830 ms |         22.227 ms |
| `array_to_max`                |    10613.2 ms |      115.094 ms |          398.791 ms |         17.321 ms |
| `array_to_min`                |    10600.5 ms |      113.859 ms |          400.926 ms |         17.204 ms |
| `array_to_min_max`            |    10727.9 ms |      169.226 ms |          824.539 ms |         23.922 ms |
| `array_to_skewness`           |    22267.2 ms |      802.463 ms |         1077.630 ms |        120.925 ms |
| `array_to_kurtosis`           |    22253.1 ms |      806.296 ms |         1075.960 ms |        112.210 ms |



Development
-----------

These tests follow the [PGXS and `pg_regress` framework](https://www.postgresql.org/docs/current/extend-pgxs.html) used for Postgres extensions, including Postgres's own contrib package. To run the tests, first install the extension somewhere then say `make installcheck`. You can use standard libpq envvars to control the database connection, e.g. `PGPORT=5436 make installcheck`.
