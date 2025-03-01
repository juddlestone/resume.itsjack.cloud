from flask import Blueprint, render_template, jsonify
import os
import requests

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    blob_endpoint = os.environ.get('BLOB_ENDPOINT')
    return render_template('index.html', BLOB_ENDPOINT=blob_endpoint)

@main_bp.route('/get_visitor_count')
def get_visitor_count():
    backend_endpoint = os.environ.get('BACKEND_ENDPOINT')
    if not backend_endpoint:
        return jsonify({"error": "Backend endpoint not configured", "count": 0})
    
    counter_url = f"http://{backend_endpoint}/api/count"
    
    # Retry logic
    max_retries = 3
    retry_delay = 2  # seconds
    
    for attempt in range(max_retries):
        try:
            response = requests.get(counter_url, timeout=10)
            if response.status_code == 200:
                return jsonify(response.json())
            
            # If we got a non-200 status, wait and retry
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
                continue
                
            return jsonify({"error": f"Failed to retrieve count: Status {response.status_code}", "count": 0})
        
        except Exception as e:
            if attempt < max_retries - 1:
                time.sleep(retry_delay)
                continue
            
            return jsonify({"error": str(e), "count": 0})