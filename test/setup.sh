#!/bin/bash

set -eu

source test/defaults.sh
export PGPASSWORD="$TESTING_PASSWORD"

psql -U "$TESTING_USER" -h "$TESTING_HOST" -p "$TESTING_PORT" "$TESTING_DATABASE" -c "SELECT 'okay'" >/dev/null 2>&1 || {
  cat <<-EOF;
Need a test database to run tests!
You can create one with these commands:
  CREATE USER $TESTING_USER WITH PASSWORD '$PGPASSWORD';
  CREATE DATABASE $TESTING_DATABASE WITH OWNER $TESTING_USER;
  GRANT ALL PRIVILEGES ON DATABASE $TESTING_DATABASE TO $TESTING_USER;
EOF
  exit 1;
};

sudo su - postgres -c "psql -d '$TESTING_DATABASE' -p '$TESTING_PORT' -c 'DROP EXTENSION IF EXISTS aggs_for_arrays'"
sudo su - postgres -c "psql -d '$TESTING_DATABASE' -p '$TESTING_PORT' -c 'CREATE EXTENSION aggs_for_arrays'"

psql --no-psqlrc -U "$TESTING_USER" -h "$TESTING_HOST" -p "$TESTING_PORT" "$TESTING_DATABASE" < test/setup.sql;

