from fastapi import APIRouter, HTTPException, UploadFile, File, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
from typing import List, Dict, Optional
import json
import os
import shutil
import asyncio
from datetime import datetime
import logging
from pydantic import BaseModel

# Configuration du logging
logger = logging.getLogger(__name__)

# Modèles Pydantic
class FileInfo(BaseModel):
    filename: str
    societe: str
    type_data: str
    annee: str
    size: int
    last_modified: str
    checksum: str

class SyncStatus(BaseModel):
    societe: str
    status: str
    message: str
    timestamp: str

# Router pour la gestion des fichiers
file_router = APIRouter(prefix="/api/files", tags=["Files Management"])

# Stockage des connexions WebSocket actives
active_connections: List[WebSocket] = []

# Répertoire de base pour les fichiers JSON
BASE_FILES_DIR = "payloads_societes"

async def notify_clients(message: dict):
    """Notifie tous les clients WebSocket connectés"""
    if active_connections:
        await asyncio.gather(
            *[connection.send_text(json.dumps(message)) for connection in active_connections]
        )

@file_router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """Endpoint WebSocket pour les notifications temps réel"""
    await websocket.accept()
    active_connections.append(websocket)
    
    try:
        # Envoyer un message de bienvenue
        await websocket.send_text(json.dumps({
            "type": "connection",
            "message": "Connecté au WebSocket Relay",
            "timestamp": datetime.now().isoformat()
        }))
        
        # Garder la connexion active
        while True:
            data = await websocket.receive_text()
            # Traiter les messages du client si nécessaire
            logger.info(f"Message reçu du client: {data}")
            
    except WebSocketDisconnect:
        active_connections.remove(websocket)
        logger.info("Client WebSocket déconnecté")
    except Exception as e:
        logger.error(f"Erreur WebSocket: {e}")
        if websocket in active_connections:
            active_connections.remove(websocket)

@file_router.get("/societes")
async def get_societes():
    """Récupère la liste des sociétés disponibles"""
    try:
        if not os.path.exists(BASE_FILES_DIR):
            return {"societes": []}
        
        societes = [d for d in os.listdir(BASE_FILES_DIR) 
                   if os.path.isdir(os.path.join(BASE_FILES_DIR, d))]
        
        return {"societes": societes}
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des sociétés: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.get("/societe/{societe}/files")
async def get_societe_files(societe: str):
    """Récupère la liste des fichiers JSON pour une société donnée"""
    try:
        societe_dir = os.path.join(BASE_FILES_DIR, societe)
        if not os.path.exists(societe_dir):
            raise HTTPException(status_code=404, detail=f"Société {societe} non trouvée")
        
        files = []
        for filename in os.listdir(societe_dir):
            if filename.endswith('.json'):
                file_path = os.path.join(societe_dir, filename)
                stat = os.stat(file_path)
                
                # Extraire les informations du nom de fichier
                file_info = {
                    "filename": filename,
                    "societe": societe,
                    "size": stat.st_size,
                    "last_modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    "type_data": filename.split('_')[0] if '_' in filename else "unknown",
                    "annee": filename.split('_')[-1].replace('.json', '') if '_' in filename else "unknown"
                }
                files.append(file_info)
        
        return {"societe": societe, "files": files}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des fichiers: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.get("/download/{societe}/{filename}")
async def download_file(societe: str, filename: str):
    """Télécharge un fichier JSON spécifique"""
    try:
        file_path = os.path.join(BASE_FILES_DIR, societe, filename)
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Fichier non trouvé")
        
        return FileResponse(
            path=file_path,
            filename=filename,
            media_type='application/json'
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors du téléchargement: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.post("/upload/{societe}")
async def upload_file(societe: str, file: UploadFile = File(...)):
    """Upload un fichier JSON pour une société"""
    try:
        # Créer le répertoire de la société s'il n'existe pas
        societe_dir = os.path.join(BASE_FILES_DIR, societe)
        os.makedirs(societe_dir, exist_ok=True)
        
        # Vérifier que c'est un fichier JSON
        if not file.filename.endswith('.json'):
            raise HTTPException(status_code=400, detail="Seuls les fichiers JSON sont acceptés")
        
        # Sauvegarder le fichier
        file_path = os.path.join(societe_dir, file.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Notifier les clients via WebSocket
        await notify_clients({
            "type": "file_uploaded",
            "societe": societe,
            "filename": file.filename,
            "timestamp": datetime.now().isoformat()
        })
        
        return {
            "message": "Fichier uploadé avec succès",
            "societe": societe,
            "filename": file.filename,
            "size": os.path.getsize(file_path)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.post("/sync/{societe}")
async def sync_societe_files(societe: str):
    """Synchronise tous les fichiers d'une société"""
    try:
        societe_dir = os.path.join(BASE_FILES_DIR, societe)
        if not os.path.exists(societe_dir):
            raise HTTPException(status_code=404, detail=f"Société {societe} non trouvée")
        
        # Compter les fichiers
        files = [f for f in os.listdir(societe_dir) if f.endswith('.json')]
        
        # Notifier les clients
        await notify_clients({
            "type": "sync_completed",
            "societe": societe,
            "files_count": len(files),
            "timestamp": datetime.now().isoformat()
        })
        
        return {
            "message": f"Synchronisation terminée pour {societe}",
            "societe": societe,
            "files_count": len(files)
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la synchronisation: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.delete("/delete/{societe}/{filename}")
async def delete_file(societe: str, filename: str):
    """Supprime un fichier JSON"""
    try:
        file_path = os.path.join(BASE_FILES_DIR, societe, filename)
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Fichier non trouvé")
        
        os.remove(file_path)
        
        # Notifier les clients
        await notify_clients({
            "type": "file_deleted",
            "societe": societe,
            "filename": filename,
            "timestamp": datetime.now().isoformat()
        })
        
        return {"message": "Fichier supprimé avec succès"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la suppression: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@file_router.get("/status")
async def get_sync_status():
    """Récupère le statut de synchronisation"""
    try:
        if not os.path.exists(BASE_FILES_DIR):
            return {"status": "no_data", "message": "Aucune donnée disponible"}
        
        societes = [d for d in os.listdir(BASE_FILES_DIR) 
                   if os.path.isdir(os.path.join(BASE_FILES_DIR, d))]
        
        total_files = 0
        for societe in societes:
            societe_dir = os.path.join(BASE_FILES_DIR, societe)
            files = [f for f in os.listdir(societe_dir) if f.endswith('.json')]
            total_files += len(files)
        
        return {
            "status": "ready",
            "societes_count": len(societes),
            "total_files": total_files,
            "websocket_connections": len(active_connections),
            "last_update": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du statut: {e}")
        raise HTTPException(status_code=500, detail=str(e))
