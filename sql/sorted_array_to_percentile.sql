SELECT sorted_array_to_percentile('{}'::float[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::smallint[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::integer[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::bigint[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::real[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::text[], 0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], 0);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], 1);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], 0.5);
SELECT sorted_array_to_percentile('{0,1,2,3,5}'::float[], 0.5);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], -0.2);
SELECT sorted_array_to_percentile('{0,1,1,2,5,7}'::float[], 1.2);
