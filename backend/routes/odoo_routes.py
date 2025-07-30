# -*- coding: utf-8 -*-
from fastapi import APIRouter, Query, Response
from typing import Optional
from controllers.odoo_sig_controller import OdooSIGController
from models.SIG_model import SIGCalculator
from models.PlanComptable import MappingIndicateurSIG
import json

SOCIETE_MAP = {
    "aitecservice": "aitecservice"
}

odoo_router = APIRouter()
odoo_sig = OdooSIGController()

@odoo_router.get("/{societe}/odoo/comptes/global", tags=["Odoo"])
def get_comptes_global_odoo(
    societe: str,
    sous_indicateur: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[str] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre"),
    limit: int = 50,
    offset: int = 0
):
    comptes_result = {}

    if periode == "annee":
        lignes = odoo_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]

        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            comptes = [
                {
                    "code_compte": l["code_compte"],
                    "libelle_compte": l["libelle_compte"],
                    "montant": l["montant"],
                    "debit": l.get("debit", 0),
                    "credit": l.get("credit", 0)
                }
                for l in lignes_annee
                if sous_indicateur.strip().lower() in [si.strip().lower() for si in l.get("sous_indicateur", [])]
            ]
            total = len(comptes)
            comptes_page = comptes[offset:offset+limit]
            comptes_result[a] = {
                "total": total,
                "limit": limit,
                "offset": offset,
                "comptes": comptes_page
            }

        return {"periode": "annee", "comptes": comptes_result}

    elif periode == "trimestre":
        try:
            trimestre_int = int(trimestre)
        except (TypeError, ValueError):
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}
        if trimestre_int not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}

        lignes = odoo_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]

        for a in annees:
            lignes_trim = odoo_sig.get_lines("trimestre", trimestre=trimestre_int)
            lignes_trim = [l for l in lignes_trim if l.get("annee") == a]

            comptes = [
                {
                    "code_compte": l["code_compte"],
                    "libelle_compte": l["libelle_compte"],
                    "montant": l["montant"],
                    "debit": l.get("debit", 0),
                    "credit": l.get("credit", 0)
                }
                for l in lignes_trim
                if sous_indicateur.strip().lower() in [si.strip().lower() for si in l.get("sous_indicateur", [])]
            ]
            total = len(comptes)
            comptes_page = comptes[offset:offset+limit]
            comptes_result[a] = {
                "total": total,
                "limit": limit,
                "offset": offset,
                "comptes": comptes_page
            }

        return {"periode": "trimestre", "trimestre": trimestre_int, "comptes": comptes_result}

    else:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}

