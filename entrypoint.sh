#!/bin/bash

set -e

# Configure defaults
export LITESTREAM_PORT="${LITESTREAM_PORT:-"9090"}"
export ENABLE_LITESTREAM_DATA_RESTORATION="${ENABLE_LITESTREAM_DATA_RESTORATION:-"true"}"
export ENABLE_LITESTREAM_LOGS_RESTORATION="${ENABLE_LITESTREAM_LOGS_RESTORATION:-"true"}"
export ENABLE_LITESTREAM_REPLICATION="${ENABLE_LITESTREAM_REPLICATION:-"true"}"

export PB_DEV="${PB_DEV:-"false"}"
export PB_DATA_PATH="${PB_DATA_PATH:-"/data"}"
export PB_STATIC_PATH="${PB_STATIC_PATH:-"/static"}"
export PB_MIGRATIONS_PATH="${PB_MIGRATIONS_PATH:-"/migrations"}"
export PB_HOOKS_PATH="${PB_HOOKS_PATH:-"/app/hooks"}"

export PB_ENABLE_AUTO_MIGRATIONS="${PB_ENABLE_AUTO_MIGRATIONS:-"false"}"
export PB_ENABLE_INDIVIDUAL_MIGRATIONS="${PB_ENABLE_INDIVIDUAL_MIGRATIONS:-"true"}"

export DATA_REPLICA_RETENTION="${DATA_REPLICA_RETENTION:-"24h"}"
export DATA_REPLICA_RETENTION_CHECK_INTERVAL="${DATA_REPLICA_RETENTION_CHECK_INTERVAL:-"1h"}"
export DATA_REPLICA_SNAPSHOT_INTERVAL="${DATA_REPLICA_SNAPSHOT_INTERVAL:-"24h"}"
export DATA_REPLICA_VALIDATION_INTERVAL="${DATA_REPLICA_VALIDATION_INTERVAL:-"12h"}"
export DATA_REPLICA_SYNC_INTERVAL="${DATA_REPLICA_SYNC_INTERVAL:-"1s"}"

export LOGS_REPLICA_RETENTION="${LOGS_REPLICA_RETENTION:-"48h"}"
export LOGS_REPLICA_RETENTION_CHECK_INTERVAL="${LOGS_REPLICA_RETENTION_CHECK_INTERVAL:-"12h"}"
export LOGS_REPLICA_SNAPSHOT_INTERVAL="${LOGS_REPLICA_SNAPSHOT_INTERVAL:-"48h"}"
export LOGS_REPLICA_SYNC_INTERVAL="${LOGS_REPLICA_SYNC_INTERVAL:-"10m"}"

# Sanity checks
if [ "$PB_ENABLE_AUTO_MIGRATIONS" = "true" ] && [ "$PB_ENABLE_INDIVIDUAL_MIGRATIONS" = "true" ]; then
	echo "Auto-migrations and individual migrations can not be set simultaneously."
	exit 1
fi

# Make sure PocketBase directories exists
mkdir -p "${PB_DATA_PATH}"
mkdir -p "${PB_STATIC_PATH}"
mkdir -p "${PB_MIGRATIONS_PATH}"
mkdir -p "${PB_HOOKS_PATH}"

# Check if the data restoration is enabled
if [ "$ENABLE_LITESTREAM_DATA_RESTORATION" = "true" ]; then
	# Restore the data database if it does not already exist.
	if [ -f "${PB_DATA_PATH}/data.db" ]; then
		echo "Data database already exists, skipping restore."
	else
		echo "No data database found, restoring from replica if exists."
		litestream restore -if-replica-exists -o "${PB_DATA_PATH}/data.db" "${DATA_REPLICA_URI}"
	fi
fi

# Check if the logs restoration is enabled
if [ "$ENABLE_LITESTREAM_LOGS_RESTORATION" = "true" ]; then
	# Restore the logs database if it does not already exist.
	if [ -f "${PB_DATA_PATH}/logs.db" ]; then
		echo "Logs database already exists, skipping restore."
	else
		echo "No logs database found, restoring from replica if exists."
		litestream restore -if-replica-exists -o "${PB_DATA_PATH}/logs.db" "${LOGS_REPLICA_URI}"
	fi
fi

if [ "$PB_ENABLE_INDIVIDUAL_MIGRATIONS" = "true" ]; then
	/usr/local/bin/pocketbase --migrationsDir=${PB_MIGRATIONS_PATH} migrate
fi

if [ "$ENABLE_LITESTREAM_REPLICATION" = "true" ]; then
	# Run litestream with pocketbase as the subprocess.
	exec litestream replicate -exec "/usr/local/bin/pocketbase --automigrate=${PB_ENABLE_AUTO_MIGRATIONS} --dir=${PB_DATA_PATH} --publicDir=${PB_STATIC_PATH} --migrationsDir=${PB_MIGRATIONS_PATH} --hooksDir=${PB_HOOKS_PATH} serve --http=0.0.0.0:${PORT:-8090} --encryptionEnv=PB_ENCRYPTION_KEY --dev=${PB_DEV}"
else
	/usr/local/bin/pocketbase --automigrate=${PB_ENABLE_AUTO_MIGRATIONS} --dir=${PB_DATA_PATH} --publicDir=${PB_STATIC_PATH} --migrationsDir=${PB_MIGRATIONS_PATH} --hooksDir=${PB_HOOKS_PATH} serve --http=0.0.0.0:${PORT:-8090} --encryptionEnv=PB_ENCRYPTION_KEY --dev=${PB_DEV}
fi
