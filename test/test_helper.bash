
source test/defaults.sh
export PGPASSWORD="$TESTING_PASSWORD"

function query() {
  (echo "\\pset null 'NULL'"; echo $1) | psql --no-psqlrc --tuples-only -U "$TESTING_USER" -h "$TESTING_HOST" -p "$TESTING_PORT" "$TESTING_DATABASE" | grep -v 'Null display is' | sed 's/^ *//'
}

