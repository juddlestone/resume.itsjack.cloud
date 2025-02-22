from flask import Flask
import os
from flask_cors import CORS

def create_app():
    app = Flask(__name__)
    CORS(app)  # Enable CORS for API requests
    
    # Configuration
    app.config.from_object('config.Config')
    
    # Register blueprints
    from app.routes import api_bp
    app.register_blueprint(api_bp)
    
    return app




