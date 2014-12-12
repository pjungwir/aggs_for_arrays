BEGIN; 

DROP INDEX IF EXISTS idx_measurements_id;
DROP INDEX IF EXISTS idx_samples_id;
DROP INDEX IF EXISTS idx_samples_measurement_id;
DROP INDEX IF EXISTS idx_sample_groups_id;
DROP INDEX IF EXISTS idx_sample_groups_measurement_id;
DROP TABLE IF EXISTS samples;
DROP TABLE IF EXISTS sample_groups;
DROP TABLE IF EXISTS measurements;
DROP SEQUENCE IF EXISTS seq_measurements_id;
DROP SEQUENCE IF EXISTS seq_samples_id;
DROP SEQUENCE IF EXISTS seq_sample_groups_id;

CREATE SEQUENCE seq_measurements_id;
CREATE TABLE measurements (
id INTEGER PRIMARY KEY DEFAULT nextval('seq_measurements_id'),
  name TEXT NOT NULL
);

CREATE SEQUENCE seq_samples_id;
CREATE TABLE samples (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_samples_id'),
  measurement_id INTEGER NOT NULL,
  value_f4 FLOAT NOT NULL,
  value_f8 DOUBLE PRECISION NOT NULL
);

CREATE SEQUENCE seq_sample_groups_id;
CREATE TABLE sample_groups (
  id INTEGER PRIMARY KEY DEFAULT nextval('seq_sample_groups_id'),
  measurement_id INTEGER NOT NULL,
  values_f4 FLOAT[] NOT NULL,
  values_f8 DOUBLE PRECISION[] NOT NULL
);

INSERT INTO measurements
(name)
SELECT  a::text
FROM    generate_series(1, 100) AS s(a)
;

INSERT INTO samples
(measurement_id, value_f4, value_f8)
SELECT  m.id,
        random() * 2000 - 1000,
        random() * 2000 - 1000
FROM    measurements m
CROSS JOIN generate_series(1, 100)
;

INSERT INTO sample_groups
(measurement_id, values_f4, values_f8)
SELECT  m.id,
        (SELECT array_agg(random() * 2000 - 1000) FROM generate_series(1, 100)),
        (SELECT array_agg(random() * 2000 - 1000) FROM generate_series(1, 100))
FROM    measurements m
;

CREATE INDEX idx_measurements_id ON measurements (id);
CREATE INDEX idx_samples_id ON samples (id);
CREATE INDEX idx_samples_measurement_id ON samples (measurement_id);
CREATE INDEX idx_sample_groups_id ON sample_groups (id);
CREATE INDEX idx_sample_groups_measurement_id ON sample_groups (measurement_id);

COMMIT;