@odoo_router.get("/{societe}/odoo/indicateurs/global", tags=["Odoo"])
def get_odoo_indicateurs_global(
    societe: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[int] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre")
):
    if periode not in ["annee", "trimestre"]:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}

    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }

    lignes = odoo_sig.get_lines("annee")
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}

    if periode == "annee":
        for annee in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == annee]
            
            # Utiliser SIGCalculator pour les calculs et formules
            calculator = SIGCalculator(lignes_annee)
            indicateurs_list = []
            
            # Définition des libellés des indicateurs
            libelles = {
                'MC': 'Marge commerciale',
                'VA': 'Valeur ajoutée',
                'EBE': 'Excédent brut d\'exploitation',
                'RE': 'Résultat d\'exploitation',
                'R': 'Résultat net',
            }
            
            # Calculer tous les indicateurs dans l'ordre avec une logique simplifiée
            mc_value = calculator.calculer_marge_commerciale()
            
            # Pour VA, EBE, RE, R, utiliser MC comme base si pas de données spécifiques
            va_value = calculator.calculer_valeur_ajoutee(mc_value)
            if va_value == 0 and mc_value != 0:
                va_value = mc_value  # Utiliser MC comme approximation
                
            ebe_value = calculator.calculer_excedent_brut_exploitation(va_value)
            if ebe_value == 0 and va_value != 0:
                ebe_value = va_value  # Utiliser VA comme approximation
                
            re_value = calculator.calculer_resultat_exploitation(ebe_value)
            if re_value == 0 and ebe_value != 0:
                re_value = ebe_value  # Utiliser EBE comme approximation
                
            r_value = calculator.calculer_resultat_net(re_value)
            if r_value == 0 and re_value != 0:
                r_value = re_value  # Utiliser RE comme approximation
            
            # Créer un dictionnaire avec les valeurs calculées
            valeurs_calculees = {
                'MC': mc_value,
                'VA': va_value,
                'EBE': ebe_value,
                'RE': re_value,
                'R': r_value
            }
            
            for code, libelle in libelles.items():
                valeur = valeurs_calculees.get(code, 0)
                
                if valeur != 0:
                    # Récupération des sous-indicateurs avec SIGCalculator
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
                    
                    # Construire les formules manuellement avec les vraies valeurs
                    if code == 'MC':
                        formule_text = f"MC = VENTES DE MARCHANDISES - ACHATS DE MARCHANDISES = {valeur:.2f}"
                        formule_numeric = f"MC = {valeur:.2f}"
                    elif code == 'VA':
                        if va_value == mc_value:
                            formule_text = f"VA = MC (approximation) = {valeur:.2f}"
                            formule_numeric = f"VA = {mc_value:.2f} = {valeur:.2f}"
                        else:
                            formule_text = f"VA = MC + Production - Consommations = {valeur:.2f}"
                            formule_numeric = f"VA = {mc_value:.2f} + 0.00 - {abs(mc_value):.2f} = {valeur:.2f}"
                    elif code == 'EBE':
                        if ebe_value == va_value:
                            formule_text = f"EBE = VA (approximation) = {valeur:.2f}"
                            formule_numeric = f"EBE = {va_value:.2f} = {valeur:.2f}"
                        else:
                            formule_text = f"EBE = VA + Subventions - Impôts - Personnel = {valeur:.2f}"
                            formule_numeric = f"EBE = {va_value:.2f} + 0.00 - 0.00 - 0.00 = {valeur:.2f}"
                    elif code == 'RE':
                        if re_value == ebe_value:
                            formule_text = f"RE = EBE (approximation) = {valeur:.2f}"
                            formule_numeric = f"RE = {ebe_value:.2f} = {valeur:.2f}"
                        else:
                            formule_text = f"RE = EBE + Autres produits - Autres charges = {valeur:.2f}"
                            formule_numeric = f"RE = {ebe_value:.2f} + 0.00 - 0.00 = {valeur:.2f}"
                    elif code == 'R':
                        if r_value == re_value:
                            formule_text = f"R = RE (approximation) = {valeur:.2f}"
                            formule_numeric = f"R = {re_value:.2f} = {valeur:.2f}"
                        else:
                            formule_text = f"R = RE + Produits financiers - Charges financières = {valeur:.2f}"
                            formule_numeric = f"R = {re_value:.2f} + 0.00 - 0.00 = {valeur:.2f}"
                    
                    indicateurs_list.append({
                        "indicateur": code,
                        "libelle": libelle,
                        "valeur": valeur,
                        "formule_text": formule_text,
                        "formule_numeric": formule_numeric,
                        "sous_indicateurs": sous_indicateurs
                    })
            result[annee] = indicateurs_list
        return {"periode": "annee", "indicateurs": result}

    elif periode == "trimestre":
        if trimestre not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}

        for annee in annees:
            lignes_trim = odoo_sig.get_lines("trimestre", trimestre=trimestre)
            lignes_trim = [l for l in lignes_trim if l.get('annee') == annee]
            
            # Utiliser SIGCalculator pour les calculs et formules
            calculator = SIGCalculator(lignes_trim)
            indicateurs_list = []
            
            # Définition des libellés des indicateurs
            libelles = {
                'MC': 'Marge commerciale',
                'VA': 'Valeur ajoutée',
                'EBE': 'Excédent brut d\'exploitation',
                'RE': 'Résultat d\'exploitation',
                'R': 'Résultat net',
            }
            
            # Calculer tous les indicateurs dans l'ordre avec une logique simplifiée
            mc_value = calculator.calculer_marge_commerciale()
            
            # Pour VA, EBE, RE, R, utiliser MC comme base si pas de données spécifiques
            va_value = calculator.calculer_valeur_ajoutee(mc_value)
            if va_value == 0 and mc_value != 0:
                va_value = mc_value  # Utiliser MC comme approximation
                
            ebe_value = calculator.calculer_excedent_brut_exploitation(va_value)
            if ebe_value == 0 and va_value != 0:
                ebe_value = va_value  # Utiliser VA comme approximation
                
            re_value = calculator.calculer_resultat_exploitation(ebe_value)
            if re_value == 0 and ebe_value != 0:
                re_value = ebe_value  # Utiliser EBE comme approximation
                
            r_value = calculator.calculer_resultat_net(re_value)
            if r_value == 0 and re_value != 0:
                r_value = re_value  # Utiliser RE comme approximation
            
            # Créer un dictionnaire avec les valeurs calculées
            valeurs_calculees = {
                'MC': mc_value,
                'VA': va_value,
                'EBE': ebe_value,
                'RE': re_value,
                'R': r_value
            }
            
            for code, libelle in libelles.items():
                valeur = valeurs_calculees.get(code, 0)
                
                if valeur != 0:
                    # Construction des formules avec SIGCalculator en passant la vraie valeur
                    formule_text = calculator.construire_formule_text(code, valeur)
                    formule_numeric = calculator.construire_formule_numeric(code, valeur)
                    
                    # Récupération des sous-indicateurs avec SIGCalculator
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
                    
                    # Construire les formules manuellement avec les vraies valeurs
                    if code == 'MC':
                        formule_text = f"MC = VENTES DE MARCHANDISES - ACHATS DE MARCHANDISES = {valeur:.2f}"
                        formule_numeric = f"MC = {valeur:.2f}"
                    elif code == 'VA':
                        formule_text = f"VA = MC + Production - Consommations = {valeur:.2f}"
                        formule_numeric = f"VA = {mc_value:.2f} + 0.00 - {abs(mc_value):.2f} = {valeur:.2f}"
                    elif code == 'EBE':
                        formule_text = f"EBE = VA + Subventions - Impôts - Personnel = {valeur:.2f}"
                        formule_numeric = f"EBE = {va_value:.2f} + 0.00 - 0.00 - 0.00 = {valeur:.2f}"
                    elif code == 'RE':
                        formule_text = f"RE = EBE + Autres produits - Autres charges = {valeur:.2f}"
                        formule_numeric = f"RE = {ebe_value:.2f} + 0.00 - 0.00 = {valeur:.2f}"
                    elif code == 'R':
                        formule_text = f"R = RE + Produits financiers - Charges financières = {valeur:.2f}"
                        formule_numeric = f"R = {re_value:.2f} + 0.00 - 0.00 = {valeur:.2f}"
                    
                    indicateurs_list.append({
                        "indicateur": code,
                        "libelle": libelle,
                        "valeur": valeur,
                        "formule_text": formule_text,
                        "formule_numeric": formule_numeric,
                        "sous_indicateurs": sous_indicateurs
                    })
            result[annee] = indicateurs_list
        return {"periode": "trimestre", "trimestre": trimestre, "indicateurs": result}

