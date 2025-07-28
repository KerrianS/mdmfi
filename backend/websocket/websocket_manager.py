# -*- coding: utf-8 -*-
import json
import asyncio
from typing import Dict, List, Set, Optional
from fastapi import WebSocket
from datetime import datetime
import logging
from services.keycloak_service import keycloak_service

logger = logging.getLogger(__name__)

class WebSocketManager:
    """
    WebSocket Relay Manager - Gère les connexions et diffuse les notifications
    """
    
    def __init__(self):
        # Connexions actives par type de client avec informations utilisateur
        self.active_connections: Dict[str, Set[WebSocket]] = {
            "dashboard": set(),
            "direction": set(),
            "comptable": set(),
            "mobile": set()
        }
        
        # Stockage des informations utilisateur par connexion
        self.connection_users: Dict[WebSocket, Dict] = {}
        
        # Stockage des dernières notifications
        self.recent_notifications: List[dict] = []
        self.max_notifications = 100
        
    async def connect(self, websocket: WebSocket, token: str = None, client_type: str = None, client_id: str = None):
        """Accepter une nouvelle connexion WebSocket avec authentification Keycloak"""
        
        # Authentifier via Keycloak si un token est fourni
        auth_info = None
        if token:
            auth_info = await keycloak_service.authenticate_websocket(token)
            if not auth_info:
                await websocket.close(code=4001, reason="Authentication failed")
                logger.warning("Connexion refusée: échec d'authentification")
                return False
            
            # Utiliser le type de client déterminé par Keycloak si pas spécifié
            if not client_type:
                client_type = auth_info['client_type']
        
        # Type de client par défaut si pas d'authentification
        if not client_type:
            client_type = "mobile"
            
        await websocket.accept()
        
        if client_type not in self.active_connections:
            self.active_connections[client_type] = set()
            
        self.active_connections[client_type].add(websocket)
        
        # Stocker les informations utilisateur
        if auth_info:
            auth_info['connected_at'] = datetime.now().isoformat()
            self.connection_users[websocket] = auth_info
            logger.info(f"Client {client_type} connecté - Utilisateur: {auth_info['username']}")
        else:
            logger.info(f"Client {client_type} connecté - Anonyme")
            
        logger.info(f"Total connexions {client_type}: {len(self.active_connections[client_type])}")
        
        # Envoyer les notifications récentes au nouveau client
        await self.send_recent_notifications(websocket)
        return True
        
    def disconnect(self, websocket: WebSocket, client_type: str = None):
        """Supprimer une connexion WebSocket"""
        # Nettoyer les informations utilisateur
        user_info = self.connection_users.pop(websocket, None)
        username = user_info['username'] if user_info else "Anonyme"
        
        # Trouver le type de client si pas fourni
        if not client_type:
            for ctype, connections in self.active_connections.items():
                if websocket in connections:
                    client_type = ctype
                    break
        
        if client_type and client_type in self.active_connections:
            self.active_connections[client_type].discard(websocket)
            logger.info(f"Client {client_type} déconnecté - Utilisateur: {username}. Restant: {len(self.active_connections[client_type])}")
        else:
            # Nettoyer de tous les types si pas trouvé
            for connections in self.active_connections.values():
                connections.discard(websocket)
    
    async def send_recent_notifications(self, websocket: WebSocket):
        """Envoyer les notifications récentes à un nouveau client"""
        try:
            for notification in self.recent_notifications[-10:]:  # 10 dernières
                await websocket.send_text(json.dumps(notification, ensure_ascii=False))
        except Exception as e:
            logger.error(f"Erreur envoi notifications récentes: {e}")
    
    def has_permission(self, websocket: WebSocket, permission: str) -> bool:
        """Vérifier si une connexion a une permission spécifique"""
        user_info = self.connection_users.get(websocket)
        if not user_info:
            return False
        
        permissions = user_info.get('permissions', {})
        return permissions.get(permission, False)
    
    def get_user_info(self, websocket: WebSocket) -> Optional[Dict]:
        """Récupérer les informations utilisateur d'une connexion"""
        return self.connection_users.get(websocket)
    
    async def broadcast_to_type(self, message: dict, client_type: str):
        """Diffuser un message à tous les clients d'un type spécifique"""
        if client_type not in self.active_connections:
            return
            
        message_str = json.dumps(message, ensure_ascii=False)
        disconnected = set()
        
        for connection in self.active_connections[client_type].copy():
            try:
                await connection.send_text(message_str)
            except Exception as e:
                logger.error(f"Erreur envoi vers {client_type}: {e}")
                disconnected.add(connection)
        
        # Nettoyer les connexions fermées
        for conn in disconnected:
            self.active_connections[client_type].discard(conn)
    
    async def broadcast_to_all(self, message: dict):
        """Diffuser un message à tous les clients connectés"""
        tasks = []
        for client_type in self.active_connections.keys():
            tasks.append(self.broadcast_to_type(message, client_type))
        
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # Stocker la notification
        self.store_notification(message)
    
    def store_notification(self, notification: dict):
        """Stocker une notification dans l'historique"""
        notification["timestamp"] = datetime.now().isoformat()
        self.recent_notifications.append(notification)
        
        # Limiter le nombre de notifications stockées
        if len(self.recent_notifications) > self.max_notifications:
            self.recent_notifications = self.recent_notifications[-self.max_notifications:]
    
    def get_connection_stats(self) -> dict:
        """Obtenir les statistiques de connexion"""
        return {
            "total_connections": sum(len(conns) for conns in self.active_connections.values()),
            "by_type": {
                client_type: len(connections) 
                for client_type, connections in self.active_connections.items()
            },
            "recent_notifications_count": len(self.recent_notifications)
        }
    
    async def ping_all_clients(self):
        """Envoyer un ping à tous les clients pour vérifier les connexions"""
        ping_message = {
            "type": "ping",
            "timestamp": datetime.now().isoformat()
        }
        await self.broadcast_to_all(ping_message)

# Instance globale du manager
websocket_manager = WebSocketManager()
