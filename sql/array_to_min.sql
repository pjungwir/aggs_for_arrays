SELECT array_to_min('{}'::float[]);
SELECT array_to_min('{1,1,5,2,0}'::smallint[]);
SELECT array_to_min('{1,1,5,2,0}'::integer[]);
SELECT array_to_min('{1,1,5,2,0}'::bigint[]);
SELECT array_to_min('{1,1,5,2,0}'::real[]);
SELECT array_to_min('{1,1,5,2,0}'::float[]);
SELECT array_to_min('{1,1,5,2,0}'::text[]);
SELECT array_to_min('{NULL}'::float[]);
SELECT array_to_min('{1,1,NULL,2,0}'::float[]);
SELECT array_to_min('{NULL,1,1,2}'::float[]);
SELECT array_to_min('{1,1,2,NULL}'::float[]);
