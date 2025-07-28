# -*- coding: utf-8 -*-
import os
import jwt
import requests
from typing import Optional, Dict, List
from dotenv import load_dotenv
import logging

load_dotenv()
logger = logging.getLogger(__name__)

class KeycloakService:
    """
    Service d'authentification Keycloak pour le backend
    """
    
    def __init__(self):
        self.keycloak_url = os.getenv("KEYCLOAK_URL", "https://api.client.aitecservice.com/api/keycloak")
        self.realm = os.getenv("KEYCLOAK_REALM", "master")
        self.client_id = os.getenv("KEYCLOAK_CLIENT_ID", "mdm-fi")
        
    async def verify_token(self, token: str) -> Optional[Dict]:
        """
        Vérifie un token JWT Keycloak et retourne les informations utilisateur
        """
        try:
            # Décoder le token sans vérification de signature pour l'instant
            # En production, il faudrait vérifier avec la clé publique Keycloak
            decoded_token = jwt.decode(token, options={"verify_signature": False})
            
            logger.info(f"Token décodé pour utilisateur: {decoded_token.get('preferred_username')}")
            
            return {
                'username': decoded_token.get('preferred_username'),
                'email': decoded_token.get('email'),
                'name': decoded_token.get('name'),
                'groups': decoded_token.get('groups', []),
                'realm_access': decoded_token.get('realm_access', {}),
                'resource_access': decoded_token.get('resource_access', {}),
                'sub': decoded_token.get('sub'),
                'exp': decoded_token.get('exp')
            }
            
        except jwt.ExpiredSignatureError:
            logger.warning("Token expiré")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Token invalide: {e}")
            return None
        except Exception as e:
            logger.error(f"Erreur lors de la vérification du token: {e}")
            return None
    
    async def get_user_info(self, token: str) -> Optional[Dict]:
        """
        Récupère les informations utilisateur via l'API Keycloak
        """
        try:
            headers = {
                'Authorization': f'Bearer {token}',
                'Content-Type': 'application/json'
            }
            
            response = requests.get(
                f"{self.keycloak_url}/userinfo",
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    return data.get('data')
            
            logger.warning(f"Échec récupération userinfo: {response.status_code}")
            return None
            
        except Exception as e:
            logger.error(f"Erreur lors de la récupération des infos utilisateur: {e}")
            return None
    
    def get_user_permissions(self, user_info: Dict) -> Dict[str, bool]:
        """
        Extrait les permissions utilisateur à partir des infos Keycloak
        """
        permissions = {
            'is_admin': False,
            'is_comptable': False,
            'is_direction': False,
            'can_force_check': False,
            'can_broadcast': False,
            'has_mdm_fi': False
        }
        
        try:
            # Vérifier les rôles realm
            realm_roles = user_info.get('realm_access', {}).get('roles', [])
            
            # Vérifier les rôles de ressource
            resource_roles = []
            resource_access = user_info.get('resource_access', {})
            for resource, access in resource_access.items():
                resource_roles.extend(access.get('roles', []))
            
            all_roles = realm_roles + resource_roles
            
            # Déterminer les permissions
            permissions['has_mdm_fi'] = 'MDM-Fi' in all_roles
            permissions['is_admin'] = 'permissions-admin' in all_roles
            permissions['is_comptable'] = any('comptab' in role.lower() for role in all_roles)
            permissions['is_direction'] = any('direction' in role.lower() for role in all_roles)
            
            # Permissions dérivées
            permissions['can_force_check'] = permissions['is_admin'] or permissions['is_direction'] or permissions['is_comptable']
            permissions['can_broadcast'] = permissions['is_admin']
            
            logger.info(f"Permissions calculées pour {user_info.get('preferred_username')}: {permissions}")
            
        except Exception as e:
            logger.error(f"Erreur lors du calcul des permissions: {e}")
        
        return permissions
    
    def get_client_type_from_permissions(self, permissions: Dict[str, bool]) -> str:
        """
        Détermine le type de client à partir des permissions
        """
        if permissions.get('is_admin'):
            return 'dashboard'  # Admin a accès complet
        elif permissions.get('is_direction'):
            return 'direction'
        elif permissions.get('is_comptable'):
            return 'comptable'
        else:
            return 'mobile'  # Client basique
    
    async def authenticate_websocket(self, token: str) -> Optional[Dict]:
        """
        Authentifie un token pour une connexion WebSocket et retourne les infos complètes
        """
        if not token:
            return None
        
        # Nettoyer le token (enlever "Bearer " si présent)
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Vérifier le token
        user_info = await self.verify_token(token)
        if not user_info:
            # Fallback: essayer via l'API
            user_info = await self.get_user_info(token)
        
        if not user_info:
            return None
        
        # Calculer les permissions
        permissions = self.get_user_permissions(user_info)
        
        # Vérifier que l'utilisateur a accès à MDM-Fi
        if not permissions.get('has_mdm_fi'):
            logger.warning(f"Utilisateur {user_info.get('preferred_username')} n'a pas accès à MDM-Fi")
            return None
        
        # Déterminer le type de client
        client_type = self.get_client_type_from_permissions(permissions)
        
        return {
            'user_info': user_info,
            'permissions': permissions,
            'client_type': client_type,
            'username': user_info.get('preferred_username'),
            'email': user_info.get('email')
        }

# Instance globale
keycloak_service = KeycloakService()
