#!/usr/bin/env python3
"""
Script de génération et envoi de fichiers JSON
Ce script simule le processus côté client qui génère les fichiers JSON
et les envoie via le Web Service Relay
"""

import json
import requests
import os
import time
from datetime import datetime, timedelta
import random

# Configuration
RELAY_URL = "http://localhost:8000"
SOCIETE = "client-test"

class DataGenerator:
    def __init__(self, relay_url: str, societe: str):
        self.relay_url = relay_url
        self.societe = societe
        
    def generate_comptes_data(self, annee: str, mois: str = None):
        """Génère des données de comptes"""
        data = {
            "societe": self.societe,
            "annee": annee,
            "mois": mois,
            "type": "comptes",
            "data": {
                "comptes": [],
                "total_actif": 0,
                "total_passif": 0,
                "date_generation": datetime.now().isoformat()
            }
        }
        
        # Générer des comptes fictifs
        for i in range(10):
            compte = {
                "numero": f"6{str(i).zfill(3)}",
                "intitule": f"Compte {i+1}",
                "solde": random.uniform(1000, 100000),
                "type": "actif" if i < 5 else "passif"
            }
            data["data"]["comptes"].append(compte)
            
            if compte["type"] == "actif":
                data["data"]["total_actif"] += compte["solde"]
            else:
                data["data"]["total_passif"] += compte["solde"]
        
        return data
    
    def generate_indicateurs_data(self, annee: str, mois: str = None):
        """Génère des données d'indicateurs"""
        data = {
            "societe": self.societe,
            "annee": annee,
            "mois": mois,
            "type": "indicateurs",
            "data": {
                "indicateurs": [],
                "date_generation": datetime.now().isoformat()
            }
        }
        
        # Indicateurs financiers
        indicateurs = [
            "Ratio de liquidité",
            "Ratio de solvabilité",
            "Marge bénéficiaire",
            "ROE",
            "ROA"
        ]
        
        for indicateur in indicateurs:
            data["data"]["indicateurs"].append({
                "nom": indicateur,
                "valeur": random.uniform(0.1, 2.0),
                "unite": "%" if "ratio" in indicateur.lower() else "fois",
                "tendance": random.choice(["hausse", "baisse", "stable"])
            })
        
        return data
    
    def generate_sous_indicateurs_data(self, annee: str, mois: str = None):
        """Génère des données de sous-indicateurs"""
        data = {
            "societe": self.societe,
            "annee": annee,
            "mois": mois,
            "type": "sous_indicateurs",
            "data": {
                "sous_indicateurs": [],
                "date_generation": datetime.now().isoformat()
            }
        }
        
        # Sous-indicateurs détaillés
        sous_indicateurs = [
            "Liquidité immédiate",
            "Liquidité réduite",
            "Solvabilité générale",
            "Solvabilité restreinte",
            "Rentabilité économique"
        ]
        
        for sous_indicateur in sous_indicateurs:
            data["data"]["sous_indicateurs"].append({
                "nom": sous_indicateur,
                "valeur": random.uniform(0.5, 3.0),
                "seuil_alerte": 1.0,
                "seuil_critique": 0.5,
                "statut": random.choice(["normal", "alerte", "critique"])
            })
        
        return data
    
    def save_json_file(self, data: dict, filename: str):
        """Sauvegarde les données en fichier JSON"""
        os.makedirs("generated_files", exist_ok=True)
        file_path = os.path.join("generated_files", filename)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Fichier généré: {file_path}")
        return file_path
    
    def upload_to_relay(self, file_path: str):
        """Upload le fichier vers le relay"""
        try:
            with open(file_path, 'rb') as f:
                files = {'file': (os.path.basename(file_path), f, 'application/json')}
                response = requests.post(f"{self.relay_url}/api/files/upload/{self.societe}", files=files)
                response.raise_for_status()
                
            result = response.json()
            print(f"✅ Fichier uploadé vers le relay: {result}")
            return result
        except Exception as e:
            print(f"❌ Erreur lors de l'upload: {e}")
            return None
    
    def generate_and_upload_all(self, annee: str):
        """Génère et upload tous les types de données pour une année"""
        print(f"🚀 Génération des données pour {annee}...")
        
        # 1. Comptes annuels
        comptes_data = self.generate_comptes_data(annee)
        comptes_file = self.save_json_file(comptes_data, f"comptes_global_annee_{annee}.json")
        self.upload_to_relay(comptes_file)
        
        # 2. Indicateurs annuels
        indicateurs_data = self.generate_indicateurs_data(annee)
        indicateurs_file = self.save_json_file(indicateurs_data, f"indicateurs_global_annee_{annee}.json")
        self.upload_to_relay(indicateurs_file)
        
        # 3. Sous-indicateurs annuels
        sous_indicateurs_data = self.generate_sous_indicateurs_data(annee)
        sous_indicateurs_file = self.save_json_file(sous_indicateurs_data, f"sous_indicateurs_global_annee_{annee}.json")
        self.upload_to_relay(sous_indicateurs_file)
        
        # 4. Données mensuelles pour chaque mois
        for mois in range(1, 13):
            mois_str = str(mois).zfill(2)
            
            # Comptes mensuels
            comptes_mensuel = self.generate_comptes_data(annee, mois_str)
            comptes_mensuel_file = self.save_json_file(comptes_mensuel, f"comptes_mensuel_{annee}_{mois_str}.json")
            self.upload_to_relay(comptes_mensuel_file)
            
            # Indicateurs mensuels
            indicateurs_mensuel = self.generate_indicateurs_data(annee, mois_str)
            indicateurs_mensuel_file = self.save_json_file(indicateurs_mensuel, f"indicateurs_mensuel_{annee}_{mois_str}.json")
            self.upload_to_relay(indicateurs_mensuel_file)
            
            # Sous-indicateurs mensuels
            sous_indicateurs_mensuel = self.generate_sous_indicateurs_data(annee, mois_str)
            sous_indicateurs_mensuel_file = self.save_json_file(sous_indicateurs_mensuel, f"sous_indicateurs_mensuel_{annee}_{mois_str}.json")
            self.upload_to_relay(sous_indicateurs_mensuel_file)
            
            time.sleep(0.5)  # Pause entre les uploads
        
        print(f"✅ Génération terminée pour {annee}")

def main():
    """Fonction principale"""
    print("🔧 Générateur de données JSON pour le Web Service Relay")
    print("=" * 60)
    
    # Vérifier que le relay est accessible
    try:
        response = requests.get(f"{RELAY_URL}/")
        if response.status_code != 200:
            print("❌ Le relay n'est pas accessible")
            return
        print("✅ Relay accessible")
    except Exception as e:
        print(f"❌ Impossible de se connecter au relay: {e}")
        return
    
    # Créer le générateur
    generator = DataGenerator(RELAY_URL, SOCIETE)
    
    # Générer les données pour les 3 dernières années
    current_year = datetime.now().year
    for annee in range(current_year - 2, current_year + 1):
        generator.generate_and_upload_all(str(annee))
        time.sleep(1)  # Pause entre les années
    
    print("\n🎉 Génération et upload terminés !")
    print(f"📁 Fichiers générés dans le dossier: generated_files/")
    print(f"📤 Fichiers uploadés vers le relay pour la société: {SOCIETE}")

if __name__ == "__main__":
    main() 