import io
from pathlib import Path
import pandas as pd

CSV_ENCODINGS = ["utf-8-sig", "utf-8", "cp1258", "utf-16", "latin-1"]

def _to_buffer(source):
    """Receive BytesIO or file local domain, return BytesIO"""
    if isinstance(source, (str, Path)):
        with open(source, "rb") as f:
            return io.BytesIO(f.read())
    source.seek(0)
    return source

def parse_csv(source, sep=",", encodings=CSV_ENCODINGS, **kwargs):
    """Try individual encoding because Vietnamese CSV normally wrong encoding"""
    buf = _to_buffer(source)
    last_err = None  
    for enc in encodings:
        try:
            buf.seek(0)
            return pd.read_csv(buf, encoding=enc, sep=sep, **kwargs)
        except UnicodeError as e:
            last_err = e
    raise ValueError(f"Can not read CSV with encondings: {encodings}: {last_err}")

def parse_xlsx(source, sheet_name=0, **kwargs):
    return pd.read_excel(_to_buffer(source), sheet_name=sheet_name, engine="openpyxl", **kwargs)

def parse_xlsm(source, sheet_name=0, **kwargs):
    return pd.read_excel(_to_buffer(source), sheet_name=sheet_name, engine="openpyxl", **kwargs)

def parse_xlsb(source, sheet_name=0, **kwargs):
    return pd.read_excel(_to_buffer(source), sheet_name=sheet_name, engine="pyxlsb", **kwargs)

PARSERS = {
   "csv":parse_csv,
   "xlsx":parse_xlsx,
   "xlsm":parse_xlsm,
   "xlsb":parse_xlsb 
}

def parse_file(file_name, source, **kwargs):
    """Choose function as tail of file_name.
    
    file_name: file name
    source: BytesIO (download_file)
    **kwargs: return sheet_name, sep, header for the allocate function"""

    ext = Path(file_name).suffix.lower().lstrip(".")
    if ext not in PARSERS:
        raise ValueError(f"format not supported: .{ext} ({file_name})."
                         f"Support: {list(PARSERS)}")
    return PARSERS[ext](source, **kwargs)
