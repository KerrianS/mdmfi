#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour générer des fichiers .hive par société et payloads organisés
"""

import os
import json
from datetime import datetime
from dotenv import load_dotenv

# Import des contrôleurs
from controllers.navision_sig_controller import NavisionSIGController

load_dotenv()

# Mapping des vues vers les noms de sociétés
SOCIETE_MAPPING = {
    "neg_view_entry": "rsp-neg",
    "sb_view_entry": "rsp-sb", 
    "bgs_view_entry": "rsp-bgs"
}

def create_societe_hive():
    print("🚀 Génération des fichiers .hive par société")
    
    # Contrôleurs Navision pour les 3 vues
    navision_neg = NavisionSIGController(vue="neg_view_entry")
    navision_sb = NavisionSIGController(vue="sb_view_entry")
    navision_bgs = NavisionSIGController(vue="bgs_view_entry")
    
    # Récupération des données Navision (3 vues)
    print("\n📊 Récupération des données Navision par société...")
    
    # Récupération des données pour les années 2022, 2021, 2020
    annees = [2022, 2021, 2020]
    
    # Dictionnaire pour stocker les données par société
    societes_data = {
        "rsp-neg": [],
        "rsp-sb": [],
        "rsp-bgs": []
    }
    
    # Contrôleurs par société
    controllers = {
        "rsp-neg": navision_neg,
        "rsp-sb": navision_sb,
        "rsp-bgs": navision_bgs
    }
    
    for societe, controller in controllers.items():
        print(f"\n📊 Société: {societe}")
        
        for annee in annees:
            print(f"   📅 Année {annee}:")
            
            # Récupération des lignes pour cette société/année
            lignes = controller.get_lines("annee", annee)
            societes_data[societe].extend(lignes)
            
            print(f"      ✅ {len(lignes)} lignes récupérées")
    
    # Générer un fichier hive par société
    print(f"\n📝 Génération des fichiers .hive par société...")
    
    for societe, lignes in societes_data.items():
        if not lignes:
            print(f"⚠️  Aucune donnée pour {societe}")
            continue
            
        print(f"\n📊 Société {societe}: {len(lignes)} lignes")
        
        # Construction du fichier .hive pour cette société
        hive_data = {
            "metadata": {
                "generation_date": datetime.now().isoformat(),
                "societe": societe,
                "total_lines": len(lignes),
                "description": f"Données Navision pour {societe} (années 2022, 2021, 2020)"
            },
            "donnees_brutes": {
                "lignes": lignes
            }
        }
        
        # Sauvegarder le fichier
        filename = f"{societe}_data.hive"
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(hive_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ Fichier généré: {filename}")
    
    print(f"\n🎉 Génération terminée !")
    print(f"📁 Fichiers créés:")
    for societe in societes_data.keys():
        filename = f"{societe}_data.hive"
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            print(f"   📄 {filename} ({size:,} bytes)")

if __name__ == "__main__":
    create_societe_hive() 