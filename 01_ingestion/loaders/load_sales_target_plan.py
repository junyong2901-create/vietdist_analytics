import os
import sys 
import time
from pathlib import Path 

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pandas as pd 
from dotenv import load_dotenv

from connectors.gdrive_connector import list_files_in_folder, download_file_as_bytes
from utils.file_parser import parse_file
from utils.db_utils import *

load_dotenv()

FOLDER_ID = os.getenv('GDRIVE_FOLDER_ID')
TARGET_FILE = 'SRC02_sales_target_plan.xlsx'
TABLE_NAME = 'sales_target_plan'
TARGET_SCHEMA = 'raw'
SHEETS_TO_LOAD = [0,1]
SOURCE_PLATFORM = 'google_drive'

def read_all_sheets(file_name, raw_bytes):

    sheets = parse_file(file_name, raw_bytes, sheet_name=SHEETS_TO_LOAD)

    frames = []
    first_cols = None
    for idx, sdf in sheets.items():
        sdf=sdf.copy()
        sdf.columns = [str(c).strip() for c in sdf.columns] #Delete space in columns name

        if 'plan_version' not in sdf.columns:
            print(f"    NOTICE: sheet {idx + 1} does not have plan_version column")

        #Notice if sheet has different columns name
        cols = set(sdf.columns)
        if first_cols is None:
            first_cols = cols
        elif cols != first_cols:
            print(f" NOTICE: sheet '{idx + 1}' has different name with first sheet: "
                  f" Missing {sorted(first_cols - cols)}, Surplus {sorted(cols - first_cols)}")

        print(f"    Sheet '{idx + 1}': {len(sdf)} rows, {len(sdf.columns) - 1} columns")
        frames.append(sdf)

    return pd.concat(frames, ignore_index=True, sort=False) #Keep the sort of columns, if only has 1 sheet will return NULL at other sheet

def run():
    batch_id = generate_batch_id()
    engine = get_engine()

    files = list_files_in_folder(FOLDER_ID)
    print(f"Find {len(files)} files in folder")

    total_loaded = 0
    for f in files:
        if not f['name'].endswith(TARGET_FILE):
            continue
        try:
            raw_bytes = download_file_as_bytes(f['id'])
            df = read_all_sheets(f['name'], raw_bytes)
            df = add_metadata(df, f['name'], SOURCE_PLATFORM, batch_id)
            start = time.time()
            rows = load_to_bronze(df, TABLE_NAME, engine, schema=TARGET_SCHEMA, if_exists='append')
            total_loaded += rows
            print(f'    OK: {f['name']} - {rows} rows')

            print(write_log(engine, batch_id, TABLE_NAME, f['name'], rows, 'SUCCESS', round(time.time() - start,2)))

        except Exception as e:
            print(f"    ERROR: {f['name']} - {e}")

if __name__ == '__main__':
     run()
