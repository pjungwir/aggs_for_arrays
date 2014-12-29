aggs_for_arrays
===============

This Postgres extension provides various functions for operating on arrays,
for instance taking the histogram of an array of numbers.

These functions are useful because if you have a lot values you want to aggregate,
queries that fetch each value from a separate row can have poor performance.
Storing all the values in a single row as a Postgres array
can drastically improve query performance.
For instance, computing a 1000-bucket histogram on one million float values
stored in separate rows took 11 seconds in a simple benchmark,
compared to 30 milliseconds with the `array_to_hist` function.

Even if you store all the values together in an array column,
these functions still outperform aggregations done in SQL or plpgsql,
because the Postgres C API lets you skip a lot of the work
for interfacing at those higher levels.
For instance, the same benchmark gave 340ms for a SQL solution
and 11 seconds for a plpgsql solution.
We show further benchmark results below.


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

    * SQL on `samples`.
    * SQL on `sample_groups`.
    * PLPGSQL on `sample_groups`.
    * The `aggs_for_arrays` function on `sample_groups`.

The `sorted_array_to_*` methods use `sorted_samples` and `sorted_sample_groups` instead.

| function                 | SQL row-based | SQL array-based | PLPGSQL array-based | `aggs_for_arrays` |
|:-------------------------|--------------:|----------------:|--------------------:|------------------:|
| `array_to_hist`          |    11161.2 ms |      342.641 ms |          11422.3 ms |         30.111 ms |
| `array_to_mean`          | | | | |
| `array_to_median`        | | | | |
| `sorted_array_to_median` | | | | |
| `array_to_mode`          | | | | |
| `sorted_array_to_mode`   | | | | |
| `array_to_percentile`    | | | | |
| `array_to_percentiles`   | | | | |
| `array_to_max`           | | | | |
| `array_to_min`           | | | | |



