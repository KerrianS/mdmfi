#!/usr/bin/env python3
"""
Script de test pour le Web Service Relay
Ce script démontre comment utiliser l'API pour synchroniser les fichiers JSON
"""

import asyncio
import websockets
import json
import requests
import os
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
WS_URL = "ws://localhost:8000/api/files/ws"

class RelayClient:
    def __init__(self, base_url: str, ws_url: str):
        self.base_url = base_url
        self.ws_url = ws_url
        self.websocket = None
        
    async def connect_websocket(self):
        """Se connecte au WebSocket pour recevoir les notifications"""
        try:
            self.websocket = await websockets.connect(self.ws_url)
            print("✅ Connecté au WebSocket Relay")
            
            # Écouter les messages
            async for message in self.websocket:
                data = json.loads(message)
                print(f"📡 Notification reçue: {data}")
                
        except Exception as e:
            print(f"❌ Erreur WebSocket: {e}")
    
    def get_societes(self):
        """Récupère la liste des sociétés"""
        try:
            response = requests.get(f"{self.base_url}/api/files/societes")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Erreur lors de la récupération des sociétés: {e}")
            return None
    
    def get_societe_files(self, societe: str):
        """Récupère les fichiers d'une société"""
        try:
            response = requests.get(f"{self.base_url}/api/files/societe/{societe}/files")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Erreur lors de la récupération des fichiers: {e}")
            return None
    
    def download_file(self, societe: str, filename: str, save_path: str):
        """Télécharge un fichier JSON"""
        try:
            response = requests.get(f"{self.base_url}/api/files/download/{societe}/{filename}")
            response.raise_for_status()
            
            # Créer le répertoire de destination
            os.makedirs(os.path.dirname(save_path), exist_ok=True)
            
            # Sauvegarder le fichier
            with open(save_path, 'wb') as f:
                f.write(response.content)
            
            print(f"✅ Fichier téléchargé: {save_path}")
            return True
        except Exception as e:
            print(f"❌ Erreur lors du téléchargement: {e}")
            return False
    
    def upload_file(self, societe: str, file_path: str):
        """Upload un fichier JSON"""
        try:
            with open(file_path, 'rb') as f:
                files = {'file': (os.path.basename(file_path), f, 'application/json')}
                response = requests.post(f"{self.base_url}/api/files/upload/{societe}", files=files)
                response.raise_for_status()
                
            result = response.json()
            print(f"✅ Fichier uploadé: {result}")
            return result
        except Exception as e:
            print(f"❌ Erreur lors de l'upload: {e}")
            return None
    
    def sync_societe(self, societe: str):
        """Synchronise une société"""
        try:
            response = requests.post(f"{self.base_url}/api/files/sync/{societe}")
            response.raise_for_status()
            result = response.json()
            print(f"✅ Synchronisation terminée: {result}")
            return result
        except Exception as e:
            print(f"❌ Erreur lors de la synchronisation: {e}")
            return None
    
    def get_status(self):
        """Récupère le statut du relay"""
        try:
            response = requests.get(f"{self.base_url}/api/files/status")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"❌ Erreur lors de la récupération du statut: {e}")
            return None

async def main():
    """Fonction principale de test"""
    client = RelayClient(BASE_URL, WS_URL)
    
    print("🚀 Test du Web Service Relay")
    print("=" * 50)
    
    # 1. Vérifier le statut
    print("\n1. Vérification du statut...")
    status = client.get_status()
    if status:
        print(f"📊 Statut: {status}")
    
    # 2. Récupérer les sociétés
    print("\n2. Récupération des sociétés...")
    societes = client.get_societes()
    if societes and societes.get('societes'):
        print(f"🏢 Sociétés disponibles: {societes['societes']}")
        
        # 3. Pour chaque société, récupérer les fichiers
        for societe in societes['societes']:
            print(f"\n3. Fichiers pour {societe}...")
            files = client.get_societe_files(societe)
            if files and files.get('files'):
                print(f"📁 {len(files['files'])} fichiers trouvés:")
                for file_info in files['files']:
                    print(f"   - {file_info['filename']} ({file_info['size']} bytes)")
                    
                    # 4. Télécharger un exemple de fichier
                    save_path = f"downloads/{societe}/{file_info['filename']}"
                    client.download_file(societe, file_info['filename'], save_path)
                    break  # Un seul fichier par société pour l'exemple
    else:
        print("⚠️ Aucune société trouvée")
    
    # 5. Démarrer l'écoute WebSocket
    print("\n5. Démarrage de l'écoute WebSocket...")
    print("📡 En attente de notifications (Ctrl+C pour arrêter)...")
    
    try:
        await client.connect_websocket()
    except KeyboardInterrupt:
        print("\n👋 Arrêt du client")

if __name__ == "__main__":
    print("🔧 Script de test du Web Service Relay")
    print("Assurez-vous que le serveur est démarré sur http://localhost:8000")
    print()
    
    # Test synchrone
    client = RelayClient(BASE_URL, WS_URL)
    
    # Vérifier si le serveur est accessible
    try:
        response = requests.get(f"{BASE_URL}/")
        if response.status_code == 200:
            print("✅ Serveur accessible")
        else:
            print("❌ Serveur non accessible")
            exit(1)
    except Exception as e:
        print(f"❌ Impossible de se connecter au serveur: {e}")
        exit(1)
    
    # Lancer le test asynchrone
    asyncio.run(main()) 