SELECT array_to_count('{}'::float[]);
SELECT array_to_count('{1,1,5,2,0}'::smallint[]);
SELECT array_to_count('{1,1,5,2,0}'::integer[]);
SELECT array_to_count('{1,1,5,2,0}'::bigint[]);
SELECT array_to_count('{1,1,5,2,0}'::real[]);
SELECT array_to_count('{1,1,5,2,0}'::float[]);
SELECT array_to_count('{NULL}'::float[]);
SELECT array_to_count('{1,1,NULL,2,0}'::float[]);
SELECT array_to_count('{1,1,5,2,0}'::text[]);

