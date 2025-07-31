#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour générer des fichiers .hive par société depuis Odoo
"""

import os
import json
import sys
from datetime import datetime
from dotenv import load_dotenv

# Ajouter le répertoire parent au path pour importer les services
sys.path.append('../..')

from services.odoo.odoo_api import OdooService
from models.PlanComptable import MappingIndicateurSIG

load_dotenv()

# Mapping des sociétés Odoo
SOCIETE_MAPPING = {
    "aitecservice": "aitecservice"
}

def connect_odoo():
    """Connexion à Odoo"""
    try:
        odoo = OdooService()
        print("✅ Connexion Odoo réussie")
        return odoo
    except Exception as e:
        print(f"❌ Erreur de connexion Odoo: {e}")
        return None

def fetch_odoo_data(odoo_service, periode="annee") -> list:
    """Récupère les données depuis Odoo"""
    print(f"📊 Récupération des données Odoo (période: {periode})...")
    
    try:
        # Utiliser la même logique que le contrôleur Odoo
        today = datetime.now().date()
        annees = [today.year, today.year - 1, today.year - 2, today.year - 3]
        all_lines = []
        
        for annee in annees:
            if periode == "trimestre":
                # Pour les trimestres, on prend les 3 derniers trimestres
                for trimestre in range(1, 5):
                    mois_debut = (trimestre - 1) * 3 + 1
                    mois_fin = mois_debut + 2
                    date_debut = f"{annee}-{mois_debut:02d}-01"
                    if mois_fin == 12:
                        date_fin = f"{annee}-12-31"
                    else:
                        next_month = mois_fin + 1
                        date_fin = (datetime.date(annee, next_month, 1) - datetime.timedelta(days=1)).isoformat()
                    
                    domain = [
                        ['date', '>=', date_debut], 
                        ['date', '<=', date_fin],
                        ['move_id.state', '=', 'posted']
                    ]
                    
                    fields = ['account_id', 'debit', 'credit', 'date', 'name', 'ref', 'move_id']
                    lines = odoo_service.search_read('account.move.line', domain, fields, limit=10000)
                    
                    for line in lines:
                        if isinstance(line['account_id'], list):
                            line['code_compte'] = line['account_id'][1].split(' ')[0]
                            line['libelle_compte'] = ' '.join(line['account_id'][1].split(' ')[1:])
                        else:
                            line['code_compte'] = ''
                            line['libelle_compte'] = ''
                        
                        code = line["code_compte"]
                        line['classe'] = code[:1] if code else ''
                        line['sous_classe'] = code[:2] if code else ''
                        line['sss_classe'] = code[:3] if code else ''
                        
                        # Mapping des indicateurs
                        mapping = MappingIndicateurSIG.find_best_mapping(code)
                        if mapping:
                            line['indicateur'] = mapping.indicateur
                            line['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
                        else:
                            line['indicateur'] = None
                            line['sous_indicateur'] = []
                        
                        line['montant'] = line['debit'] - line['credit']
                        line['annee'] = annee
                        line['mois'] = int(line['date'][5:7]) if line['date'] else None
                        line['trimestre'] = ((int(line['date'][5:7]) - 1) // 3) + 1 if line['date'] else None
                        
                        all_lines.append(line)
            else:
                # Pour les années
                domain = [
                    ['date', '>=', f"{annee}-01-01"], 
                    ['date', '<=', f"{annee}-12-31"],
                    ['move_id.state', '=', 'posted']
                ]
                
                fields = ['account_id', 'debit', 'credit', 'date', 'name', 'ref', 'move_id']
                lines = odoo_service.search_read('account.move.line', domain, fields, limit=10000)
                
                for line in lines:
                    if isinstance(line['account_id'], list):
                        line['code_compte'] = line['account_id'][1].split(' ')[0]
                        line['libelle_compte'] = ' '.join(line['account_id'][1].split(' ')[1:])
                    else:
                        line['code_compte'] = ''
                        line['libelle_compte'] = ''
                    
                    code = line["code_compte"]
                    line['classe'] = code[:1] if code else ''
                    line['sous_classe'] = code[:2] if code else ''
                    line['sss_classe'] = code[:3] if code else ''
                    
                    # Mapping des indicateurs
                    mapping = MappingIndicateurSIG.find_best_mapping(code)
                    if mapping:
                        line['indicateur'] = mapping.indicateur
                        line['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
                    else:
                        line['indicateur'] = None
                        line['sous_indicateur'] = []
                    
                    line['montant'] = line['debit'] - line['credit']
                    line['annee'] = annee
                    line['mois'] = int(line['date'][5:7]) if line['date'] else None
                    line['trimestre'] = ((int(line['date'][5:7]) - 1) // 3) + 1 if line['date'] else None
                    
                    all_lines.append(line)
        
        print(f"✅ {len(all_lines)} lignes récupérées d'Odoo")
        return all_lines
        
    except Exception as e:
        print(f"❌ Erreur lors de la récupération des données Odoo: {e}")
        return []

def create_societe_hive():
    print("🚀 Génération des fichiers .hive par société depuis Odoo")
    
    try:
        # Connexion à Odoo
        print("🔌 Connexion à Odoo...")
        odoo_service = connect_odoo()
        
        if not odoo_service:
            print("❌ Impossible de se connecter à Odoo")
            return 1
        
        # Récupération des données pour chaque société
        societes_data = {}
        
        for societe_code, societe_name in SOCIETE_MAPPING.items():
            print(f"\n📊 Société: {societe_name}")
            
            # Récupération des données
            lignes = fetch_odoo_data(odoo_service, "annee")
            societes_data[societe_name] = lignes
        
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
                    "description": f"Données Odoo pour {societe}"
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
                
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(create_societe_hive()) 