/* aggs_for_arrays--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION aggs_for_arrays" to load this file. \quit

CREATE OR REPLACE FUNCTION 
array_to_hist(anyarray, anyelement, anyelement, int)
RETURNS int[]
AS 'aggs_for_arrays', 'array_to_hist'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_mean(anyarray)
RETURNS DOUBLE PRECISION
AS 'aggs_for_arrays', 'array_to_mean'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_median(anyarray)
RETURNS DOUBLE PRECISION
AS 'aggs_for_arrays', 'array_to_median'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
sorted_array_to_median(anyarray)
RETURNS DOUBLE PRECISION
AS 'aggs_for_arrays', 'sorted_array_to_median'
LANGUAGE c;

/*
CREATE OR REPLACE FUNCTION 
array_to_mode(anyarray)
RETURNS DOUBLE PRECISION
AS 'aggs_for_arrays', 'array_to_mode'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_percentile(anyarray, float)
RETURNS DOUBLE PRECISION
AS 'aggs_for_arrays', 'array_to_percentile'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_percentiles(anyarray, float[])
RETURNS DOUBLE PRECISION[]
AS 'aggs_for_arrays', 'array_to_percentiles'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_min(anyarray)
RETURNS anyelement
AS 'aggs_for_arrays', 'array_to_min'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_max(anyarray)
RETURNS anyelement
AS 'aggs_for_arrays', 'array_to_max'
LANGUAGE c;

CREATE OR REPLACE FUNCTION 
array_to_min_max(anyarray)
RETURNS anyarray
AS 'aggs_for_arrays', 'array_to_min_max'
LANGUAGE c;

*/
