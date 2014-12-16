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
In general, these functions accept arrays of any numeric type.
The return value will either be the same type (e.g. for a mean)
or an `integer` type (e.g. for histogram bucket counts).
If a function can take any numeric type,
its types are shown as `T`.

`integer[] array_to_hist(values T[], bucket_start T, bucket_width T, bucket_count integer)`

`float array_to_mean(values T[])`

`float array_to_median(values T[])`

`float sorted_array_to_median(values T[])`

`float array_to_mode(values T[])`

`float sorted_array_to_mode(values T[])`

`float array_to_percentile(values T[], percentile float)`

`float[] array_to_percentiles(values T[], percentiles float[])`

`T array_to_max(values T[])`

`T array_to_min(values T[])`

`T[] array_to_min_max(values T[])`

## array_to_hist
## array_to_mean
## array_to_median
## sorted_array_to_median
## array_to_mode
## sorted_array_to_mode
## array_to_percentile
## array_to_percentiles
## array_to_max
## array_to_min
## array_to_min_max




Benchmarks
----------

Assume you have two tables:

    CREATE TABLE measurements (
      id INTEGER PRIMARY KEY,
      group_id INTEGER NOT NULL,
      value FLOAT NOT NULL
    );

    CREATE TABLE measurement_groups {
      id INTEGER PRIMARY KEY,
      values FLOAT[] NOT NULL
    };

These tables store the same information,
but `measurements` stores each measurement in a separate row,
and `measurement_groups stores a whole group in just one row.

You can run `bench.sh` to test the performance of various approaches:

    * SQL on `measurements`.
    * SQL on `measurement_groups`.
    * PLPGSQL on `measurement_groups`.
    * The `aggs_for_arrays` function on `measurement_groups`.

| function               | SQL row-based | SQL array-based | PLPGSQL array-based | `aggs_for_arrays` |
|------------------------|---------------|-----------------|---------------------|-------------------|
| `array_to_hist`        |    11161.2 ms |      342.641 ms |          11422.3 ms |         30.111 ms |
| `array_to_mean`        | | | | |
| `array_to_median`      | | | | |
| `array_to_mode`        | | | | |
| `array_to_percentile`  | | | | |
| `array_to_percentiles` | | | | |
| `array_to_max`         | | | | |
| `array_to_min`         | | | | |


