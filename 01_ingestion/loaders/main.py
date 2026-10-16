
import os
from pathlib import Path

from dotenv import load_dotenv
from connectors.gdrive_connector import list_files_in_folder, download_file_as_bytes
from utils.file_parser import parse_file

load_dotenv()

FOLDER_ID = os.getenv("GDRIVE_FOLDER_ID")

files = list_files_in_folder(FOLDER_ID)

CSV_NAME = "SRC01_sales_transactions.csv"

XLXS_NAME = "SRC05_distributor_orders.xlsx" 

name_to_id = {f["name"]: f["id"] for f in files}

for name in [CSV_NAME, XLXS_NAME]:
    buf = download_file_as_bytes(name_to_id[name])
    df = parse_file(name, buf)
    print(f"\n== {name} ===")
    print(f"{df.shape[0]} rows, {df.shape[1]} columns")
    print(df.head(3))
