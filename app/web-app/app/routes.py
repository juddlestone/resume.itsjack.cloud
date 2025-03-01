from flask import Blueprint, render_template, jsonify, request
import os
import json
import hashlib

main_bp = Blueprint('main', __name__)

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
@main_bp.route('/')
def index():
    blob_endpoint = os.environ.get('BLOB_ENDPOINT')
    return render_template('index.html', BLOB_ENDPOINT=blob_endpoint)

# Counter function
# This function will count the number of unique visitors
# The counter data will be stored in a JSON file
@main_bp.route('/get_visitor_count')
def get_visitor_count():
    try:
        # Get visitor's IP address
        # The IP addresses of the visitors will be hashed before storing
        ip_address = request.remote_addr
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
        
        return jsonify({"count": data["count"]})
    except Exception as e:
        # Log the error for debugging
        print(f"Error in visitor counting: {str(e)}")
        return jsonify({"error": str(e), "count": 0})