# -*- coding: utf-8 -*-
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException, Query
from fastapi.responses import HTMLResponse
from websocket.websocket_manager import websocket_manager
from websocket.data_detector import data_detector
import json
import logging

logger = logging.getLogger(__name__)

websocket_router = APIRouter(prefix="/ws", tags=["WebSocket"])

@websocket_router.websocket("/connect")
async def websocket_endpoint(
    websocket: WebSocket, 
    token: str = Query(None), 
    client_type: str = Query(None), 
    client_id: str = Query(None)
):
    """
    Point d'entrée WebSocket principal avec authentification Keycloak
    """
    # Connecter avec authentification
    success = await websocket_manager.connect(websocket, token, client_type, client_id)
    if not success:
        return  # Connexion fermée par l'authentification
    
    # Déterminer le type de client final
    user_info = websocket_manager.get_user_info(websocket)
    final_client_type = user_info['client_type'] if user_info else (client_type or "mobile")
    
    try:
        while True:
            # Écouter les messages du client
            data = await websocket.receive_text()
            
            try:
                message = json.loads(data)
                await handle_client_message(websocket, message, final_client_type)
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Format de message invalide"
                }))
                
    except WebSocketDisconnect:
        websocket_manager.disconnect(websocket, final_client_type)
        username = user_info['username'] if user_info else "Anonyme"
        logger.info(f"Client {final_client_type} déconnecté - Utilisateur: {username}")

async def handle_client_message(websocket: WebSocket, message: dict, client_type: str):
    """Traiter les messages reçus des clients"""
    message_type = message.get("type")
    
    if message_type == "ping":
        # Répondre au ping
        await websocket.send_text(json.dumps({
            "type": "pong",
            "timestamp": message.get("timestamp")
        }))
        
    elif message_type == "subscribe":
        # Abonnement à des notifications spécifiques
        categories = message.get("categories", [])
        await websocket.send_text(json.dumps({
            "type": "subscribed",
            "categories": categories,
            "message": f"Abonné aux catégories: {', '.join(categories)}"
        }))
        
    elif message_type == "force_check":
        # Forcer une vérification des données (permission requise)
        if websocket_manager.has_permission(websocket, "can_force_check"):
            result = await data_detector.force_check()
            await websocket.send_text(json.dumps({
                "type": "force_check_result",
                "result": result
            }))
        else:
            await websocket.send_text(json.dumps({
                "type": "error",
                "message": "Permission refusée pour force_check - Rôle requis: admin, direction ou comptable"
            }))
    
    elif message_type == "get_user_info":
        # Retourner les informations utilisateur
        user_info = websocket_manager.get_user_info(websocket)
        if user_info:
            await websocket.send_text(json.dumps({
                "type": "user_info",
                "username": user_info['username'],
                "email": user_info['email'],
                "client_type": user_info['client_type'],
                "permissions": user_info['permissions']
            }))
        else:
            await websocket.send_text(json.dumps({
                "type": "user_info",
                "message": "Utilisateur non authentifié"
            }))

@websocket_router.get("/stats")
async def get_websocket_stats():
    """Obtenir les statistiques des connexions WebSocket"""
    return websocket_manager.get_connection_stats()

