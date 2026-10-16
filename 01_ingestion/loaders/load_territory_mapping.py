import uuid, time
from datetime import datetime
import sys; sys.path.append('..')
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from connectors.gdrive_connector import list_files_in_folder, download_file_as_bytes
from utils.file_parser import parse_file
from utils.db_utils import add_metadata, load_to_bronze, get_engine, write_log
from sqlalchemy import text
import os 
from dotenv import load_dotenv

load_dotenv()

FOLDER_ID = os.getenv('GDRIVE_FOLDER_ID')
TABLE_NAME = 'raw_territory_mapping'

def run():
    batch_id = str(uuid.uuid4())
    engine = get_engine()

    files = list_files_in_folder(FOLDER_ID)
    print(f"Find {len(files)} files in folder")

    total_loaded = 0
    for f in files:
        if not f['name'].endswith('SRC08_territory_mapping.xlsx'):
            continue
        try:
            raw_bytes = download_file_as_bytes(f['id'])
            df = parse_file(f['name'], raw_bytes)
            df = add_metadata(df, f['name'], 'google_drive', batch_id)
            start = time.time()
            rows = load_to_bronze(df, TABLE_NAME, if_exists='append')
            total_loaded += rows
            print(f'    OK: {f['name']} - {rows} rows')

            print(write_log(engine, batch_id, TABLE_NAME, f['name'], rows, 'SUCCESS', round(time.time() - start,2)))

        except Exception as e:
            print(f"    ERROR: {f['name']} - {e}")

if __name__ == '__main__':
     run()