# -*- coding: utf-8 -*-
import json
import os
from datetime import datetime, timedelta
from services.navision.navision_api import NavisionService

class NotificationService:
    def __init__(self):
        self.navision = NavisionService()
        self.cache_file = "data_cache.json"
        
    def get_data_summary(self):
        """Récupère un résumé des données actuelles pour chaque société"""
        summary = {}
        
        societes = {
            "rsp-bgs": "bgs_view_entry",
            "rsp-neg": "neg_view_entry", 
            "rsp-sb": "sb_view_entry"
        }
        
        for nom_societe, vue in societes.items():
            try:
                # Récupérer les données récentes (dernières 48h)
                date_limite = (datetime.now() - timedelta(days=2)).strftime('%Y-%m-%d')
                
                params = [
                    ("select", "count"),
                    ("date_ecriture", f"gte.{date_limite}")
                ]
                
                # Compter les lignes récentes
                result = self.navision.get(vue, params=params)
                count_recent = len(result) if isinstance(result, list) else 0
                
                # Récupérer la date de dernière écriture
                params_last = [
                    ("select", "date_ecriture"),
                    ("order", "date_ecriture.desc"),
                    ("limit", "1")
                ]
                
                last_entry = self.navision.get(vue, params=params_last)
                last_date = last_entry[0]['date_ecriture'] if last_entry else None
                
                summary[nom_societe] = {
                    "vue": vue,
                    "count_recent_48h": count_recent,
                    "last_entry_date": last_date,
                    "timestamp": datetime.now().isoformat()
                }
                
            except Exception as e:
                summary[nom_societe] = {
                    "vue": vue,
                    "error": str(e),
                    "timestamp": datetime.now().isoformat()
                }
        
        return summary
    
    def load_cached_summary(self):
        """Charge le résumé mis en cache"""
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                return {}
        return {}
    
    def save_summary_cache(self, summary):
        """Sauvegarde le résumé en cache"""
        with open(self.cache_file, 'w', encoding='utf-8') as f:
            json.dump(summary, f, indent=2, ensure_ascii=False)
    
    def check_for_updates(self):
        """Vérifie s'il y a de nouvelles données depuis la dernière vérification"""
        current_summary = self.get_data_summary()
        cached_summary = self.load_cached_summary()
        
        notifications = []
        
        for societe, current_data in current_summary.items():
            if 'error' in current_data:
                continue
                
            cached_data = cached_summary.get(societe, {})
            
            # Vérifier s'il y a de nouvelles entrées
            current_count = current_data.get('count_recent_48h', 0)
            cached_count = cached_data.get('count_recent_48h', 0)
            
            current_last_date = current_data.get('last_entry_date')
            cached_last_date = cached_data.get('last_entry_date')
            
            # Nouvelles données détectées
            if current_count > cached_count:
                notifications.append({
                    "type": "new_data",
                    "societe": societe,
                    "message": f"Nouvelles données détectées pour {societe}",
                    "details": {
                        "nouvelles_entrees": current_count - cached_count,
                        "total_recent": current_count,
                        "derniere_date": current_last_date
                    },
                    "timestamp": datetime.now().isoformat(),
                    "priority": "high"
                })
            
            # Nouvelle date de dernière écriture
            elif current_last_date != cached_last_date and current_last_date:
                notifications.append({
                    "type": "data_update", 
                    "societe": societe,
                    "message": f"Mise à jour des données pour {societe}",
                    "details": {
                        "ancienne_date": cached_last_date,
                        "nouvelle_date": current_last_date
                    },
                    "timestamp": datetime.now().isoformat(),
                    "priority": "medium"
                })
        
        # Sauvegarder le nouveau résumé
        self.save_summary_cache(current_summary)
        
        return {
            "has_updates": len(notifications) > 0,
            "notifications": notifications,
            "summary": current_summary,
            "check_timestamp": datetime.now().isoformat()
        }
    
    def get_data_freshness(self):
        """Retourne l'âge des données pour chaque société"""
        summary = self.get_data_summary()
        freshness = {}
        
        for societe, data in summary.items():
            if 'error' in data:
                freshness[societe] = {"status": "error", "message": data['error']}
                continue
                
            last_date = data.get('last_entry_date')
            if not last_date:
                freshness[societe] = {"status": "no_data", "age_days": None}
                continue
            
            try:
                last_datetime = datetime.fromisoformat(last_date.replace('Z', '+00:00'))
                age_hours = (datetime.now() - last_datetime.replace(tzinfo=None)).total_seconds() / 3600
                age_days = age_hours / 24
                
                if age_days < 1:
                    status = "fresh"  # Moins de 24h
                elif age_days < 7:
                    status = "recent"  # Moins d'une semaine
                else:
                    status = "old"  # Plus d'une semaine
                
                freshness[societe] = {
                    "status": status,
                    "age_hours": round(age_hours, 1),
                    "age_days": round(age_days, 1),
                    "last_entry": last_date
                }
                
            except Exception as e:
                freshness[societe] = {"status": "error", "message": f"Erreur parsing date: {str(e)}"}
        
        return freshness
