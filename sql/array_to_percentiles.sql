SELECT array_to_percentiles('{}'::float[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::smallint[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::integer[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::bigint[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::real[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::text[], '{0.2,0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0,0.2}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.2,1}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{0.5}'::float[]);
SELECT array_to_percentiles('{1,2,5,3,0}'::float[], '{0.5}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{-0.2,-0.4}'::float[]);
SELECT array_to_percentiles('{1,1,5,2,0,7}'::float[], '{1.2}'::float[]);
