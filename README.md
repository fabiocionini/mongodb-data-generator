# MongoDB Large Test Data Generator 🚀

This project quickly generates **10 million+ realistic MongoDB documents** using `Faker` + parallel processing, and imports them into MongoDB efficiently.

---

## Features

- ✅ Uses **Faker** to generate realistic names, emails, addresses, etc.
- ✅ Fully parallelized using **multiprocessing**
- ✅ Docker Compose setup with MongoDB + auto-import
- ✅ Fast: Utilizes all available CPU cores
- ✅ Easily customizable fields & document count

---

## Configuration

Copy `env-example` to a new `.env` file and adjust:

```env
# Enable Gzip compression (1 = enabled, 0 = disabled)
COMPRESS=0

# Total number of documents to generate
TOTAL_DOCS=10000000

# MongoDB exposed port (on host machine)
MONGO_PORT=27017

# MongoDB authentication
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=secretpassword

# Number of parallel insertion workers (auto = auto-detect CPU cores)
NUM_WORKERS=auto
```

---

## Customize Document Structure

Edit `document_template.py`:

```python
def generate_document(doc_id):
    return {
        "_id": doc_id,
        "name": fake.name(),
        "email": fake.email(),
        # Add or remove fields here!
    }
```

---

## Quick Start

- Build and run with `docker-compose up` or execute `./run.sh` script.
- Stop the container with `docker compose down` or execute `./stop.sh` script.
- Connect to MongoDB instance at `localhost` using provided credentials and port:
```bash
mongosh "mongodb://admin:secretpassword@localhost:27017/admin"
use testdb
db.testcol.countDocuments()
```

## Monitor Progress & Import Status

To view real-time:

- Document generation (multi-core progress bars)
- Import progress & cleanup logs

Run:

```bash
./show-progress.sh
```

#### Requirements
`tmux` is needed to show real time progress output. 

Install via `brew`, `apt` or other package managers.
