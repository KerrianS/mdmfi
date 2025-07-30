# -*- coding: utf-8 -*-
from fastapi import APIRouter
from controllers.navision_sig_controller import NavisionSIGController
from models.PlanComptable import MappingIndicateurSIG
from models.SIG_model import SIGCalculator
import datetime
from fastapi import Query
from typing import Optional

navision_router = APIRouter()

SOCIETE_VUE_MAP = {
    "rsp-bgs": "bgs_view_entry",
    "rsp-neg": "neg_view_entry",
    "rsp-sb": "sb_view_entry"
}

def calcul_sig_adapte(lignes):
    """
    Calcul SIG avec formules comptables officielles françaises
    Utilise le nouveau SIGCalculator pour un code plus propre et modulaire
    """
    calculator = SIGCalculator(lignes)
    return calculator.calculer_tous_indicateurs()

@navision_router.get("/{societe}/comptes/global", tags=["Navision"])
def get_comptes_global(
    societe: str,
    sous_indicateur: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[str] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre"),
    limit: int = 50,
    offset: int = 0
):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    comptes_result = {}
    if periode == "annee":
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            comptes_dict = {}
            for l in lignes_annee:
                if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", [])) and l.get("annee") == a:
                    key = (l["code_compte"], l["libelle_compte"])
                    if key not in comptes_dict:
                        comptes_dict[key] = {
                            "code_compte": l["code_compte"],
                            "libelle_compte": l["libelle_compte"],
                            "montant": 0,
                            "debit": 0,
                            "credit": 0
                        }
                    comptes_dict[key]["montant"] += l["montant"]
                    comptes_dict[key]["debit"] += l.get("debit", 0)
                    comptes_dict[key]["credit"] += l.get("credit", 0)
            comptes_list = list(comptes_dict.values())
            total = len(comptes_list)
            comptes_page = comptes_list[offset:offset+limit]
            comptes_result[a] = {"total": total, "limit": limit, "offset": offset, "comptes": comptes_page}
        return {"periode": "annee", "comptes": comptes_result}
    elif periode == "trimestre":
        try:
            trimestre_int = int(trimestre)
        except (TypeError, ValueError):
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        if trimestre_int not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        for a in annees:
            lignes_trim = navision_sig.get_lines("trimestre", annee=a, trimestre=trimestre_int)
            comptes_dict = {}
            for l in lignes_trim:
                if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", [])) and l.get("annee") == a:
                    key = (l["code_compte"], l["libelle_compte"])
                    if key not in comptes_dict:
                        comptes_dict[key] = {
                            "code_compte": l["code_compte"],
                            "libelle_compte": l["libelle_compte"],
                            "montant": 0,
                            "debit": 0,
                            "credit": 0
                        }
                    comptes_dict[key]["montant"] += l["montant"]
                    comptes_dict[key]["debit"] += l.get("debit", 0)
                    comptes_dict[key]["credit"] += l.get("credit", 0)
            comptes_list = list(comptes_dict.values())
            total = len(comptes_list)
            comptes_page = comptes_list[offset:offset+limit]
            comptes_result[a] = {"total": total, "limit": limit, "offset": offset, "comptes": comptes_page}
        return {"periode": "trimestre", "trimestre": trimestre_int, "comptes": comptes_result}
    else:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}

# 3. Sous indicateurs mensuels
@navision_router.get("/{societe}/sous_indicateurs/mensuel", tags=["Navision"])
def get_sous_indicateurs_mensuel(societe: str, annee: int):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    
    lignes = navision_sig.get_lines("annee")
    result = {}
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        if not lignes_mois:
            continue
        
        # Utiliser le nouveau SIGCalculator
        calculator = SIGCalculator(lignes_mois)
        indicateurs_calcules = calculator.calculer_tous_indicateurs()
        indicateurs_dict = {}
        
        for ind_key in indicateurs_calcules.keys():
            sous_indicateurs_avec_montants = calculator.get_sous_indicateurs_avec_montants(ind_key)
            sous_indicateurs = []
            
            for si_data in sous_indicateurs_avec_montants:
                sous_indicateur_name = si_data["sous_indicateur"]
                sous_indicateurs.append({
                    "sousIndicateur": sous_indicateur_name,
                    "libelle": MappingIndicateurSIG.get_libelle(sous_indicateur_name),
                    "initiales": MappingIndicateurSIG.get_initiales(sous_indicateur_name),
                    "formule": MappingIndicateurSIG.get_formule(sous_indicateur_name),
                    "montant": si_data["montant"]
                })
            
            indicateurs_dict[ind_key] = sous_indicateurs
        result[mois] = indicateurs_dict
    return {"annee": annee, "mois": result}

