#!/bin/sh
set -e

if [ "$1" = 'postgres' ]; then
	# SET DEFAULT VALUES IF NOT SET
	PGDATA=${PGDATA:-/var/services/data/postgres}
	PGLOG=${PGLOG:-/var/services/log/postgres}
	PGUSER=${PGUSER:-postgres}
	PGDB=${PGDB:-postgres}
	PGPASSWORD=${PGPASSWORD:-pgpass}
	mkdir -p "$PGDATA" "$PGLOG"
	chown -R postgres "$PGDATA" "$PGLOG"

	# CREATE INITIAL DATABASE
	if [ -z "$(ls -A "$PGDATA")" ]; then
		gosu postgres initdb
		sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

		if [ "$PGDB" != 'postgres' ]; then
			gosu postgres postgres --single -jE <<-EOSQL
				CREATE DATABASE "$PGDB" OWNER "$PGUSER";
			EOSQL
			echo
		fi

		if [ "$PGPASSWORD" == 'pgpass' ]; then
			echo "please change to a more secure password, if this is running in production"
		fi

		if [ "$PGUSER" = 'postgres' ]; then
			op='ALTER'
		else
			op='CREATE'
		fi

		gosu postgres postgres --single -jE <<-EOSQL
			$op USER "$PGUSER" WITH SUPERUSER PASSWORD '$PGPASSWORD';
		EOSQL
		echo

		{ echo; echo "host all all 0.0.0.0/0 md5"; } >> "$PGDATA"/pg_hba.conf
	fi
	exec gosu postgres "$@"
fi

exec "$@"

