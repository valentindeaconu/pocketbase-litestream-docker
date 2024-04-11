# pocketbase-litestream-docker

This project builds a Docker image that wraps the [PocketBase](https://pocketbase.io/) server with [litestream](https://litestream.io/) to continuously back up the SQLite databases to a remote S3 storage.

The entry point is overwritten so that if the database does not exist at startup, it will be downloaded from the remote storage before starting the actual database.

Litestream also exposes a port that can be scraped for metrics. If you wish to enable that, expose the port `9090`.

## Inputs

| Variable | Description | Default |
| --- | --- | --- |
| PORT | The port PocketBase should listen to. | `8090` |
| LITESTREAM_PORT | The port litestream should listen to. | `9090` |
| LITESTREAM_ACCESS_KEY | Access Key for the S3-compatible storage. | `n/a` |
| LITESTREAM_SECRET_ACCESS_KEY | Secret Access Key for the S3-compatible storage. | `n/a` |
| ENABLE_LITESTREAM_DATA_RESTORATION | Whether to restore the data database at startup or not. | `true` |
| ENABLE_LITESTREAM_LOGS_RESTORATION | Whether to restore the logs database at startup or not. | `true` |
| ENABLE_LITESTREAM_REPLICATION | Whether to enable continuous replication via litestream or not. | `true` |
| DATA_REPLICA_URI | An S3 URI where the data database should be replicated. | `n/a` |
| LOGS_REPLICA_URI | An S3 URI where the logs database should be replicated. | `n/a` |
| PB_ENCRYPTION_KEY | The secret used to encrypt PocketBase settings. | `n/a` |
| PB_DATA_PATH | The path to the data directory. | `/data` |
| PB_STATIC_PATH | The path to the static directory. | `/static` |
| PB_MIGRATIONS_PATH | The path to the migrations directory. | `/migrations` |
| PB_HOOKS_PATH | The path to the custom hooks directory. | `/app/hooks` |
| PB_ENABLE_AUTO_MIGRATION | Whether to enable auto-migrations or not. | `false` |
| PB_ENABLE_INDIVIDUAL_MIGRATIONS | Whether to enable individual migrations or not. | `true` |
| PB_DEV | Enables dev mode for PocketBase. | `false` |
| DATA_REPLICA_RETENTION | The amount of time that snapshot & WAL files will be kept. | `24h` |
| DATA_REPLICA_RETENTION_CHECK_INTERVAL | Specifies how often Litestream will check if retention needs to be enforced. | `1h` |
| DATA_REPLICA_SNAPSHOT_INTERVAL | Specifies how often new snapshots will be created. Should be less or equal with the retention interval. | `24h` |
| DATA_REPLICA_VALIDATION_INTERVAL | Specifies how often Litestream will automatically restore and validate that the data on the replica matches the local copy. | `12h` |
| DATA_REPLICA_SYNC_INTERVAL | Frequency in which frames are pushed to the replica. | `1s` |
| LOGS_REPLICA_RETENTION | The amount of time that snapshot & WAL files will be kept. | `48h` |
| LOGS_REPLICA_RETENTION_CHECK_INTERVAL | Specifies how often Litestream will check if retention needs to be enforced. | `12h` |
| LOGS_REPLICA_SNAPSHOT_INTERVAL | Specifies how often new snapshots will be created. Should be less or equal with the retention interval. | `48h` |
| LOGS_REPLICA_SYNC_INTERVAL | Frequency in which frames are pushed to the replica. | `10m` |

### AWS default credentials provider chain

If you wish to configure Litestream to use the default credentials providers chain, omit to set `LITESTREAM_ACCESS_KEY` and `LITESTREAM_SECRET_ACCESS_KEY` and configure the AWS credentials instead.

## Deploy and test locally

### Build

```
docker build -t pocketbase-litestream-docker:dev .
```

### Run

```
docker run \
  -p 8090:8090 \
  -v ${PWD}/.volumes/data:/data \
  -v ${PWD}/.volumes/migrations:/migrations \
  -v ${PWD}/.volumes/static:/static \
  -v ${PWD}/.volumes/hooks:/app/hooks \
  -e PORT=8090 \
  -e DATA_REPLICA_URI=s3://YOURBUCKETNAME/data \
  -e LOGS_REPLICA_URI=s3://YOURBUCKETNAME/logs \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  pocketbase-litestream-docker:dev
```

### Run without replication for local development

```
docker run \
  -p 8090:8090 \
  -v ${PWD}/.volumes/data:/data \
  -v ${PWD}/.volumes/migrations:/migrations \
  -v ${PWD}/.volumes/static:/static \
  -v ${PWD}/.volumes/hooks:/app/hooks \
  -e PORT=8090 \
  -e ENABLE_LITESTREAM_REPLICATION=false \
  -e ENABLE_LITESTREAM_DATA_RESTORATION=false \
  -e ENABLE_LITESTREAM_LOGS_RESTORATION=false \
  -e PB_DEV=true \
  pocketbase-litestream-docker:dev
```
