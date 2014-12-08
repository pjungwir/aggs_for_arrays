MODULES = aggs_for_arrays
EXTENSION = aggs_for_arrays
DATA = aggs_for_arrays--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

test:
	./test/setup.sh
	PATH="./test/bats:$$PATH" ./test/bats/bats test/array_to_hist.sh

bench:
	./bench/setup.sh
	./bench/bench-all.sh

.PHONY: test bench

