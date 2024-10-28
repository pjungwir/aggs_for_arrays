SELECT array_to_skewness('{}'::float[]);
SELECT array_to_skewness('{1,1,5,2,0}'::smallint[]);
SELECT array_to_skewness('{1,1,5,2,0}'::integer[]);
SELECT array_to_skewness('{1,1,5,2,0}'::bigint[]);
SELECT array_to_skewness('{1,1,5,2,0}'::real[]);
SELECT array_to_skewness('{1,1,5,2,0}'::float[]);
SELECT array_to_skewness('{1,1,5,2,0}'::text[]);
