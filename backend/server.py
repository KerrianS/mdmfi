from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from routes.odoo_routes import odoo_router
from routes.navision_routes import navision_router
from routes.file_routes import file_router
import json
import locale
import os
import asyncio
import logging

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

os.environ['PYTHONIOENCODING'] = 'utf-8'
app = FastAPI(
    title="MDM-FI API - Analyse SIG avec WebSocket Relay",
    description="API d'analyse des indicateurs SIG pour Odoo et Navision avec notifications temps réel.",
    version="1.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware pour forcer l'encodage UTF-8 dans les réponses JSON
@app.middleware("http")
async def force_utf8_encoding(request, call_next):
    response = await call_next(request)
    if "application/json" in response.headers.get("content-type", ""):
        response.headers["Content-Type"] = "application/json; charset=utf-8"
    return response
app.include_router(odoo_router)
app.include_router(navision_router)
app.include_router(file_router)

@app.get("/")
def root():
    return {
        "message": "API MDM-FI avec WebSocket Relay", 
        "version": "1.1.0",
        "features": [
            "Analyse SIG Navision/Odoo",
            "Notifications temps réel via WebSocket",
            "Monitoring automatique des données",
            "WebSocket Relay pour multi-clients",
            "Gestion des fichiers JSON",
            "Synchronisation temps réel"
        ],
        "endpoints": {
            "api_docs": "/docs",
            "websocket_test": "/ws/test",
            "websocket_stats": "/ws/stats",
            "files_websocket": "/api/files/ws",
            "files_status": "/api/files/status"
        }
    }