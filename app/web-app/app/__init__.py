from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import os
from pathlib import Path

def create_app():
    app = FastAPI(
        title="Jack Huddlestone - Resume",
        debug=os.environ.get('DEBUG', 'False') == 'True'
    )

    # Get the base directory
    base_dir = Path(__file__).resolve().parent

    # Mount static files
    app.mount("/static", StaticFiles(directory=str(base_dir / "static")), name="static")

    # Register routes
    from app.routes import router
    app.include_router(router)

    return app