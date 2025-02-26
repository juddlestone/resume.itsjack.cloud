# counter-app/app/routes.py
from flask import Blueprint, jsonify, request
import os
from azure.data.tables import TableServiceClient, TableClient
from azure.core.exceptions import ResourceExistsError
import datetime
import hashlib

api_bp = Blueprint('api', __name__, url_prefix='/api')

# Azure Table Storage configuration
connection_string = os.environ.get('AZURE_STORAGE_CONNECTION_STRING')
table_name = os.environ.get('VISITOR_TABLE_NAME', 'visitorcount')

# Initialize table if it doesn't exist
def ensure_table_exists():
    table_service = TableServiceClient.from_connection_string(conn_str=connection_string)
    try:
        table_service.create_table(table_name=table_name)
    except ResourceExistsError:
        # Table already exists
        pass
    return table_service.get_table_client(table_name=table_name)

# Get or create counter entity
def get_counter_entity(table_client):
    try:
        counter_entity = table_client.get_entity(partition_key="counter", row_key="visitor_count")
        return counter_entity
    except:
        # Create new counter if it doesn't exist
        counter_entity = {
            "PartitionKey": "counter",
            "RowKey": "visitor_count",
            "count": 0,
            "unique_visitors": []
        }
        table_client.create_entity(entity=counter_entity)
        return counter_entity

# Hash IP to protect privacy
def hash_ip(ip):
    return hashlib.sha256(ip.encode()).hexdigest()

@api_bp.route('/count', methods=['GET'])
def get_count():
    try:
        # Get visitor's IP address
        ip_address = request.remote_addr
        hashed_ip = hash_ip(ip_address)
        
        # Initialize table connection
        table_client = ensure_table_exists()
        
        # Get counter entity
        counter_entity = get_counter_entity(table_client)
        
        # Check if this is a unique visitor
        visitor_list = counter_entity.get("unique_visitors", [])
        
        if hashed_ip not in visitor_list:
            # Update the counter for new unique visitor
            visitor_list.append(hashed_ip)
            
            # Update the entity
            table_client.update_entity(entity={
                "PartitionKey": "counter",
                "RowKey": "visitor_count",
                "count": len(visitor_list),
                "unique_visitors": visitor_list,
                "last_updated": datetime.datetime.utcnow().isoformat()
            })
            
        # Get the updated count
        counter_entity = table_client.get_entity(partition_key="counter", row_key="visitor_count")
        count = counter_entity.get("count", 0)
        
        return jsonify({"count": count})
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({"error": str(e), "count": 0})