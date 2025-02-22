from flask import Flask
import os

def create_app():
    app = Flask(__name__)
    
    # Configuration
    app.config.from_object('config.Config')
    
    # Register blueprints
    from app.routes import main_bp
    app.register_blueprint(main_bp)
    
    return app