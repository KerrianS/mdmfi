
# -*- coding: utf-8 -*-
"""
Script pour convertir les fichiers hive par société en payloads JSON organisés
"""

import json
import datetime
import os
import sys
from typing import Dict, List, Any

# Ajouter le répertoire parent au path pour importer les modèles
sys.path.append('..')

from models.PlanComptable import MappingIndicateurSIG
from models.SIG_model import SIGCalculator

def load_societe_hive_data(file_path: str) -> List[Dict[str, Any]]:
    """
    Charge les données du fichier hive d'une société
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Extraire les données brutes selon la structure du fichier
    if 'donnees_brutes' in data:
        if 'lignes' in data['donnees_brutes']:
            # Structure avec lignes dans donnees_brutes
            return data['donnees_brutes']['lignes']
        else:
            # Structure avec vues dans donnees_brutes
            lignes = []
            for vue, donnees in data['donnees_brutes'].items():
                if isinstance(donnees, list):
                    lignes.extend(donnees)
            return lignes
    else:
        # Structure simple (liste directe)
        return data if isinstance(data, list) else []

def enrich_lines_with_mapping(lignes: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Enrichit les lignes avec le mapping des indicateurs SIG
    """
    mapping_cache = {}
    enriched = []
    
    for ligne in lignes:
        # Adapter les champs pour correspondre au format attendu
        code = ligne.get("code_compte", "")
        ligne_enrichie = {
            'code_compte': code,
            'libelle_compte': ligne.get('description', ''),
            'montant': float(ligne.get('montant', 0)),
            'debit': float(ligne.get('debit', 0)),
            'credit': float(ligne.get('credit', 0)),
            'date_ecriture': ligne.get('date_ecriture', ''),
            'document_no': ligne.get('document', ''),
            'user_id': ligne.get('utilisateur', ''),
            'source_code': ligne.get('source', ''),
            'global_dimension_1': ligne.get('dimension_1', ''),
            'global_dimension_2': ligne.get('dimension_2', ''),
            'annee': None,
            'mois': None,
            'sous_indicateur': []
        }
        
        # Extraire l'année et le mois de date_ecriture
        date_ecriture = ligne_enrichie['date_ecriture']
        if date_ecriture:
            try:
                date_obj = datetime.datetime.fromisoformat(date_ecriture.replace('Z', '+00:00'))
                ligne_enrichie['annee'] = date_obj.year
                ligne_enrichie['mois'] = date_obj.month
                ligne_enrichie['trimestre'] = ((date_obj.month - 1) // 3) + 1
            except:
                ligne_enrichie['annee'] = None
                ligne_enrichie['mois'] = None
                ligne_enrichie['trimestre'] = None
        else:
            ligne_enrichie['annee'] = None
            ligne_enrichie['mois'] = None
            ligne_enrichie['trimestre'] = None
        
        # Trouver le mapping pour ce compte
        if code in mapping_cache:
            mapping = mapping_cache[code]
        else:
            mapping = MappingIndicateurSIG.find_best_mapping(code)
            mapping_cache[code] = mapping
        
        if mapping:
            ligne_enrichie['indicateur'] = mapping.indicateur
            ligne_enrichie['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
        else:
            ligne_enrichie['indicateur'] = ''
            ligne_enrichie['sous_indicateur'] = []
        
        enriched.append(ligne_enrichie)
    
    return enriched

def generate_global_indicators_payload(lignes: List[Dict[str, Any]], periode: str = "annee") -> Dict[str, Any]:
    """
    Génère le payload pour les indicateurs globaux
    """
    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }
    
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}
    
    for annee in annees:
        lignes_annee = [l for l in lignes if l.get('annee') == annee]
        
        # Calculer les indicateurs pour cette année
        calculator = SIGCalculator()
        indicateurs = calculator.calculer_indicateurs_global(lignes_annee)
        
        if indicateurs and 'indicateurs' in indicateurs:
            result[annee] = indicateurs['indicateurs']
    
    return {"periode": periode, "indicateurs": result}

def generate_monthly_indicators_payload(lignes: List[Dict[str, Any]], annee: int) -> Dict[str, Any]:
    """
    Génère le payload pour les indicateurs mensuels
    """
    result = {}
    
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        
        if not lignes_mois:
            continue
        
        # Calculer les indicateurs pour ce mois
        calculator = SIGCalculator()
        indicateurs = calculator.calculer_indicateurs_mensuel(lignes_mois, annee)
        
        if indicateurs and 'mois' in indicateurs and mois in indicateurs['mois']:
            result[mois] = indicateurs['mois'][mois]
    
    return {"annee": annee, "mois": result}

