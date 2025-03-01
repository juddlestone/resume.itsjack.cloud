# counter-app/app/routes.py
from flask import Blueprint, jsonify, request
import os
import json
import hashlib

api_bp = Blueprint('api', __name__, url_prefix='/api')

# Path to the counter file
counter_file_path = '/visitor-data/counter.json'

# Hash IP to protect privacy
def hash_ip(ip):
    return hashlib.sha256(ip.encode()).hexdigest()

@api_bp.route('/count', methods=['GET'])
def get_count():
    try:
        # Get visitor's IP address
        ip_address = request.remote_addr
        hashed_ip = hash_ip(ip_address)
        
        # Check if the counter file exists
        if os.path.exists(counter_file_path):
            with open(counter_file_path, 'r') as file:
                data = json.load(file)
        else:
            data = {"count": 0, "unique_visitors": []}
        
        # Check if this is a unique visitor
        if hashed_ip not in data["unique_visitors"]:
            # Update the counter for new unique visitor
            data["unique_visitors"].append(hashed_ip)
            data["count"] += 1
            
            # Write the updated data back to the file
            with open(counter_file_path, 'w') as file:
                json.dump(data, file)
        
        return jsonify({"count": data["count"]})
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({"error": str(e), "count": 0})
