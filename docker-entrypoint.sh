#!/bin/sh
set -e

if [ "$1" = 'postgres' ]; then
	# SET DEFAULT VALUES IF NOT SET
	POSTGRES_DATA=${POSTGRES_DATA:-/var/services/data/postgres}
	POSTGRES_LOG=${POSTGRES_LOG:-/var/services/log/postgres}
	POSTGRES_USER=${POSTGRES_USER:-postgres}
	POSTGRES_DB=${POSTGRES_DB:-postgres}
	POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-pgpass}
	mkdir -p "$POSTGRES_DATA" "$POSTGRES_LOG"
	chown -R postgres "$POSTGRES_DATA" "$POSTGRES_LOG"

	# CREATE INITIAL DATABASE
	if [ -z "$(ls -A "$POSTGRES_DATA")" ]; then
		gosu postgres initdb
		sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$POSTGRES_DATA"/postgresql.conf

		if [ "$POSTGRES_DB" != 'postgres' ]; then
			gosu postgres postgres --single -jE <<-EOSQL
				CREATE DATABASE "$POSTGRES_DB" OWNER "$POSTGRES_USER";
			EOSQL
			echo
		fi

		if [ "$POSTGRES_PASSWORD" == 'pgpass' ]; then
			echo "please change to a more secure password, if this is running in production"
		fi

		if [ "$POSTGRES_USER" = 'postgres' ]; then
			op='ALTER'
		else
			op='CREATE'
		fi

		gosu postgres postgres --single -jE <<-EOSQL
			$op USER "$POSTGRES_USER" WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';
		EOSQL
		echo

		{ echo; echo "host all all 0.0.0.0/0 md5"; } >> "$POSTGRES_DATA"/pg_hba.conf
	fi
	exec gosu postgres "$@"
fi

exec "$@"