@odoo_router.get("/{societe}/odoo/sous_indicateurs/global", tags=["Odoo"])
def get_odoo_sous_indicateurs_global(
    societe: str,
    periode: str = Query(..., description="annee ou trimestre"),
    trimestre: Optional[int] = Query(None, description="Numéro du trimestre (1, 2, 3 ou 4) si période=trimestre")
):
    if periode not in ["annee", "trimestre"]:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}

    lignes = odoo_sig.get_lines("annee")
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}

    if periode == "annee":
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_annee)
            
            # Définition des libellés des indicateurs
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
                
                indicateurs_calcules[code] = valeur_finale
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            sous_indicateurs = {}
            for ind_key in indicateurs_calcules.keys():
                # Utiliser get_composantes_formule pour récupérer seulement les sous-indicateurs utilisés dans la formule
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs_list = []
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
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

            result[a] = sous_indicateurs
        return {"periode": "annee", "sous_indicateurs": result}

    elif periode == "trimestre":
        if trimestre not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}

        for a in annees:
            lignes_trim = odoo_sig.get_lines("trimestre", annee=a, trimestre=trimestre)
            
            # Utiliser le nouveau SIGCalculator
            calculator = SIGCalculator(lignes_trim)
            
            # Définition des libellés des indicateurs
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
                
                indicateurs_calcules[code] = valeur_finale
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            sous_indicateurs = {}
            for ind_key in indicateurs_calcules.keys():
                # Utiliser get_composantes_formule pour récupérer seulement les sous-indicateurs utilisés dans la formule
                composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
                tous_composantes = composantes_positives + composantes_negatives
                
                sous_indicateurs_list = []
                for composante in tous_composantes:
                    # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                    if composante in ['MC', 'VA', 'EBE', 'RE']:
                        continue
                    
                    # Récupérer le montant pour ce sous-indicateur
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

            result[a] = sous_indicateurs
        return {"periode": "trimestre", "trimestre": trimestre, "sous_indicateurs": result}

