import os 
import uuid
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.types import Text, TIMESTAMP

load_dotenv()

DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT')
DB_USER = os.getenv('DB_USER')
DB_PASS = os.getenv('DB_PASS')
DB_NAME = os.getenv('DB_NAME')

VALID_PLATFORMS = {'google_drive', 'onedrive'}
METADATA_COLUMNS = ['e_source_file', '_source_platform', '_ingested_at', '_batch_id']

#Create engine
def get_engine():
    try:
        engine = create_engine(f'postgresql+psycopg2://{DB_USER}:{quote_plus(DB_PASS)}@{DB_HOST}:{DB_PORT}/{DB_NAME}')
        print("Create engine sucessfully")
        return engine
    except Exception as e:
        print(f"Error creating engine: {e}")
        raise

#Create Metadata
def generate_batch_id():
    """Create batch_id (UUID). Call once per time running pipeline"""
    return str(uuid.uuid4())

def add_metadata(df, source_file, source_platform, batch_id=None):
    """Add 4 columns metadata into dataframe (not in the original)"""
    if source_platform not in VALID_PLATFORMS:
        raise ValueError(
            f"source_platform must be {sorted(VALID_PLATFORMS)}, receive: {source_platform!r}"
        )
    df = df.copy()
    df['e_source_file'] = source_file
    df['_source_platform'] = source_platform
    df['_ingested_at'] = pd.Timestamp.now()
    df['_batch_id'] = batch_id or generate_batch_id()
    return df

#Load to bronze schema
def load_to_bronze(df, table_name, engine=None, schema='raw', if_exists='append'):
    """Record dataframe into raw. <table_name>. Return number of rows loaded"""
    missing = [c for c in METADATA_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Missing metadata columns {missing}. Call add_metadata() first.")

    if engine is None:
        engine = get_engine()

    try:
        with engine.begin() as conn:
            df.to_sql(
                name=table_name,
                con=conn,
                schema=schema,
                if_exists=if_exists,
                index=False,
                chunksize=5000,
                method='multi',
                dtype={
                    'e_source_file': Text(),
                    '_source_platform': Text(),
                    '_ingested_at': TIMESTAMP(),
                    '_batch_id': UUID(as_uuid=False),
                }
            )
        print(f"{table_name} inserted successfully ({len(df)} rows)")
        return len(df)
    except Exception as e:
        print(f"Error inserting {table_name}: {e}")
        raise


def write_log(engine, batch_id, source_name, source_file, rows_loaded,
              status, duration_sec, error_message=None):

    """
    Ghi 1 dòng vào raw.ingestion_log.
    status: 'success' hoặc 'failed' (chữ thường, đúng ràng buộc CHECK của bảng).
    """
    status = status.lower()
    SOURCE_PLATFORM = 'google_drive'
    VALID_STATUS = {'success', 'failed'}
    LOG_TABLE = 'raw.ingestion_log'
    if status not in VALID_STATUS:
        raise ValueError(f"status phải là một trong {sorted(VALID_STATUS)}, nhận được: {status!r}")
 
    with engine.begin() as conn:
        conn.execute(
            text(
                f'INSERT INTO {LOG_TABLE} '
                '(batch_id, source_name, source_platform, source_file, '
                'status, rows_loaded, duration_sec, error_message) '
                'VALUES (CAST(:bid AS uuid), :sn, :sp, :sf, :st, :rl, :dur, :err)'
            ),
            dict(
                bid=str(batch_id),
                sn=source_name,
                sp=SOURCE_PLATFORM,
                sf=source_file,
                st=status,
                rl=int(rows_loaded) if rows_loaded is not None else None,
                dur=round(float(duration_sec), 2),
                err=error_message,
            ),
        )
        print("Insert log successfully")