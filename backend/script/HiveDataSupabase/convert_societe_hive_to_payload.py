# -*- coding: utf-8 -*-
"""
Script pour convertir les fichiers hive par société en payloads JSON organisés
"""

import json
import datetime
import os
from typing import Dict, List, Any
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
        code = ligne.get("code_compte", "")
        if code in mapping_cache:
            mapping = mapping_cache[code]
        else:
            mapping = MappingIndicateurSIG.find_best_mapping(code)
            mapping_cache[code] = mapping
        
        # Ajouter les informations de classe
        ligne['classe'] = code[:1] if code else ''
        ligne['sous_classe'] = code[:2] if code else ''
        ligne['sss_classe'] = code[:3] if code else ''
        
        if mapping:
            ligne['indicateur'] = mapping.indicateur
            ligne['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
        else:
            ligne['indicateur'] = ''
            ligne['sous_indicateur'] = []
        
        # Extraire l'année et le mois de date_ecriture
        date_ecriture = ligne.get('date_ecriture', '')
        if date_ecriture:
            try:
                date_obj = datetime.datetime.fromisoformat(date_ecriture.replace('Z', '+00:00'))
                ligne['annee'] = date_obj.year
                ligne['mois'] = date_obj.month
                ligne['trimestre'] = ((date_obj.month - 1) // 3) + 1
            except:
                ligne['annee'] = None
                ligne['mois'] = None
                ligne['trimestre'] = None
        else:
            ligne['annee'] = None
            ligne['mois'] = None
            ligne['trimestre'] = None
        
        enriched.append(ligne)
    
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
        
        # Utiliser SIGCalculator
        calculator = SIGCalculator(lignes_annee)
        indicateurs_list = []
        
        for code, libelle in libelles.items():
            # Construction des formules
            formule_text = calculator.construire_formule_text(code, 0)
            formule_numeric = calculator.construire_formule_numeric(code, 0)
            
            # Extraire la valeur finale
            try:
                valeur_finale = float(formule_numeric.split(' = ')[-1])
            except (IndexError, ValueError):
                valeur_finale = 0
            
            if valeur_finale == 0:
                continue
            
            # Récupération des sous-indicateurs
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(code)
            tous_composantes = composantes_positives + composantes_negatives
            
            sous_indicateurs = []
            for composante in tous_composantes:
                if composante in ['MC', 'VA', 'EBE', 'RE']:
                    continue
                
                montant = calculator._get_montant_par_indicateur_sous_ind(code, [composante])
                if montant != 0:
                    sous_indicateurs.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
            
            indicateurs_list.append({
                "indicateur": code,
                "libelle": libelle,
                "valeur": valeur_finale,
                "formule_text": formule_text,
                "formule_numeric": formule_numeric,
                "sous_indicateurs": sous_indicateurs
            })
        
        result[annee] = indicateurs_list
    
    return {"periode": periode, "indicateurs": result}

def generate_monthly_indicators_payload(lignes: List[Dict[str, Any]], annee: int) -> Dict[str, Any]:
    """
    Génère le payload pour les indicateurs mensuels
    """
    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }
    
    result = {}
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        
        if not lignes_mois:
            continue
        
        calculator = SIGCalculator(lignes_mois)
        indicateurs_list = []
        
        for code, libelle in libelles.items():
            formule_text = calculator.construire_formule_text(code, 0)
            formule_numeric = calculator.construire_formule_numeric(code, 0)
            
            try:
                valeur_finale = float(formule_numeric.split(' = ')[-1])
            except (IndexError, ValueError):
                valeur_finale = 0
            
            if valeur_finale == 0:
                continue
            
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(code)
            tous_composantes = composantes_positives + composantes_negatives
            
            sous_indicateurs = []
            for composante in tous_composantes:
                if composante in ['MC', 'VA', 'EBE', 'RE']:
                    continue
                
                montant = calculator._get_montant_par_indicateur_sous_ind(code, [composante])
                if montant != 0:
                    sous_indicateurs.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
            
            indicateurs_list.append({
                "indicateur": code,
                "libelle": libelle,
                "valeur": valeur_finale,
                "formule_text": formule_text,
                "formule_numeric": formule_numeric,
                "sous_indicateurs": sous_indicateurs
            })
        
        result[mois] = indicateurs_list
    
    return {"annee": annee, "mois": result}

def generate_global_sub_indicators_payload(lignes: List[Dict[str, Any]], periode: str = "annee") -> Dict[str, Any]:
    """
    Génère le payload pour les sous-indicateurs globaux
    """
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}
    
    for annee in annees:
        lignes_annee = [l for l in lignes if l.get('annee') == annee]
        calculator = SIGCalculator(lignes_annee)
        
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée',
            'EBE': 'Excédent brut d\'exploitation',
            'RE': 'Résultat d\'exploitation',
            'R': 'Résultat net',
        }
        
        indicateurs_calcules = {}
        
        # Calculer les indicateurs principaux
        for code, libelle in libelles.items():
            formule_text = calculator.construire_formule_text(code, 0)
            formule_numeric = calculator.construire_formule_numeric(code, 0)
            
            try:
                valeur_finale = float(formule_numeric.split(' = ')[-1])
            except (IndexError, ValueError):
                valeur_finale = 0
            
            if valeur_finale == 0:
                continue
            
            indicateurs_calcules[code] = valeur_finale
        
        # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
        sous_indicateurs = {}
        for ind_key in indicateurs_calcules.keys():
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
            tous_composantes = composantes_positives + composantes_negatives
            
            sous_indicateurs_list = []
            for composante in tous_composantes:
                if composante in ['MC', 'VA', 'EBE', 'RE']:
                    continue
                
                montant = calculator._get_montant_par_indicateur_sous_ind(ind_key, [composante])
                if montant != 0:
                    sous_indicateurs_list.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
            
            sous_indicateurs[ind_key] = sous_indicateurs_list
        
        result[annee] = sous_indicateurs
    
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
        
        calculator = SIGCalculator(lignes_mois)
        
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée',
            'EBE': 'Excédent brut d\'exploitation',
            'RE': 'Résultat d\'exploitation',
            'R': 'Résultat net',
        }
        
        indicateurs_calcules = {}
        
        # Calculer les indicateurs principaux
        for code, libelle in libelles.items():
            formule_text = calculator.construire_formule_text(code, 0)
            formule_numeric = calculator.construire_formule_numeric(code, 0)
            
            try:
                valeur_finale = float(formule_numeric.split(' = ')[-1])
            except (IndexError, ValueError):
                valeur_finale = 0
            
            if valeur_finale == 0:
                continue
            
            indicateurs_calcules[code] = valeur_finale
        
        # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
        indicateurs_dict = {}
        for ind_key in indicateurs_calcules.keys():
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
            tous_composantes = composantes_positives + composantes_negatives
            
            sous_indicateurs_list = []
            for composante in tous_composantes:
                if composante in ['MC', 'VA', 'EBE', 'RE']:
                    continue
                
                montant = calculator._get_montant_par_indicateur_sous_ind(ind_key, [composante])
                if montant != 0:
                    sous_indicateurs_list.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
            
            indicateurs_dict[ind_key] = sous_indicateurs_list
        
        result[mois] = indicateurs_dict
    
    return {"annee": annee, "mois": result}