def generate_global_sub_indicators_payload(lignes: List[Dict[str, Any]], periode: str = "annee") -> Dict[str, Any]:
    """
    Génère le payload pour les sous-indicateurs globaux
    """
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}
    
    for annee in annees:
        lignes_annee = [l for l in lignes if l.get('annee') == annee]
        
        # Calculer les sous-indicateurs pour cette année
        calculator = SIGCalculator()
        sous_indicateurs = calculator.calculer_sous_indicateurs_global(lignes_annee)
        
        if sous_indicateurs and 'sous_indicateurs' in sous_indicateurs:
            result[annee] = sous_indicateurs['sous_indicateurs']
    
    return {"periode": periode, "sous_indicateurs": result}

def generate_monthly_sub_indicators_payload(lignes: List[Dict[str, Any]], annee: int) -> Dict[str, Any]:
    """
    Génère le payload pour les sous-indicateurs mensuels
    """
    result = {}
    
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        
        if not lignes_mois:
            continue
        
        # Calculer les sous-indicateurs pour ce mois
        calculator = SIGCalculator()
        sous_indicateurs = calculator.calculer_sous_indicateurs_mensuel(lignes_mois, annee)
        
        if sous_indicateurs and 'mois' in sous_indicateurs and mois in sous_indicateurs['mois']:
            result[mois] = sous_indicateurs['mois'][mois]
    
    return {"annee": annee, "mois": result}

def generate_comptes_global_payload(lignes: List[Dict[str, Any]], periode: str = "annee") -> Dict[str, Any]:
    """
    Génère le payload pour les comptes globaux
    """
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}
    
    # Liste des sous-indicateurs possibles
    sous_indicateurs_possibles = [
        "VENTES DE MARCHANDISES", "ACHATS DE MARCHANDISES", "PRESTATIONS DE SERVICES",
        "FOURNITURES", "SERVICES EXTÉRIEURS", "CHARGES DE PERSONNEL", "IMPÔTS ET TAXES"
    ]
    
    for annee in annees:
        lignes_annee = [l for l in lignes if l.get('annee') == annee]
        comptes_result = {}
        
        for sous_indicateur in sous_indicateurs_possibles:
            comptes_dict = {}
            
            for l in lignes_annee:
                if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", [])):
                    key = (l["code_compte"], l.get("libelle_compte", ""))
                    if key not in comptes_dict:
                        comptes_dict[key] = {
                            "code_compte": l["code_compte"],
                            "libelle_compte": l.get("libelle_compte", ""),
                            "montant": 0,
                            "debit": 0,
                            "credit": 0
                        }
                    comptes_dict[key]["montant"] += l["montant"]
                    comptes_dict[key]["debit"] += l.get("debit", 0)
                    comptes_dict[key]["credit"] += l.get("credit", 0)
            
            if comptes_dict:
                comptes_list = list(comptes_dict.values())
                comptes_result[sous_indicateur] = {
                    "total": len(comptes_list),
                    "limit": 50,
                    "offset": 0,
                    "comptes": comptes_list[:50]
                }
        
        if comptes_result:
            result[annee] = comptes_result
    
    return {"periode": periode, "comptes": result}

def generate_comptes_mensuel_payload(lignes: List[Dict[str, Any]], annee: int) -> Dict[str, Any]:
    """
    Génère le payload pour les comptes mensuels
    """
    result = {}
    
    sous_indicateurs_possibles = [
        "VENTES DE MARCHANDISES", "ACHATS DE MARCHANDISES", "PRESTATIONS DE SERVICES",
        "FOURNITURES", "SERVICES EXTÉRIEURS", "CHARGES DE PERSONNEL", "IMPÔTS ET TAXES"
    ]
    
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        
        if not lignes_mois:
            continue
        
        comptes_result = {}
        
        for sous_indicateur in sous_indicateurs_possibles:
            comptes_dict = {}
            
            for l in lignes_mois:
                if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", [])):
                    key = (l["code_compte"], l.get("libelle_compte", ""))
                    if key not in comptes_dict:
                        comptes_dict[key] = {
                            "code_compte": l["code_compte"],
                            "libelle_compte": l.get("libelle_compte", ""),
                            "montant": 0,
                            "debit": 0,
                            "credit": 0
                        }
                    comptes_dict[key]["montant"] += l["montant"]
                    comptes_dict[key]["debit"] += l.get("debit", 0)
                    comptes_dict[key]["credit"] += l.get("credit", 0)
            
            if comptes_dict:
                comptes_list = list(comptes_dict.values())
                comptes_result[sous_indicateur] = {
                    "total": len(comptes_list),
                    "limit": 50,
                    "offset": 0,
                    "comptes": comptes_list[:50]
                }
        
        if comptes_result:
            result[mois] = comptes_result
    
    return {"annee": annee, "mois": result}

