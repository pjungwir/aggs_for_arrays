#!/bin/bash

set -eu

source bench/defaults.sh
export PGPASSWORD="$BENCH_PASSWORD"

psql -U "$BENCH_USER" -h "$BENCH_HOST" -p "$BENCH_PORT" "$BENCH_DATABASE" -c "SELECT 'okay'" >/dev/null 2>&1 || {
  cat <<-EOF;
Need a bench database to run benchmarks!
You can create one with these commands:
  CREATE USER $BENCH_USER WITH PASSWORD '$PGPASSWORD';
  CREATE DATABASE $BENCH_DATABASE WITH OWNER $BENCH_USER;
  GRANT ALL PRIVILEGES ON DATABASE $BENCH_DATABASE TO $BENCH_USER;
EOF
  exit 1;
};

sudo su - postgres -c "psql -d '$BENCH_DATABASE' -p '$BENCH_PORT' -c 'DROP EXTENSION IF EXISTS aggs_for_arrays'"
sudo su - postgres -c "psql -d '$BENCH_DATABASE' -p '$BENCH_PORT' -c 'CREATE EXTENSION aggs_for_arrays'"

tables=$(echo '\dt' | psql --no-psqlrc --tuples-only -U "$BENCH_USER" -h "$BENCH_HOST" -p "$BENCH_PORT" "$BENCH_DATABASE" 2>/dev/null | wc -l)
if [ "$tables" -lt 3 ]; then
  psql --no-psqlrc -U "$BENCH_USER" -h "$BENCH_HOST" -p "$BENCH_PORT" "$BENCH_DATABASE" < bench/setup.sql;
fi