def generate_comptes_global_payload(lignes: List[Dict[str, Any]], periode: str = "annee") -> Dict[str, Any]:
    """
    Génère le payload pour les comptes globaux
    """
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}
    
    # Liste des sous-indicateurs possibles pour générer des exemples
    sous_indicateurs_possibles = [
        "VENTES DE MARCHANDISES", "ACHATS DE MARCHANDISES", "PRESTATIONS DE SERVICES",
        "FOURNITURES", "SERVICES EXTÉRIEURS", "CHARGES DE PERSONNEL", "IMPÔTS ET TAXES"
    ]
    
    for annee in annees:
        lignes_annee = [l for l in lignes if l.get('annee') == annee]
        
        # Générer un exemple pour chaque sous-indicateur
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
            
            if comptes_dict:  # Seulement si on a des comptes pour ce sous-indicateur
                comptes_list = list(comptes_dict.values())
                comptes_result[sous_indicateur] = {
                    "total": len(comptes_list),
                    "limit": 50,
                    "offset": 0,
                    "comptes": comptes_list[:50]  # Limiter à 50 comptes
                }
        
        if comptes_result:  # Seulement si on a des données
            result[annee] = comptes_result
    
    return {"periode": periode, "comptes": result}

def generate_comptes_mensuel_payload(lignes: List[Dict[str, Any]], annee: int) -> Dict[str, Any]:
    """
    Génère le payload pour les comptes mensuels
    """
    result = {}
    
    # Liste des sous-indicateurs possibles
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
            
            if comptes_dict:  # Seulement si on a des comptes pour ce sous-indicateur
                comptes_list = list(comptes_dict.values())
                comptes_result[sous_indicateur] = {
                    "total": len(comptes_list),
                    "limit": 50,
                    "offset": 0,
                    "comptes": comptes_list[:50]  # Limiter à 50 comptes
                }
        
        if comptes_result:  # Seulement si on a des données
            result[mois] = comptes_result
    
    return {"annee": annee, "mois": result}

def convert_societe_hive_to_payloads(societe: str, hive_file_path: str, output_dir: str = "payloads"):
    """
    Convertit le fichier hive d'une société en payloads JSON
    """
    # Créer le dossier de sortie pour cette société
    societe_dir = os.path.join(output_dir, societe)
    os.makedirs(societe_dir, exist_ok=True)
    
    print(f"📊 Société: {societe}")
    print(f"Chargement des données depuis {hive_file_path}...")
    lignes = load_societe_hive_data(hive_file_path)
    print(f"Données chargées: {len(lignes)} lignes")
    
    print("Enrichissement des données avec le mapping...")
    lignes_enrichies = enrich_lines_with_mapping(lignes)
    print("Données enrichies")
    
    # Générer les payloads
    print("Génération des payloads...")
    
    # 1. Indicateurs globaux (année)
    payload_global = generate_global_indicators_payload(lignes_enrichies, "annee")
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
    payload_sous_global = generate_global_sub_indicators_payload(lignes_enrichies, "annee")
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
    
    # Liste des sociétés
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
    
    # Lister les fichiers générés
    if os.path.exists("payloads_societes"):
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