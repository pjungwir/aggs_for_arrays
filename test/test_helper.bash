
source test/defaults.sh
export PGPASSWORD="$TESTING_PASSWORD"

function query() {
  echo $1 | psql --no-psqlrc --tuples-only -U "$TESTING_USER" -h "$TESTING_HOST" -p "$TESTING_PORT" "$TESTING_DATABASE" | sed 's/^ *//'
}

