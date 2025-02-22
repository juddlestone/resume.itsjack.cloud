from flask import Blueprint, render_template, request, jsonify
import os
import datetime
import requests

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
def index():
    last_update = datetime.datetime.now().strftime("%B %d, %Y")
    return render_template('index.html', last_update=last_update)

@main_bp.route('/get_visitor_count')
def get_visitor_count():
    counter_url = os.environ.get('COUNTER_API_URL', 'http://counter-app:5000/api/count')
    try:
        response = requests.get(counter_url)
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({"error": "Failed to retrieve count", "count": 0})
    except Exception as e:
        return jsonify({"error": str(e), "count": 0})