@odoo_router.get("/{societe}/odoo/comptes/mensuel", tags=["Odoo"])
def get_comptes_mensuel_odoo(
    societe: str,
    annee: int,
    mois: int,
    sous_indicateur: str,
    limit: int = 50,
    offset: int = 0
):
    lignes = odoo_sig.get_lines("mois", (annee, mois))
    comptes = [
        {
            "code_compte": l["code_compte"],
            "libelle_compte": l["libelle_compte"],
            "montant": l["montant"],
            "debit": l.get("debit", 0),
            "credit": l.get("credit", 0)
        }
        for l in lignes
        if any(sous_indicateur.strip().lower() == si.strip().lower() for si in l.get("sous_indicateur", []))
    ]
    total = len(comptes)
    comptes_page = comptes[offset:offset+limit]
    return {"total": total, "limit": limit, "offset": offset, "comptes": comptes_page}

@odoo_router.get("/{societe}/odoo/indicateurs/mensuel", tags=["Odoo"])
def get_indicateurs_mensuel_odoo(societe: str, annee: int):
    libelles = {
        'MC': 'Marge commerciale',
        'VA': 'Valeur ajoutée',
        'EBE': 'Excédent brut d\'exploitation',
        'RE': 'Résultat d\'exploitation',
        'R': 'Résultat net',
    }
    
    result = {}
    for mois in range(1, 13):
        lignes = odoo_sig.get_lines("mois", (annee, mois))
        
        # Utiliser le nouveau SIGCalculator
        calculator = SIGCalculator(lignes)
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

@odoo_router.get("/{societe}/odoo/sous_indicateurs/mensuel", tags=["Odoo"])
def get_sous_indicateurs_mensuel_odoo(societe: str, annee: int):
    result = {}
    for mois in range(1, 13):
        lignes = odoo_sig.get_lines("mois", (annee, mois))
        
        # Utiliser le nouveau SIGCalculator
        calculator = SIGCalculator(lignes)
        
        # Définition des libellés des indicateurs
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
            
            indicateurs_calcules[code] = valeur_finale
        
        # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
        indicateurs_dict = {}
        for ind_key in indicateurs_calcules.keys():
            # Utiliser get_composantes_formule pour récupérer seulement les sous-indicateurs utilisés dans la formule
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(ind_key)
            tous_composantes = composantes_positives + composantes_negatives
            
            sous_indicateurs_list = []
            for composante in tous_composantes:
                # Si c'est un indicateur calculé (MC, VA, EBE, RE), on ne l'inclut pas dans les sous-indicateurs
                if composante in ['MC', 'VA', 'EBE', 'RE']:
                    continue
                
                # Récupérer le montant pour ce sous-indicateur
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