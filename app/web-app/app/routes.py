from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
import os
import json
import hashlib
from pathlib import Path

router = APIRouter()

# Setup Jinja2 templates
base_dir = Path(__file__).resolve().parent
templates = Jinja2Templates(directory=str(base_dir / "templates"))

# Custom url_for function for Flask compatibility
def custom_url_for(name: str, **path_params):
    """
    Custom url_for function that mimics Flask's url_for for static files
    """
    if name == 'static':
        filename = path_params.get('filename', '')
        return f"/static/{filename}"
    # For other routes, would need request context
    return f"/{name}"

# Add url_for to Jinja2 globals
templates.env.globals['url_for'] = custom_url_for

# Counter File Path
counter_file_path = '/visitor-data/counter.json'

# Hash IP 
# Protect the privacy of the visitors by hashing their IP addresses
def hash_ip(ip):
    return hashlib.sha256(ip.encode()).hexdigest()

# Landing Page
# Loads pictures from the Azure Blob Storage
# The Blob Storage URL is passed to the HTML template
# The URL is read from the environment variable BLOB_ENDPOINT
@router.get('/', response_class=HTMLResponse)
async def index(request: Request):
    blob_endpoint = os.environ.get('BLOB_ENDPOINT')
    return templates.TemplateResponse('index.html', {
        'request': request,
        'BLOB_ENDPOINT': blob_endpoint
    })

# Counter function
# This function will count the number of unique visitors
# The counter data will be stored in a JSON file
@router.get('/get_visitor_count')
async def get_visitor_count(request: Request):
    try:
        # Get visitor's IP address
        # The IP addresses of the visitors will be hashed before storing
        ip_address = request.client.host if request.client else "127.0.0.1"
        hashed_ip = hash_ip(ip_address)

        # Check if the counter file exists
        if os.path.exists(counter_file_path):
            try:
                with open(counter_file_path, 'r') as file:
                    data = json.load(file)
            except json.JSONDecodeError:
                # If the file is empty or corrupted, reset the counter
                data = {"count": 0, "unique_visitors": []}
        else:
            # Create a new counter file if it does not exist
            os.makedirs(os.path.dirname(counter_file_path), exist_ok=True)
            data = {"count": 0, "unique_visitors": []}

        # The counter data will be updated only if the visitor is unique
        if hashed_ip not in data["unique_visitors"]:
            # Update the counter for new unique visitor
            data["unique_visitors"].append(hashed_ip)
            data["count"] += 1

            # Write the updated data back to the file
            with open(counter_file_path, 'w') as file:
                json.dump(data, file)

        return {"count": data["count"]}
    except Exception as e:
        # Log the error for debugging
        print(f"Error in visitor counting: {str(e)}")
        return {"error": str(e), "count": 0}