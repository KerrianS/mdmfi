# -*- coding: utf-8 -*-
import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, Any
from controllers.navision_sig_controller import NavisionSIGController
from websocket.websocket_manager import websocket_manager

logger = logging.getLogger(__name__)

class DataChangeDetector:
    """
    Détecteur de changements dans les données comptables
    """
    
    def __init__(self):
        self.last_check = {}  # Dernière vérification par société
        self.data_signatures = {}  # Signatures des données pour détecter les changements
        self.check_interval = 300  # 5 minutes
        self.is_running = False
        
    def calculate_data_signature(self, lignes: list) -> str:
        """Calculer une signature des données pour détecter les changements"""
        if not lignes:
            return "empty"
            
        # Signature basée sur le nombre de lignes et la somme des montants
        total_lines = len(lignes)
        total_amount = sum(l.get('montant', 0) for l in lignes)
        latest_date = max((l.get('date_ecriture', '') for l in lignes), default='')
        
        signature = f"{total_lines}_{total_amount:.2f}_{latest_date}"
        return signature
    
    async def check_for_new_data(self, societe: str, vue: str) -> Dict[str, Any]:
        """Vérifier s'il y a de nouvelles données pour une société"""
        try:
            controller = NavisionSIGController(vue)
            lignes = controller.get_lines("annee")
            
            new_signature = self.calculate_data_signature(lignes)
            old_signature = self.data_signatures.get(societe, "")
            
            if new_signature != old_signature:
                self.data_signatures[societe] = new_signature
                
                # Analyser les changements
                total_lines = len(lignes)
                annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)
                latest_year = annees[0] if annees else None
                
                return {
                    "has_changes": True,
                    "societe": societe,
                    "total_lignes": total_lines,
                    "annees_disponibles": annees[:3],  # 3 dernières années
                    "derniere_annee": latest_year,
                    "signature": new_signature,
                    "timestamp": datetime.now().isoformat()
                }
            
            return {"has_changes": False, "societe": societe}
            
        except Exception as e:
            logger.error(f"Erreur vérification données {societe}: {e}")
            return {"has_changes": False, "societe": societe, "error": str(e)}
    
    async def check_all_societies(self):
        """Vérifier toutes les sociétés pour des changements"""
        societes = {
            "rsp-bgs": "bgs_view_entry",
            "rsp-neg": "neg_view_entry", 
            "rsp-sb": "sb_view_entry"
        }
        
        changes_detected = []
        
        for nom_societe, vue in societes.items():
            result = await self.check_for_new_data(nom_societe, vue)
            if result.get("has_changes"):
                changes_detected.append(result)
        
        return changes_detected
    
    async def notify_changes(self, changes: list):
        """Envoyer les notifications de changements via WebSocket"""
        if not changes:
            return
            
        for change in changes:
            notification = {
                "type": "data_update",
                "category": "comptabilite",
                "title": f"Nouvelles données - {change['societe'].upper()}",
                "message": f"Nouvelles données comptables détectées pour {change['societe']}",
                "data": {
                    "societe": change['societe'],
                    "total_lignes": change.get('total_lignes', 0),
                    "annees": change.get('annees_disponibles', []),
                    "derniere_annee": change.get('derniere_annee')
                },
                "priority": "normal",
                "timestamp": change.get('timestamp')
            }
            
            # Diffuser la notification
            await websocket_manager.broadcast_to_all(notification)
            logger.info(f"Notification envoyée pour {change['societe']}")
    
    async def monitoring_loop(self):
        """Boucle principale de monitoring"""
        logger.info("Démarrage du monitoring des données")
        self.is_running = True
        
        while self.is_running:
            try:
                # Vérifier les changements
                changes = await self.check_all_societies()
                
                if changes:
                    logger.info(f"Changements détectés: {len(changes)} société(s)")
                    await self.notify_changes(changes)
                else:
                    logger.debug("Aucun changement détecté")
                
                # Attendre avant la prochaine vérification
                await asyncio.sleep(self.check_interval)
                
            except Exception as e:
                logger.error(f"Erreur dans la boucle de monitoring: {e}")
                await asyncio.sleep(60)  # Attendre 1 minute en cas d'erreur
    
    def start_monitoring(self):
        """Démarrer le monitoring en arrière-plan"""
        if not self.is_running:
            asyncio.create_task(self.monitoring_loop())
    
    def stop_monitoring(self):
        """Arrêter le monitoring"""
        self.is_running = False
        logger.info("Arrêt du monitoring des données")
    
    async def force_check(self) -> Dict[str, Any]:
        """Forcer une vérification manuelle"""
        logger.info("Vérification forcée des données")
        changes = await self.check_all_societies()
        
        if changes:
            await self.notify_changes(changes)
            return {
                "status": "success",
                "changes_found": len(changes),
                "details": changes
            }
        else:
            return {
                "status": "no_changes",
                "message": "Aucune nouvelle donnée détectée"
            }

# Instance globale du détecteur
data_detector = DataChangeDetector()
