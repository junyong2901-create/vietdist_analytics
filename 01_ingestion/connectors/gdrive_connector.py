import io 
import os #đọc các biến môi trường đường dẫn và folder_key
from pathlib import Path #xử lý đường dẫn file theo cách rõ ràng

from dotenv import load_dotenv #nạp cấu hình từ .env
from google.oauth2 import service_account #Tạo creadentials từ JSON key của Service Account
from googleapiclient.discovery import build #Tạo client để gọi Google Drive API
from googleapiclient.http import MediaIoBaseDownload

load_dotenv()

PROJECT_ROOT = Path(__file__).resolve().parents[2]

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]

def _get_service():
    """Create client Google Drive from file JSON key declaration in .env"""
    key_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
    if not key_path:
        raise EnvironmentError("Missing GOOGLE_SERVICE_ACCOUNT_PATH in .env")

    key_file = Path(key_path)
    if not key_file.is_absolute():
        key_file = PROJECT_ROOT / key_file
    if not key_file.exists():
        raise FileNotFoundError(f"Can not found file key: {key_file}")

    creds = service_account.Credentials.from_service_account_file(
        str(key_file), scopes=SCOPES
    )
    return build("drive", "v3", credentials=creds)

def list_files_in_folder(folder_id):
    """Return list[dict] included id, name, mimeType, size of all files in folder"""
    service = _get_service()
    files = []
    page_token = None
    while True:
        resp = service.files().list(
            q=(f"'{folder_id}' in parents and trashed=False"),
            fields=("nextPageToken, files(id, name, mimeType, size)"),
            pageSize=100,
            pageToken=page_token,
            orderBy="name",
        ).execute()
        files.extend(resp.get("files",[]))
        page_token = resp.get("nextPageToken")
        if not page_token:
            break
    return files 

def download_file_as_bytes(file_id):
    """Download 1 file into RAM, return BytesIO"""
    service = _get_service()
    request = service.files().get_media(fileId=file_id, supportsAllDrives=True)
    buf = io.BytesIO()
    downloader = MediaIoBaseDownload(buf, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    buf.seek(0)
    return buf

if __name__ == "__main__":
    FOLDER_ID = os.getenv("GDRIVE_FOLDER_ID")
    files=list_files_in_folder(FOLDER_ID)
    print(f"Find {len(files)} file:")
    for f in files:
        print(f" - {f['name']} ({f['mimeType']})")