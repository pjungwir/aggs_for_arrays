SELECT array_to_hist('{}'::integer[], 1, 2, 4);
SELECT array_to_hist('{1,1,5,2,0}', 1, 2, 4);
SELECT array_to_hist('{1,1,5,2,0}'::smallint[], 1::smallint, 2::smallint, 4);
SELECT array_to_hist('{1,1,5,2,0}'::integer[], 1::integer, 2::integer, 4);
SELECT array_to_hist('{1,1,5,2,0}'::bigint[], 1::bigint, 2::bigint, 4);
SELECT array_to_hist('{1,1,5,2,0}'::real[], 1::real, 2::real, 4);
SELECT array_to_hist('{1,1,5,2,0}'::float[], 1::float, 2::float, 4);
SELECT array_to_hist('{1,1,5,2,0}'::text[], 1::text, 2::text, 4);
