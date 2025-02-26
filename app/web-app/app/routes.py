from flask import Blueprint, render_template, request, jsonify
import os
import datetime
import requests

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    return render_template('index.html')

@main_bp.route('/get_visitor_count')
def get_visitor_count():
    counter_url = os.environ.get('COUNTER_CONTAINER_HOSTNAME')
    try:
        response = requests.get(counter_url)
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({"error": "Failed to retrieve count", "count": 0})
    except Exception as e:
        return jsonify({"error": str(e), "count": 0})