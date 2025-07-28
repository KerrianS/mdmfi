# -*- coding: utf-8 -*-
from fastapi import APIRouter, BackgroundTasks
from services.notification_service import NotificationService
from typing import Optional
import asyncio

notification_router = APIRouter()
notification_service = NotificationService()

@notification_router.get("/notifications/check", tags=["Notifications"])
def check_data_updates():
    """
    Vérifie s'il y a de nouvelles données depuis la dernière vérification
    """
    result = notification_service.check_for_updates()
    return result

@notification_router.get("/notifications/freshness", tags=["Notifications"])
def get_data_freshness():
    """
    Retourne l'âge des données pour chaque société
    """
    freshness = notification_service.get_data_freshness()
    return {
        "freshness": freshness,
        "check_timestamp": notification_service.get_data_summary()
    }

@notification_router.get("/notifications/summary", tags=["Notifications"])
def get_data_summary():
    """
    Retourne un résumé des données actuelles
    """
    summary = notification_service.get_data_summary()
    return {
        "summary": summary,
        "cached": notification_service.load_cached_summary()
    }

@notification_router.post("/notifications/reset-cache", tags=["Notifications"])
def reset_notification_cache():
    """
    Remet à zéro le cache des notifications (force la détection de nouvelles données)
    """
    import os
    if os.path.exists(notification_service.cache_file):
        os.remove(notification_service.cache_file)
    return {"message": "Cache de notifications remis à zéro"}

@notification_router.get("/notifications/status", tags=["Notifications"])
def get_notification_status():
    """
    Retourne le statut global des notifications et des données
    """
    summary = notification_service.get_data_summary()
    freshness = notification_service.get_data_freshness()
    
    # Calculer le statut global
    total_recent = sum(data.get('count_recent_48h', 0) for data in summary.values() if 'error' not in data)
    
    fresh_count = sum(1 for f in freshness.values() if f.get('status') == 'fresh')
    recent_count = sum(1 for f in freshness.values() if f.get('status') == 'recent') 
    old_count = sum(1 for f in freshness.values() if f.get('status') == 'old')
    error_count = sum(1 for f in freshness.values() if f.get('status') == 'error')
    
    global_status = "healthy"
    if error_count > 0:
        global_status = "error"
    elif old_count > fresh_count:
        global_status = "outdated"
    elif recent_count > 0:
        global_status = "recent"
    
    return {
        "global_status": global_status,
        "statistics": {
            "total_recent_entries": total_recent,
            "fresh_societies": fresh_count,
            "recent_societies": recent_count, 
            "old_societies": old_count,
            "error_societies": error_count
        },
        "details": {
            "summary": summary,
            "freshness": freshness
        }
    }

# Système de notification en temps réel (optionnel)
@notification_router.get("/notifications/watch", tags=["Notifications"])
async def watch_data_changes(interval_minutes: int = 5):
    """
    Surveille les changements de données en continu
    (pour usage avec WebSocket ou Server-Sent Events)
    """
    notifications_history = []
    
    while True:
        result = notification_service.check_for_updates()
        
        if result["has_updates"]:
            notifications_history.extend(result["notifications"])
            # Garder seulement les 50 dernières notifications
            notifications_history = notifications_history[-50:]
        
        # Retourner les notifications récentes
        yield {
            "timestamp": result["check_timestamp"],
            "has_new_updates": result["has_updates"],
            "recent_notifications": result["notifications"],
            "history": notifications_history[-10:],  # 10 dernières
            "next_check_in": f"{interval_minutes} minutes"
        }
        
        # Attendre avant la prochaine vérification
        await asyncio.sleep(interval_minutes * 60)
