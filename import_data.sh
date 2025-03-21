#!/bin/bash
set -e

# Add at the top:
DB_NAME="${MONGO_DB:-testdb}"
COLLECTION_NAME="${MONGO_COLLECTION:-testcol}"
BATCH_SIZE="${MONGO_BATCHSIZE:-10000}"

# === CLEANUP PREVIOUS FILES ===
echo "🧹 Cleaning up old files if present..."
rm -f /data/testdata.json /data/testdata.json.gz /data/data_ready.flag /data/importer.log

LOGFILE=/data/importer.log
exec > >(tee -a "$LOGFILE") 2>&1

FILE="/data/testdata.json"
if [ "$COMPRESS" = "1" ]; then
  FILE="/data/testdata.json.gz"
fi

# Auto-detect CPU cores if not set
if [ "$NUM_WORKERS" = "auto" ] || [ -z "$NUM_WORKERS" ]; then
  NUM_WORKERS=$(nproc)
fi

echo "🧮 Using $NUM_WORKERS parallel insertion workers for import"

echo "⏳ Waiting for generated data file to appear..."
# Wait for file itself
while [ ! -f "$FILE" ]; do
  sleep 3
done

# Wait for ready flag
while [ ! -f "/data/data_ready.flag" ]; do
  sleep 1
done

echo "✅ Data file found at $FILE, starting import..."

if [ "$COMPRESS" = "1" ]; then
  stdbuf -oL mongoimport --host mongo --port 27017 --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --db "$DB_NAME" --collection "$COLLECTION_NAME" --file "$FILE" --gzip --numInsertionWorkers "$NUM_WORKERS" --batchSize "$BATCH_SIZE"
  echo "🧹 Cleaning up compressed file..."
  rm -f "$FILE"
else
  stdbuf -oL mongoimport --host mongo --port 27017 --username "$MONGO_INITDB_ROOT_USERNAME" --password "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --db "$DB_NAME" --collection "$COLLECTION_NAME" --file "$FILE" --numInsertionWorkers "$NUM_WORKERS" --batchSize "$BATCH_SIZE"
  echo "🧹 Cleaning up uncompressed file..."
  rm -f "$FILE"
fi

rm -f /data/data_ready.flag

sleep 3
echo "✅ Import finished."
sleep 3
