#!/bin/bash
set -e

# Cleanup previous files
echo "🧹 Cleaning up old files..."
rm -f /data/testdata.json /data/data_ready.flag /data/importer.log

# Setup logging
LOGFILE=/data/importer.log
exec > >(tee -a "$LOGFILE") 2>&1

FILE="/data/testdata.json"

DB_NAME="${MONGO_DB:-testdb}"
COLLECTION_NAME="${MONGO_COLLECTION:-testcol}"
BATCH_SIZE="${MONGO_BATCHSIZE:-10000}"
MONGO_URI="${MONGO_URI:-}"
HOST="${MONGO_HOST:-mongo}"
USERNAME="${MONGO_USERNAME:-admin}"
PASSWORD="${MONGO_PASSWORD:-password}"

# Auto-detect CPU cores if not set
if [ "$NUM_WORKERS" = "auto" ] || [ -z "$NUM_WORKERS" ]; then
  NUM_WORKERS=$(nproc)
fi

echo "🧮 Using $NUM_WORKERS parallel insertion workers and batch size $BATCH_SIZE"

echo "⏳ Waiting for generated data file to appear..."
# Wait for file itself
while [ ! -f "$FILE" ]; do
  sleep 3
  if [ -f "/data/data_ready.flag" ]; then
    break
  fi
done

# Wait for ready flag
while [ ! -f "/data/data_ready.flag" ]; do
  sleep 1
done

echo "✅ Data file found at $FILE, starting import..."

# Prepare import command
IMPORT_CMD="mongoimport --numInsertionWorkers $NUM_WORKERS --batchSize $BATCH_SIZE --db $DB_NAME --collection $COLLECTION_NAME --file \"$FILE\""

if [ -n "$MONGO_URI" ]; then
  IMPORT_CMD="$IMPORT_CMD --uri=\"$MONGO_URI\" --username=\"$USERNAME\" --password=\"$PASSWORD\" --authenticationDatabase=admin"
else
  IMPORT_CMD="$IMPORT_CMD --host $HOST --port 27017 --username=\"$USERNAME\" --password=\"$PASSWORD\" --authenticationDatabase=admin"
fi


eval "stdbuf -oL $IMPORT_CMD"

echo "🧹 Cleaning up data files..."
rm -f "$FILE" /data/data_ready.flag

sleep 3
echo "✅ Import finished."
sleep 3