# 4. Comptes mensuels (paginé)
@navision_router.get("/{societe}/comptes/mensuel", tags=["Navision"])
def get_comptes_mensuel(
    societe: str,
    annee: int,
    mois: int,
    sous_indicateur: str,
    limit: int = 50,
    offset: int = 0
):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    lignes = navision_sig.get_lines("mois", annee=annee, mois=mois)
    comptes = [
        {
            "code_compte": l["code_compte"],
            "libelle_compte": l["libelle_compte"],
            "montant": l["montant"],
            "debit": l.get("debit", 0),
            "credit": l.get("credit", 0),
            "date_ecriture": l["date_ecriture"],
            "document": l["document"],
            "utilisateur": l["utilisateur"]
        }
        for l in lignes
        if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", [])) and l.get("annee") == annee
    ]
    total = len(comptes)
    comptes_page = comptes[offset:offset+limit]
    return {"total": total, "limit": limit, "offset": offset, "comptes": comptes_page}

@navision_router.get("/{societe}/indicateurs/mensuel", tags=["Navision"])
def get_indicateurs_mensuel_valeurs(societe: str, annee: int):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }
    
    lignes = navision_sig.get_lines("annee")
    result = {}
    for mois in range(1, 13):
        lignes_mois = [l for l in lignes if l.get('annee') == annee and l.get('mois') == mois]
        if not lignes_mois:
            continue
        
                    # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_mois)
            indicateurs_list = []
            
            for code, libelle in libelles.items():
                # Construction des formules avec le nouveau modèle
                formule_text = calculator.construire_formule_text(code, 0)  # valeur temporaire
                formule_numeric = calculator.construire_formule_numeric(code, 0)  # valeur temporaire
                
                # Extraire la valeur finale de la formule numérique
                # La formule est au format "INDICATEUR = ... = VALEUR_FINALE"
                try:
                    valeur_finale = float(formule_numeric.split(' = ')[-1])
                except (IndexError, ValueError):
                    valeur_finale = 0
                
                if valeur_finale == 0:
                    continue
                
                # Récupération des sous-indicateurs avec montants non-nuls
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(code)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs = []
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
                    montant = calculator._get_montant_par_indicateur_sous_ind(code, [composante])
                    if montant != 0:
                        sous_indicateurs.append({
                            "sous_indicateur": composante,
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

@navision_router.get("/{societe}/indicateurs/global", tags=["Navision"])
def get_indicateurs_global_valeurs(
    societe: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[str] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre")
):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }
    
    if periode == "annee":
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        result = {}
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_annee)
            indicateurs_list = []
            
            for code, libelle in libelles.items():
                # Construction des formules avec le nouveau modèle
                formule_text = calculator.construire_formule_text(code, 0)  # valeur temporaire
                formule_numeric = calculator.construire_formule_numeric(code, 0)  # valeur temporaire
                
                # Extraire la valeur finale de la formule numérique
                # La formule est au format "INDICATEUR = ... = VALEUR_FINALE"
                try:
                    valeur_finale = float(formule_numeric.split(' = ')[-1])
                except (IndexError, ValueError):
                    valeur_finale = 0
                
                if valeur_finale == 0:
                    continue
                
                # Récupération des sous-indicateurs avec montants non-nuls
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(code)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs = []
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
                    montant = calculator._get_montant_par_indicateur_sous_ind(code, [composante])
                    if montant != 0:
                        sous_indicateurs.append({
                            "sous_indicateur": composante,
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
            result[a] = indicateurs_list
        return {"periode": "annee", "indicateurs": result}
    elif periode == "trimestre":
        try:
            trimestre_int = int(trimestre)
        except (TypeError, ValueError):
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        if trimestre_int not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        result = {}
        for a in annees:
            lignes_trim = navision_sig.get_lines("trimestre", annee=a, trimestre=trimestre_int)
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_trim)
            indicateurs_list = []
            
            for code, libelle in libelles.items():
                # Construction des formules avec le nouveau modèle
                formule_text = calculator.construire_formule_text(code, 0)  # valeur temporaire
                formule_numeric = calculator.construire_formule_numeric(code, 0)  # valeur temporaire
                
                # Extraire la valeur finale de la formule numérique
                # La formule est au format "INDICATEUR = ... = VALEUR_FINALE"
                try:
                    valeur_finale = float(formule_numeric.split(' = ')[-1])
                except (IndexError, ValueError):
                    valeur_finale = 0
                
                if valeur_finale == 0:
                    continue
                
                # Récupération des sous-indicateurs avec montants non-nuls
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(code)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs = []
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
                    montant = calculator._get_montant_par_indicateur_sous_ind(code, [composante])
                    if montant != 0:
                        sous_indicateurs.append({
                            "sous_indicateur": composante,
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
            result[a] = indicateurs_list
        return {"periode": "trimestre", "trimestre": trimestre_int, "indicateurs": result}
    else:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}

# DEBUG: Endpoint temporaire pour diagnostiquer les données
@navision_router.get("/{societe}/debug/lignes", tags=["Navision"])
def debug_lignes(societe: str, limit: int = 10):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    lignes = navision_sig.get_lines("annee")
    
    # Prenons quelques lignes pour voir leur structure
    lignes_debug = lignes[:limit] if lignes else []
    
    # Statistiques sur les indicateurs
    indicateurs_count = {}
    sous_indicateurs_count = {}
    codes_sans_mapping = []
    
    for l in lignes:
        ind = l.get('indicateur')
        if ind:
            indicateurs_count[ind] = indicateurs_count.get(ind, 0) + 1
        else:
            codes_sans_mapping.append(l.get('code_compte', ''))
        
        for si in l.get('sous_indicateur', []):
            if si:
                sous_indicateurs_count[si] = sous_indicateurs_count.get(si, 0) + 1
    
    return {
        "total_lignes": len(lignes),
        "echantillon_lignes": lignes_debug,
        "indicateurs_stats": indicateurs_count,
        "sous_indicateurs_stats": sous_indicateurs_count,
        "codes_sans_mapping_sample": codes_sans_mapping[:20],
        "annees_disponibles": sorted(list(set([l.get('annee') for l in lignes if l.get('annee')])), reverse=True)
    }

@navision_router.get("/{societe}/sous_indicateurs/global", tags=["Navision"])
def get_sous_indicateurs_global(
    societe: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[str] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre")
):
    vue = SOCIETE_VUE_MAP.get(societe)
    if not vue:
        return {"error": "Société inconnue"}
    navision_sig = NavisionSIGController(vue)
    
    if periode == "annee":
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        result = {}
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_annee)
            indicateurs_calcules = calculator.calculer_tous_indicateurs()
            sous_indicateurs = {}
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            for ind_key in indicateurs_calcules.keys():
                # Utiliser get_composantes_formule pour récupérer seulement les sous-indicateurs utilisés dans la formule
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs_list = []
                
                # Pour chaque composante de la formule, récupérer ses informations
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
                    montant = calculator._get_montant_par_indicateur_sous_ind(ind_key, [composante])
                    
                    sous_indicateurs_list.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
                
                sous_indicateurs[ind_key] = sous_indicateurs_list
            result[a] = sous_indicateurs
        return {"periode": "annee", "sous_indicateurs": result}
    elif periode == "trimestre":
        try:
            trimestre_int = int(trimestre)
        except (TypeError, ValueError):
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        if trimestre_int not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        result = {}
        for a in annees:
            lignes_trim = navision_sig.get_lines("trimestre", annee=a, trimestre=trimestre_int)
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_trim)
            indicateurs_calcules = calculator.calculer_tous_indicateurs()
            sous_indicateurs = {}
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            for ind_key in indicateurs_calcules.keys():
                # Utiliser get_composantes_formule pour récupérer seulement les sous-indicateurs utilisés dans la formule
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs_list = []
                
                # Pour chaque composante de la formule, récupérer ses informations
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
                    montant = calculator._get_montant_par_indicateur_sous_ind(ind_key, [composante])
                    
                    sous_indicateurs_list.append({
                        "sousIndicateur": composante,
                        "libelle": MappingIndicateurSIG.get_libelle(composante),
                        "initiales": MappingIndicateurSIG.get_initiales(composante),
                        "formule": MappingIndicateurSIG.get_formule(composante),
                        "montant": montant
                    })
                
                sous_indicateurs[ind_key] = sous_indicateurs_list
            result[a] = sous_indicateurs
        return {"periode": "trimestre", "trimestre": trimestre_int, "sous_indicateurs": result}
    else:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}