@websocket_router.post("/broadcast")
async def broadcast_message(message: dict, client_type: str = None, admin_token: str = None):
    """
    Diffuser un message à tous les clients ou à un type spécifique
    Nécessite un token admin valide
    """
    # Vérifier les permissions admin si token fourni
    if admin_token:
        from services.keycloak_service import keycloak_service
        auth_info = await keycloak_service.authenticate_websocket(admin_token)
        if not auth_info or not auth_info['permissions'].get('can_broadcast'):
            raise HTTPException(status_code=403, detail="Permission insuffisante pour broadcaster")
    
    try:
        if client_type:
            await websocket_manager.broadcast_to_type(message, client_type)
            return {"status": "success", "sent_to": client_type}
        else:
            await websocket_manager.broadcast_to_all(message)
            return {"status": "success", "sent_to": "all"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@websocket_router.post("/notify/data-update")
async def notify_data_update(societe: str, details: dict = None):
    """
    Envoyer une notification de mise à jour de données
    """
    notification = {
        "type": "data_update",
        "category": "comptabilite",
        "title": f"Données mises à jour - {societe.upper()}",
        "message": f"Les données comptables de {societe} ont été mises à jour",
        "data": details or {},
        "priority": "normal"
    }
    
    await websocket_manager.broadcast_to_all(notification)
    return {"status": "notification sent", "societe": societe}

@websocket_router.post("/start-monitoring")
async def start_data_monitoring():
    """Démarrer le monitoring automatique des données"""
    data_detector.start_monitoring()
    return {"status": "monitoring started", "interval": f"{data_detector.check_interval}s"}

@websocket_router.post("/stop-monitoring")
async def stop_data_monitoring():
    """Arrêter le monitoring automatique des données"""
    data_detector.stop_monitoring()
    return {"status": "monitoring stopped"}

@websocket_router.post("/force-check")
async def force_data_check():
    """Forcer une vérification immédiate des données"""
    result = await data_detector.force_check()
    return result

@websocket_router.post("/verify-token")
async def verify_keycloak_token(token: str):
    """
    Vérifier un token Keycloak et retourner les informations utilisateur
    """
    from services.keycloak_service import keycloak_service
    
    try:
        auth_info = await keycloak_service.authenticate_websocket(token)
        if auth_info:
            return {
                "valid": True,
                "user": {
                    "username": auth_info['username'],
                    "email": auth_info['email'],
                    "client_type": auth_info['client_type'],
                    "permissions": auth_info['permissions']
                }
            }
        else:
            return {"valid": False, "error": "Token invalide ou expiré"}
    except Exception as e:
        return {"valid": False, "error": str(e)}

@websocket_router.get("/connected-users")
async def get_connected_users():
    """
    Obtenir la liste des utilisateurs connectés (admin uniquement)
    """
    connections = websocket_manager.connection_users
    users = []
    
    for websocket, user_info in connections.items():
        users.append({
            "username": user_info.get('username', 'Anonyme'),
            "email": user_info.get('email'),
            "client_type": user_info.get('client_type'),
            "permissions": user_info.get('permissions', {}),
            "connected_since": user_info.get('connected_at', 'Inconnu')
        })
    
    return {
        "total_users": len(users),
        "users": users,
        "connection_stats": websocket_manager.get_connection_stats()
    }

@websocket_router.get("/test")
async def websocket_test_page():
    """Page de test pour les WebSockets avec authentification Keycloak"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>WebSocket Test - MDM-FI (Keycloak Auth)</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            #messages { border: 1px solid #ccc; height: 400px; overflow-y: scroll; padding: 10px; margin: 10px 0; }
            .message { margin: 5px 0; padding: 5px; background-color: #f5f5f5; border-radius: 3px; }
            .notification { background-color: #e7f3ff; border-left: 4px solid #007cba; }
            .error { background-color: #ffe7e7; border-left: 4px solid #dc3545; }
            .success { background-color: #e7ffe7; border-left: 4px solid #28a745; }
            input, button, select { margin: 5px; padding: 8px; }
            button { background-color: #007cba; color: white; border: none; border-radius: 3px; cursor: pointer; }
            button:hover { background-color: #005a87; }
            .auth-section { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
            .user-info { background-color: #d1ecf1; padding: 10px; border-radius: 5px; margin: 10px 0; }
            textarea { width: 400px; height: 80px; }
        </style>
    </head>
    <body>
        <h1>WebSocket Test - MDM-FI avec Authentification Keycloak</h1>
        
        <div class="auth-section">
            <h3>Authentification</h3>
            <div>
                <label>Token Keycloak (JWT):</label><br>
                <textarea id="keycloakToken" placeholder="Collez votre token JWT ici..."></textarea>
            </div>
            <div>
                <label>Type de client (optionnel, déterminé automatiquement par Keycloak):</label>
                <select id="clientType">
                    <option value="">Auto (via Keycloak)</option>
                    <option value="dashboard">Dashboard</option>
                    <option value="direction">Direction</option>
                    <option value="comptable">Comptable</option>
                    <option value="mobile">Mobile</option>
                </select>
            </div>
            <div>
                <button onclick="connect()">Se connecter</button>
                <button onclick="connectAnonymous()">Connexion anonyme</button>
                <button onclick="disconnect()">Se déconnecter</button>
                <span id="status">Déconnecté</span>
            </div>
        </div>
        
        <div id="userInfo" class="user-info" style="display: none;">
            <h4>Informations utilisateur</h4>
            <div id="userDetails"></div>
        </div>
        
        <div>
            <h3>Actions</h3>
            <button onclick="ping()">Ping</button>
            <button onclick="subscribe()">S'abonner</button>
            <button onclick="getUserInfo()">Info utilisateur</button>
            <button onclick="forceCheck()">Vérification forcée</button>
            <button onclick="clearMessages()">Effacer messages</button>
        </div>
        
        <div id="messages"></div>
        
        <script>
            let ws = null;
            const messages = document.getElementById('messages');
            const status = document.getElementById('status');
            const userInfo = document.getElementById('userInfo');
            const userDetails = document.getElementById('userDetails');
            
            function connect() {
                const token = document.getElementById('keycloakToken').value.trim();
                const clientType = document.getElementById('clientType').value;
                
                if (!token) {
                    addMessage('Erreur: Token Keycloak requis pour l\'authentification', 'error');
                    return;
                }
                
                // Construire l'URL avec les paramètres
                let wsUrl = 'ws://localhost:8000/ws/connect?token=' + encodeURIComponent(token);
                if (clientType) {
                    wsUrl += '&client_type=' + clientType;
                }
                
                ws = new WebSocket(wsUrl);
                
                ws.onopen = function(event) {
                    status.textContent = 'Connecté (Authentifié)';
                    status.style.color = 'green';
                    addMessage('Connexion WebSocket authentifiée établie', 'success');
                    
                    // Demander les infos utilisateur automatiquement
                    setTimeout(() => getUserInfo(), 500);
                };
                
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    
                    if (data.type === 'user_info') {
                        displayUserInfo(data);
                    } else {
                        addMessage('Reçu: ' + JSON.stringify(data, null, 2), 
                                  data.type === 'data_update' ? 'notification' : 'message');
                    }
                };
                
                ws.onclose = function(event) {
                    status.textContent = 'Déconnecté (Code: ' + event.code + ')';
                    status.style.color = 'red';
                    userInfo.style.display = 'none';
                    
                    if (event.code === 4001) {
                        addMessage('Connexion refusée: Échec d\'authentification Keycloak', 'error');
                    } else {
                        addMessage('Connexion fermée', 'info');
                    }
                };
                
                ws.onerror = function(error) {
                    addMessage('Erreur WebSocket: ' + error, 'error');
                };
            }
            
            function connectAnonymous() {
                const clientType = document.getElementById('clientType').value || 'mobile';
                ws = new WebSocket(`ws://localhost:8000/ws/connect?client_type=${clientType}`);
                
                ws.onopen = function(event) {
                    status.textContent = 'Connecté (Anonyme - ' + clientType + ')';
                    status.style.color = 'orange';
                    addMessage('Connexion WebSocket anonyme établie', 'info');
                };
                
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    addMessage('Reçu: ' + JSON.stringify(data, null, 2), 
                              data.type === 'data_update' ? 'notification' : 'message');
                };
                
                ws.onclose = function(event) {
                    status.textContent = 'Déconnecté';
                    status.style.color = 'red';
                    addMessage('Connexion fermée', 'info');
                };
                
                ws.onerror = function(error) {
                    addMessage('Erreur: ' + error, 'error');
                };
            }
            
            function disconnect() {
                if (ws) {
                    ws.close();
                }
            }
            
            function ping() {
                if (ws) {
                    ws.send(JSON.stringify({
                        type: 'ping',
                        timestamp: new Date().toISOString()
                    }));
                }
            }
            
            function subscribe() {
                if (ws) {
                    ws.send(JSON.stringify({
                        type: 'subscribe',
                        categories: ['comptabilite', 'system']
                    }));
                }
            }
            
            function getUserInfo() {
                if (ws) {
                    ws.send(JSON.stringify({
                        type: 'get_user_info'
                    }));
                }
            }
            
            function forceCheck() {
                if (ws) {
                    ws.send(JSON.stringify({
                        type: 'force_check'
                    }));
                }
            }
            
            function clearMessages() {
                messages.innerHTML = '';
            }
            
            function displayUserInfo(data) {
                if (data.username) {
                    userDetails.innerHTML = `
                        <strong>Utilisateur:</strong> ${data.username}<br>
                        <strong>Email:</strong> ${data.email || 'N/A'}<br>
                        <strong>Type de client:</strong> ${data.client_type}<br>
                        <strong>Permissions:</strong><br>
                        ${Object.entries(data.permissions || {}).map(([key, value]) => 
                            `&nbsp;&nbsp;• ${key}: ${value ? '✅' : '❌'}`
                        ).join('<br>')}
                    `;
                    userInfo.style.display = 'block';
                } else {
                    userDetails.innerHTML = '<em>Utilisateur non authentifié</em>';
                    userInfo.style.display = 'block';
                }
            }
            
            function addMessage(message, type = 'message') {
                const div = document.createElement('div');
                div.className = 'message ' + type;
                div.innerHTML = '<strong>' + new Date().toLocaleTimeString() + '</strong><br>' + 
                               (typeof message === 'string' ? message : JSON.stringify(message, null, 2));
                messages.appendChild(div);
                messages.scrollTop = messages.scrollHeight;
            }
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)
