MODULES = aggs_for_arrays
EXTENSION = aggs_for_arrays
DATA = aggs_for_arrays--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

test:
	./test/setup.sh
	# PATH="./test/bats:$$PATH" bats test/array_to_hist.bats test/array_to_mean.bats
	PATH="./test/bats:$$PATH" bats test

bench:
	./bench/setup.sh
	./bench/bench-all.sh | tee bench-results.txt

bench_results.txt: bench

bench_report: bench_results.txt
	./bench/format-table.rb < bench-results.txt

.PHONY: test bench bench_report

