/* aggs_for_arrays--1.0.sql */

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION aggs_for_arrays" to load this file. \quit

CREATE OR REPLACE FUNCTION 
array_to_hist(double precision[], double precision, double precision, int)
RETURNS int[]
AS 'aggs_for_arrays', 'array_to_hist'
LANGUAGE c;

