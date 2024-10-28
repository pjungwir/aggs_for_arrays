CREATE EXTENSION aggs_for_arrays;

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
FROM    generate_series(1, 100) AS s(a);

INSERT INTO sample_groups
(measurement_id, values_f4, values_f8)
SELECT  m.id,
        (SELECT array_agg(random() * 2000 - 1000) FROM generate_series(1, 100)),
        (SELECT array_agg(random() * 2000 - 1000) FROM generate_series(1, 100))
FROM    measurements m;

CREATE INDEX idx_samples_measurements_id ON samples (measurement_id);
CREATE INDEX idx_sample_groups_measurement_id ON sample_groups (measurement_id);