def convert_societe_hive_to_payloads(societe: str, hive_file_path: str, output_dir: str = "payloads"):
    """
    Convertit le fichier hive d'une société en payloads JSON
    """
    societe_dir = os.path.join(output_dir, societe)
    os.makedirs(societe_dir, exist_ok=True)
    
    print(f"📊 Conversion de {societe}...")
    print(f"📁 Fichier source: {hive_file_path}")
    print(f"📁 Dossier de sortie: {societe_dir}")
    
    # Charger les données
    lignes = load_societe_hive_data(hive_file_path)
    print(f"📊 {len(lignes)} lignes chargées")
    
    # Enrichir les données
    lignes_enrichies = enrich_lines_with_mapping(lignes)
    print(f"✅ Données enrichies")
    
    # Générer les payloads
    print("📝 Génération des payloads...")
    
    # 1. Indicateurs globaux (année)
    payload_global = generate_global_indicators_payload(lignes_enrichies)
    with open(f"{societe_dir}/indicateurs_global_annee.json", 'w', encoding='utf-8') as f:
        json.dump(payload_global, f, ensure_ascii=False, indent=2)
    print("✓ Payload indicateurs globaux (année) généré")
    
    # 2. Indicateurs mensuels (pour chaque année)
    annees = sorted({l.get('annee') for l in lignes_enrichies if l.get('annee')}, reverse=True)[:3]
    for annee in annees:
        payload_mensuel = generate_monthly_indicators_payload(lignes_enrichies, annee)
        with open(f"{societe_dir}/indicateurs_mensuel_{annee}.json", 'w', encoding='utf-8') as f:
            json.dump(payload_mensuel, f, ensure_ascii=False, indent=2)
        print(f"✓ Payload indicateurs mensuels {annee} généré")
    
    # 3. Sous-indicateurs globaux (année)
    payload_sous_global = generate_global_sub_indicators_payload(lignes_enrichies)
    with open(f"{societe_dir}/sous_indicateurs_global_annee.json", 'w', encoding='utf-8') as f:
        json.dump(payload_sous_global, f, ensure_ascii=False, indent=2)
    print("✓ Payload sous-indicateurs globaux (année) généré")
    
    # 4. Sous-indicateurs mensuels (pour chaque année)
    for annee in annees:
        payload_sous_mensuel = generate_monthly_sub_indicators_payload(lignes_enrichies, annee)
        with open(f"{societe_dir}/sous_indicateurs_mensuel_{annee}.json", 'w', encoding='utf-8') as f:
            json.dump(payload_sous_mensuel, f, ensure_ascii=False, indent=2)
        print(f"✓ Payload sous-indicateurs mensuels {annee} généré")
    
    # 5. Comptes globaux (année)
    payload_comptes_global = generate_comptes_global_payload(lignes_enrichies, "annee")
    with open(f"{societe_dir}/comptes_global_annee.json", 'w', encoding='utf-8') as f:
        json.dump(payload_comptes_global, f, ensure_ascii=False, indent=2)
    print("✓ Payload comptes globaux (année) généré")
    
    # 6. Comptes mensuels (pour chaque année)
    for annee in annees:
        payload_comptes_mensuel = generate_comptes_mensuel_payload(lignes_enrichies, annee)
        with open(f"{societe_dir}/comptes_mensuel_{annee}.json", 'w', encoding='utf-8') as f:
            json.dump(payload_comptes_mensuel, f, ensure_ascii=False, indent=2)
        print(f"✓ Payload comptes mensuels {annee} généré")
    
    print(f"✅ Conversion terminée pour {societe} !")

def convert_all_societes():
    """
    Convertit tous les fichiers hive de sociétés en payloads
    """
    print("🔄 Conversion de tous les fichiers hive par société")
    print("=" * 50)
    
    societes = ["rsp-neg", "rsp-sb", "rsp-bgs"]
    
    for societe in societes:
        hive_file = f"{societe}_data.hive"
        if os.path.exists(hive_file):
            print(f"\n📊 Conversion de {societe}...")
            try:
                convert_societe_hive_to_payloads(societe, hive_file, "payloads_societes")
                print(f"✅ Conversion {societe} terminée avec succès !")
            except Exception as e:
                print(f"❌ Erreur lors de la conversion {societe}: {e}")
        else:
            print(f"⚠️  Fichier {hive_file} non trouvé")
    
    print("\n" + "=" * 50)
    print("📁 Structure des fichiers générés:")
    
    for societe in societes:
        societe_dir = f"payloads_societes/{societe}"
        if os.path.exists(societe_dir):
            print(f"\n📂 Dossier {societe}:")
            for file in os.listdir(societe_dir):
                if file.endswith('.json'):
                    file_path = os.path.join(societe_dir, file)
                    size = os.path.getsize(file_path)
                    print(f"  📄 {file} ({size:,} bytes)")
    
    print("\n🎉 Conversion terminée !")
    print("\n💡 Utilisation dans Flutter:")
    print("   - Accédez aux données par société: payloads_societes/rsp-neg/")
    print("   - Même format que les webservices")

if __name__ == "__main__":
    convert_all_societes() 