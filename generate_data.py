import json
from tqdm import tqdm
from multiprocessing import Pool, cpu_count
import os
import gzip

from document_template import generate_document

# Read from environment variables
TOTAL_DOCS = int(os.getenv('TOTAL_DOCS', '10000000'))
CORES = cpu_count()
DOCS_PER_CORE = TOTAL_DOCS // CORES

TEMP_FOLDER = '/data/tmp'
FINAL_FILE = '/data/testdata.json'
COMPRESS = os.getenv('COMPRESS', '0') == '1'

if COMPRESS:
    FINAL_FILE += '.gz'

os.makedirs(TEMP_FOLDER, exist_ok=True)

def generate_chunk(core_id):
    start_id = core_id * DOCS_PER_CORE
    end_id = start_id + DOCS_PER_CORE
    filename = f"{TEMP_FOLDER}/chunk_{core_id}.json"

    with open(filename, 'w') as f:
        for i in tqdm(
              range(start_id, end_id),
              desc=f"Core {core_id}",
              position=core_id,
              dynamic_ncols=True,
              mininterval=0.5,
              miniters=1000       # Only refresh after every 1000 iterations
              ):
            doc = generate_document(i)
            f.write(json.dumps(doc) + '\n')
    return filename

if __name__ == "__main__":
    print(f"Starting generation of {TOTAL_DOCS} documents with {CORES} cores...")
    with Pool(CORES) as p:
        chunk_files = p.map(generate_chunk, range(CORES))

    print("Merging chunks...")
    if COMPRESS:
        with gzip.open(FINAL_FILE, 'wt') as outfile:
            for fname in chunk_files:
                with open(fname) as infile:
                    outfile.writelines(infile)
    else:
        with open(FINAL_FILE, 'w') as outfile:
            for fname in chunk_files:
                with open(fname) as infile:
                    outfile.writelines(infile)

    print(f"Cleaning up temporary files...")
    for fname in chunk_files:
        os.remove(fname)
    # After merging chunks and cleanup
    with open("/data/data_ready.flag", "w") as f:
        f.write("ready\n")
    print("✅ Data generation complete. Ready flag written.")
    print(f"✅ Generated {TOTAL_DOCS} documents into {FINAL_FILE}")
