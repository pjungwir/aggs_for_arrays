MODULES = aggs_for_arrays
EXTENSION = aggs_for_arrays
EXTENSION_VERSION = 1.3.3
DATA = $(EXTENSION)--$(EXTENSION_VERSION).sql

REGRESS = setup \
					array_to_count \
					array_to_hist \
					array_to_hist_2d \
					array_to_kurtosis \
					array_to_max \
					array_to_mean \
					array_to_median \
					array_to_min \
					array_to_min_max \
					array_to_mode \
					array_to_percentile \
					array_to_percentiles \
					array_to_skewness \
					sorted_array_to_median \
					sorted_array_to_mode \
					sorted_array_to_percentile \
					sorted_array_to_percentiles

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
REGRESS_OPTS = --dbname=$(EXTENSION)_regression	# This must come *after* the include since we override the build-in --dbname.

test:
	echo "Run make installcheck to run tests"
	exit 1

bench:
	./bench/setup.sh
	./bench/bench-all.sh | tee bench-results.txt

bench_results.txt: bench

bench-report.txt: bench_results.txt
	./bench/format-table.rb < bench-results.txt | tee bench-report.txt

release:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTENSION_VERSION)/ --output $(EXTENSION)-$(EXTENSION_VERSION).zip master

.PHONY: test bench release

