import os

class Config:
    # Debug mode for FastAPI/Uvicorn
    DEBUG = os.environ.get('DEBUG', 'False') == 'True'
    # Azure Blob Storage endpoint
    BLOB_ENDPOINT = os.environ.get('BLOB_ENDPOINT', '')
