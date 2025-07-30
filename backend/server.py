from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from routes.odoo_routes import odoo_router
from routes.navision_routes import navision_router
from routes.notification_routes import notification_router
from routes.websocket_routes import websocket_router
from websocket.data_detector import data_detector
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
# app.include_router(notification_router)
# app.include_router(websocket_router)

# @app.on_event("startup")
# async def startup_event():
#     """Démarrer le monitoring automatique au lancement du serveur"""
#     logger.info("🚀 Démarrage du serveur MDM-FI avec WebSocket Relay")
    
#     # Démarrer le monitoring automatique des données
#     data_detector.start_monitoring()
#     logger.info("📊 Monitoring automatique des données démarré")

# @app.on_event("shutdown")
# async def shutdown_event():
#     """Nettoyer les ressources au arrêt du serveur"""
#     logger.info("🔄 Arrêt du serveur MDM-FI")
#     data_detector.stop_monitoring()
#     logger.info("⏹️ Monitoring des données arrêté")

@app.get("/")
def root():
    return {
        "message": "API MDM-FI avec WebSocket Relay", 
        "version": "1.1.0",
        "features": [
            "Analyse SIG Navision/Odoo",
            "Notifications temps réel via WebSocket",
            "Monitoring automatique des données",
            "WebSocket Relay pour multi-clients"
        ],
        "endpoints": {
            "api_docs": "/docs",
            "websocket_test": "/ws/test",
            "websocket_stats": "/ws/stats"
        }
    }