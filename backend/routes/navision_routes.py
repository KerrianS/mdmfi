# -*- coding: utf-8 -*-
from fastapi import APIRouter
from controllers.navision_sig_controller import NavisionSIGController
from models.PlanComptable import MappingIndicateurSIG
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
    """
    result = {}
    
    # Helper functions pour sommer les montants (EXCLUANT les comptes de tiers)
    def get_montant_par_indicateur_sous_ind(indicateur, sous_indicateurs_list, exclure_tiers=True):
        total = 0
        for l in lignes:
            if l.get('indicateur') == indicateur:
                # Exclure les comptes de tiers (classes 4 et 5) sauf si explicitement demandé
                code_compte = str(l.get('code_compte', ''))
                if exclure_tiers and (code_compte.startswith('4') or code_compte.startswith('5')):
                    continue
                    
                if any(si in l.get('sous_indicateur', []) for si in sous_indicateurs_list):
                    total += l['montant']
        return total
    
    def get_montant_par_indicateur(indicateur, exclure_tiers=True):
        total = 0
        for l in lignes:
            if l.get('indicateur') == indicateur:
                # Exclure les comptes de tiers (classes 4 et 5) sauf si explicitement demandé
                code_compte = str(l.get('code_compte', ''))
                if exclure_tiers and (code_compte.startswith('4') or code_compte.startswith('5')):
                    continue
                total += l['montant']
        return total
    
    # 1. MARGE COMMERCIALE (MC)
    # MC = Ventes de marchandises - Coût d'achat des marchandises vendues
    ventes_marchandises = get_montant_par_indicateur_sous_ind('MC', ['VENTES DE MARCHANDISES', 'VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES', 'TVA COLLECTEE'])
    cout_achat_marchandises = get_montant_par_indicateur_sous_ind('MC', ['ACHATS DE MARCHANDISES'])
    
    # Si pas de sous-indicateurs spécifiques, prendre tout MC (hors tiers)
    if ventes_marchandises == 0 and cout_achat_marchandises == 0:
        mc_total = get_montant_par_indicateur('MC')
        if mc_total != 0:
            result['MC'] = mc_total
    else:
        mc_calculee = ventes_marchandises - abs(cout_achat_marchandises)
        if mc_calculee != 0:
            result['MC'] = mc_calculee
    
    # 2. VALEUR AJOUTÉE (VA)
    # VA = Production de l'exercice - Consommations de l'exercice en provenance de tiers
    
    # Production = MC + Production vendue + Production stockée + Production immobilisée
    mc_value = result.get('MC', 0)
    prestations_services = get_montant_par_indicateur_sous_ind('VA', ['PRESTATIONS DE SERVICES'])
    ventes_produits = get_montant_par_indicateur_sous_ind('VA', ['VENTES DE PRODUITS FINIS'])
    production_stockee = get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION STOCKÉE'])
    production_immobilisee = get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION IMMOBILISÉE'])
    
    production_exercice = mc_value + prestations_services + ventes_produits + production_stockee + production_immobilisee
    
    # Consommations = Achats stockés + Achats non stockés + Fournitures + Services extérieurs + Autres services extérieurs
    achats_stockes = get_montant_par_indicateur_sous_ind('VA', ['ACHATS STOCKES'])
    achats_non_stockes = get_montant_par_indicateur_sous_ind('VA', ['ACHATS NON STOCKES'])
    fournitures = get_montant_par_indicateur_sous_ind('VA', ['FOURNITURES'])
    services_exterieurs = get_montant_par_indicateur_sous_ind('EBE', ['SERVICES EXTÉRIEURS'])
    autres_services_exterieurs = get_montant_par_indicateur_sous_ind('EBE', ['AUTRES SERVICES EXTÉRIEURS'])
    
    consommations_tiers = abs(achats_stockes) + abs(achats_non_stockes) + abs(fournitures) + abs(services_exterieurs) + abs(autres_services_exterieurs)
    
    # Calcul de la VA selon la formule SIG standard
    va_calculee = production_exercice - consommations_tiers
    if va_calculee != 0:
        result['VA'] = va_calculee
    elif production_exercice == 0 and consommations_tiers == 0:
        # Si aucune donnée, essayer de récupérer la VA directe
        va_direct = get_montant_par_indicateur('VA')
        if va_direct != 0:
            result['VA'] = va_direct
    
    # 3. EXCÉDENT BRUT D'EXPLOITATION (EBE)
    # EBE = VA + Subventions d'exploitation - Impôts et taxes - Charges de personnel
    va_value = result.get('VA', 0)
    subventions_exploitation = get_montant_par_indicateur_sous_ind('EBE', ['SUBVENTIONS D\'EXPLOITATION'])
    impots_taxes = get_montant_par_indicateur_sous_ind('EBE', ['IMPÔTS ET TAXES'])
    charges_personnel = get_montant_par_indicateur_sous_ind('EBE', ['CHARGES DE PERSONNEL'])
    
    if va_value != 0 or subventions_exploitation != 0 or impots_taxes != 0 or charges_personnel != 0:
        result['EBE'] = va_value + subventions_exploitation - abs(impots_taxes) - abs(charges_personnel)
    
    # 4. RÉSULTAT D'EXPLOITATION (RE)
    # RE = EBE + Autres produits - Autres charges
    ebe_value = result.get('EBE', 0)
    autres_produits = get_montant_par_indicateur_sous_ind('RE', ['AUTRES PRODUITS DE GESTION COURANTE'])
    reprises_amortissements = get_montant_par_indicateur_sous_ind('RE', ['REPRISES AMORTISSEMENTS'])
    autres_charges = get_montant_par_indicateur_sous_ind('RE', ['AUTRES CHARGES DE GESTION COURANTE'])
    dotations_amortissements = get_montant_par_indicateur_sous_ind('RE', ['DOTATIONS AMORTISSEMENTS'])
    
    if ebe_value != 0 or autres_produits != 0 or reprises_amortissements != 0 or autres_charges != 0 or dotations_amortissements != 0:
        result['RE'] = ebe_value + autres_produits + reprises_amortissements - abs(autres_charges) - abs(dotations_amortissements)
    
    # 5. RÉSULTAT NET (R)
    # R = Produits - Charges (approche globale)
    # Ou R = RE + Résultat financier + Résultat exceptionnel - Impôts sur les bénéfices
    re_value = result.get('RE', 0)
    
    # Résultat financier
    produits_financiers = get_montant_par_indicateur_sous_ind('R', ['PRODUITS FINANCIERS'])
    charges_financieres = get_montant_par_indicateur_sous_ind('R', ['CHARGES FINANCIÈRES'])
    resultat_financier = produits_financiers - abs(charges_financieres)
    
    # Résultat exceptionnel
    produits_exceptionnels = get_montant_par_indicateur_sous_ind('R', ['PRODUITS EXCEPTIONNELS'])
    charges_exceptionnelles = get_montant_par_indicateur_sous_ind('R', ['CHARGES EXCEPTIONNELLES'])
    resultat_exceptionnel = produits_exceptionnels - abs(charges_exceptionnelles)
    
    # Impôts sur les bénéfices
    impots_benefices = get_montant_par_indicateur_sous_ind('R', ['IMPÔTS SUR LES BÉNÉFICES'])
    
    if (re_value != 0 or resultat_financier != 0 or resultat_exceptionnel != 0 or impots_benefices != 0):
        result['R'] = re_value + resultat_financier + resultat_exceptionnel - abs(impots_benefices)
    
    return result

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
    result = {}
    # On suppose que MappingIndicateurSIG a des méthodes pour obtenir libellé, initiales, formule d'un sous-indicateur
    for mois in range(1, 13):
        lignes = navision_sig.get_lines("mois", annee=annee, mois=mois)
        indicateurs_calcules = calcul_sig_adapte(lignes)
        indicateurs_dict = {}
        for ind_key, valeur in indicateurs_calcules.items():
            sous_indicateurs_montants = {}
            for l in lignes:
                if l.get('indicateur') == ind_key:
                    for si in l.get('sous_indicateur', []):
                        if si:
                            sous_indicateurs_montants[si] = sous_indicateurs_montants.get(si, 0) + l.get('montant', 0)
            sous_indicateurs = []
            for si, montant in sous_indicateurs_montants.items():
                # Récupérer libellé, initiales, formule depuis le mapping si possible
                libelle = MappingIndicateurSIG.get_libelle(si) if hasattr(MappingIndicateurSIG, 'get_libelle') else si
                initiales = MappingIndicateurSIG.get_initiales(si) if hasattr(MappingIndicateurSIG, 'get_initiales') else ''
                formule = MappingIndicateurSIG.get_formule(si) if hasattr(MappingIndicateurSIG, 'get_formule') else ''
                sous_indicateurs.append({
                    "sousIndicateur": si,
                    "libelle": libelle,
                    "initiales": initiales,
                    "formule": formule,
                    "montant": montant
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
    result = {}
    for mois in range(1, 13):
        lignes = navision_sig.get_lines("mois", annee=annee, mois=mois)
        # Calcul SIG avec formules comptables adaptées aux vrais sous-indicateurs
        indicateurs_calcules = calcul_sig_adapte(lignes)
        
        indicateurs_list = []
        # Bloc libellés à corriger partout où il apparaît :
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée',
            'EBE': 'Excédent brut d’exploitation',
            'RE': 'Résultat d’exploitation',
            'R': 'Résultat net',
        }
        associe_mapping = MappingIndicateurSIG.get_associe_mapping()
        for code, montant in indicateurs_calcules.items():
            # Construction des champs manquants
            formule_text = ""
            formule_numeric = ""
            valeur_formule = montant
            ecart = 0
            
            # MC
            if code == "MC":
                # Calculer tous les sous-indicateurs de MC
                ventes_marchandises = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE MARCHANDISES"]))
                ventes_produits_finis = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE PRODUITS FINIS"]))
                ventes_services = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE SERVICES"]))
                prestations_services = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["PRESTATIONS DE SERVICES"]))
                tva_collectee = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["TVA COLLECTEE"]))
                achats_marchandises = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS DE MARCHANDISES"]))
                
                # Construire la formule avec tous les sous-indicateurs disponibles
                partie_plus = []
                partie_moins = []
                
                # Partie positive : Ventes et prestations
                if ventes_marchandises != 0:
                    partie_plus.append(f"VENTES DE MARCHANDISES ({ventes_marchandises:.2f})")
                if ventes_produits_finis != 0:
                    partie_plus.append(f"VENTES DE PRODUITS FINIS ({ventes_produits_finis:.2f})")
                if ventes_services != 0:
                    partie_plus.append(f"VENTES DE SERVICES ({ventes_services:.2f})")
                if prestations_services != 0:
                    partie_plus.append(f"PRESTATIONS DE SERVICES ({prestations_services:.2f})")
                if tva_collectee != 0:
                    partie_plus.append(f"TVA COLLECTEE ({tva_collectee:.2f})")
                
                # Partie négative : Achats
                if achats_marchandises != 0:
                    partie_moins.append(f"ACHATS DE MARCHANDISES ({abs(achats_marchandises):.2f})")
                
                # Construire la formule
                if not partie_plus and partie_moins:
                    formule_text = f"MC = - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"MC = - ({' + '.join([f'{abs(achats_marchandises):.2f}' for v in [achats_marchandises] if v != 0])}) = {montant:.2f}"
                elif not partie_plus and not partie_moins:
                    formule_text = f"MC = 0 = {montant:.2f}"
                    formule_numeric = f"MC = 0 = {montant:.2f}"
                else:
                    formule_text = f"MC = {' + '.join(partie_plus)} - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"MC = ({' + '.join([f'{v:.2f}' for v in [ventes_marchandises, ventes_produits_finis, ventes_services, prestations_services, tva_collectee] if v != 0])}) - ({' + '.join([f'{abs(v):.2f}' for v in [achats_marchandises] if v != 0])}) = {montant:.2f}"
                
                valeur_formule = montant
            
            # VA
            elif code == "VA":
                mc_value = indicateurs_calcules.get('MC', 0)
                
                # Calculer les montants selon les sous-indicateurs disponibles
                prestations_services = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRESTATIONS DE SERVICES"]))
                ventes_produits = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE PRODUITS FINIS"]))
                production_stockee = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRODUCTION STOCKÉE"]))
                production_immobilisee = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRODUCTION IMMOBILISÉE"]))
                achats_stockes = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS STOCKES"]))
                achats_non_stockes = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS NON STOCKES"]))
                fournitures = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["FOURNITURES"]))
                services_exterieurs = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["SERVICES EXTÉRIEURS"]))
                autres_services_exterieurs = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES SERVICES EXTÉRIEURS"]))
                
                # Construire la formule selon les sous-indicateurs disponibles
                partie_plus = []
                partie_moins = []
                
                # Partie positive : MC + Production
                if mc_value != 0:
                    partie_plus.append(f"MC ({mc_value:.2f})")
                if prestations_services != 0:
                    partie_plus.append(f"PRESTATIONS DE SERVICES ({prestations_services:.2f})")
                if ventes_produits != 0:
                    partie_plus.append(f"VENTES DE PRODUITS FINIS ({ventes_produits:.2f})")
                if production_stockee != 0:
                    partie_plus.append(f"PRODUCTION STOCKÉE ({production_stockee:.2f})")
                if production_immobilisee != 0:
                    partie_plus.append(f"PRODUCTION IMMOBILISÉE ({production_immobilisee:.2f})")
                
                # Partie négative : Consommations
                if achats_stockes != 0:
                    partie_moins.append(f"ACHATS STOCKES ({abs(achats_stockes):.2f})")
                if achats_non_stockes != 0:
                    partie_moins.append(f"ACHATS NON STOCKES ({abs(achats_non_stockes):.2f})")
                if fournitures != 0:
                    partie_moins.append(f"FOURNITURES ({abs(fournitures):.2f})")
                if services_exterieurs != 0:
                    partie_moins.append(f"SERVICES EXTÉRIEURS ({abs(services_exterieurs):.2f})")
                if autres_services_exterieurs != 0:
                    partie_moins.append(f"AUTRES SERVICES EXTÉRIEURS ({abs(autres_services_exterieurs):.2f})")
                
                # Gestion des cas où il n'y a que des négatifs
                if not partie_plus and partie_moins:
                    formule_text = f"VA = - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"VA = - ({' + '.join([f'{abs(v):.2f}' for v in [achats_stockes, achats_non_stockes, fournitures, services_exterieurs, autres_services_exterieurs] if v != 0])}) = {montant:.2f}"
                elif not partie_plus and not partie_moins:
                    formule_text = f"VA = 0 = {montant:.2f}"
                    formule_numeric = f"VA = 0 = {montant:.2f}"
                else:
                    formule_text = f"VA = {' + '.join(partie_plus)} - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"VA = ({' + '.join([f'{v:.2f}' for v in [mc_value, prestations_services, ventes_produits, production_stockee, production_immobilisee] if v != 0])}) - ({' + '.join([f'{abs(v):.2f}' for v in [achats_stockes, achats_non_stockes, fournitures, services_exterieurs, autres_services_exterieurs] if v != 0])}) = {montant:.2f}"
                valeur_formule = montant
            
            # EBE
            elif code == "EBE":
                va_value = indicateurs_calcules.get('VA', 0)
                subventions = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["SUBVENTIONS D'EXPLOITATION"]))
                impots_taxes = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["IMPÔTS ET TAXES"]))
                charges_personnel = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES DE PERSONNEL"]))
                formule_text = f"EBE = VA ({va_value:.2f}) + SUBVENTIONS D'EXPLOITATION ({subventions:.2f}) - IMPÔTS ET TAXES ({abs(impots_taxes):.2f}) - CHARGES DE PERSONNEL ({abs(charges_personnel):.2f}) = {montant:.2f}"
                formule_numeric = f"EBE = ({va_value:.2f} + {subventions:.2f}) - ({abs(impots_taxes):.2f} + {abs(charges_personnel):.2f}) = {montant:.2f}"
                valeur_formule = montant
            
            # RE
            elif code == "RE":
                ebe_value = indicateurs_calcules.get('EBE', 0)
                autres_produits = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES PRODUITS DE GESTION COURANTE"]))
                reprises_amortissements = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["REPRISES AMORTISSEMENTS"]))
                autres_charges = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES CHARGES DE GESTION COURANTE"]))
                dotations_amortissements = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["DOTATIONS AMORTISSEMENTS"]))
                
                # Construire la formule selon les sous-indicateurs disponibles
                partie_plus = []
                partie_moins = []
                
                # Partie positive
                if ebe_value != 0:
                    partie_plus.append(f"EBE ({ebe_value:.2f})")
                if autres_produits != 0:
                    partie_plus.append(f"AUTRES PRODUITS DE GESTION COURANTE ({autres_produits:.2f})")
                if reprises_amortissements != 0:
                    partie_plus.append(f"REPRISES AMORTISSEMENTS ({reprises_amortissements:.2f})")
                
                # Partie négative
                if autres_charges != 0:
                    partie_moins.append(f"AUTRES CHARGES DE GESTION COURANTE ({abs(autres_charges):.2f})")
                if dotations_amortissements != 0:
                    partie_moins.append(f"DOTATIONS AMORTISSEMENTS ({abs(dotations_amortissements):.2f})")
                
                # Gestion des cas où il n'y a que des négatifs ou rien
                if not partie_plus and partie_moins:
                    formule_text = f"RE = - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"RE = - ({' + '.join([f'{abs(v):.2f}' for v in [autres_charges, dotations_amortissements] if v != 0])}) = {montant:.2f}"
                elif not partie_plus and not partie_moins:
                    formule_text = f"RE = 0 = {montant:.2f}"
                    formule_numeric = f"RE = 0 = {montant:.2f}"
                else:
                    formule_text = f"RE = {' + '.join(partie_plus)} - {' - '.join(partie_moins)} = {montant:.2f}"
                    formule_numeric = f"RE = ({' + '.join([f'{v:.2f}' for v in [ebe_value, autres_produits, reprises_amortissements] if v != 0])}) - ({' + '.join([f'{abs(v):.2f}' for v in [autres_charges, dotations_amortissements] if v != 0])}) = {montant:.2f}"
                valeur_formule = montant
            
            # R
            elif code == "R":
                re_value = indicateurs_calcules.get('RE', 0)
                produits_financiers = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["PRODUITS FINANCIERS"]))
                charges_financieres = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES FINANCIÈRES"]))
                produits_exceptionnels = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["PRODUITS EXCEPTIONNELS"]))
                charges_exceptionnelles = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES EXCEPTIONNELLES"]))
                impots_benefices = sum(l.get('montant', 0) for l in lignes if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["IMPÔTS SUR LES BÉNÉFICES"]))
                formule_text = f"R = RE ({re_value:.2f}) + PRODUITS FINANCIERS ({produits_financiers:.2f}) + PRODUITS EXCEPTIONNELS ({produits_exceptionnels:.2f}) - CHARGES FINANCIÈRES ({abs(charges_financieres):.2f}) - CHARGES EXCEPTIONNELLES ({abs(charges_exceptionnelles):.2f}) - IMPÔTS SUR LES BÉNÉFICES ({abs(impots_benefices):.2f}) = {montant:.2f}"
                formule_numeric = f"R = ({re_value:.2f} + {produits_financiers:.2f} + {produits_exceptionnels:.2f}) - ({abs(charges_financieres):.2f} + {abs(charges_exceptionnelles):.2f} + {abs(impots_benefices):.2f}) = {montant:.2f}"
                valeur_formule = montant
            
            indicateurs_list.append({
                "indicateur": code,
                "libelle": libelles.get(code, code),
                "valeur_calculee": montant,
                "formule_text": formule_text,
                "formule_numeric": formule_numeric,
                "valeur_formule": valeur_formule,
                "ecart": ecart,
                "associe": associe_mapping.get(code, [])
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
        'EBE': 'Excédent brut d’exploitation',
        'RE': 'Résultat d’exploitation',
        'R': 'Résultat net',
    }
    associe_mapping = MappingIndicateurSIG.get_associe_mapping()
    if periode == "annee":
        lignes = navision_sig.get_lines("annee")
        annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
        result = {}
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            indicateurs_calcules = calcul_sig_adapte(lignes_annee)
            indicateurs_list = []
            for code, montant in indicateurs_calcules.items():
                # Construction des champs manquants
                formule_text = ""
                formule_numeric = ""
                valeur_formule = montant
                ecart = 0
                # MC
                if code == "MC":
                    # Utiliser uniquement les sous-indicateurs présents dans associe
                    associe_list = associe_mapping.get(code, [])
                    ventes_marchandises = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE MARCHANDISES", "VENTES DE PRODUITS FINIS", "VENTES DE SERVICES", "PRESTATIONS DE SERVICES", "TVA COLLECTEE"]))
                    achats_marchandises = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'MC' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS DE MARCHANDISES"]))
                    formule_text = f"MC = VENTES DE MARCHANDISES ({ventes_marchandises:.2f}) - ACHATS DE MARCHANDISES ({abs(achats_marchandises):.2f}) = {montant:.2f}"
                    formule_numeric = f"MC = {ventes_marchandises:.2f} - {abs(achats_marchandises):.2f} = {montant:.2f}"
                    valeur_formule = montant
                # VA
                elif code == "VA":
                    mc_value = indicateurs_calcules.get('MC', 0)
                    # Utiliser uniquement les sous-indicateurs présents dans associe
                    associe_list = associe_mapping.get(code, [])
                    
                    # Calculer les montants selon les sous-indicateurs disponibles
                    prestations_services = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRESTATIONS DE SERVICES"]))
                    ventes_produits = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["VENTES DE PRODUITS FINIS"]))
                    production_stockee = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRODUCTION STOCKÉE"]))
                    production_immobilisee = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["PRODUCTION IMMOBILISÉE"]))
                    achats_stockes = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS STOCKES"]))
                    achats_non_stockes = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["ACHATS NON STOCKES"]))
                    fournitures = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'VA' and any(si in l.get('sous_indicateur', []) for si in ["FOURNITURES"]))
                    services_exterieurs = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["SERVICES EXTÉRIEURS"]))
                    autres_services_exterieurs = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES SERVICES EXTÉRIEURS"]))
                    
                    # Construire la formule selon les sous-indicateurs disponibles
                    partie_plus = []
                    partie_moins = []
                    
                    # Partie positive : MC + Production
                    if mc_value != 0:
                        partie_plus.append(f"MC ({mc_value:.2f})")
                    if prestations_services != 0:
                        partie_plus.append(f"PRESTATIONS DE SERVICES ({prestations_services:.2f})")
                    if ventes_produits != 0:
                        partie_plus.append(f"VENTES DE PRODUITS FINIS ({ventes_produits:.2f})")
                    if production_stockee != 0:
                        partie_plus.append(f"PRODUCTION STOCKÉE ({production_stockee:.2f})")
                    if production_immobilisee != 0:
                        partie_plus.append(f"PRODUCTION IMMOBILISÉE ({production_immobilisee:.2f})")
                    
                    # Partie négative : Consommations
                    if achats_stockes != 0:
                        partie_moins.append(f"ACHATS STOCKES ({abs(achats_stockes):.2f})")
                    if achats_non_stockes != 0:
                        partie_moins.append(f"ACHATS NON STOCKES ({abs(achats_non_stockes):.2f})")
                    if fournitures != 0:
                        partie_moins.append(f"FOURNITURES ({abs(fournitures):.2f})")
                    if services_exterieurs != 0:
                        partie_moins.append(f"SERVICES EXTÉRIEURS ({abs(services_exterieurs):.2f})")
                    if autres_services_exterieurs != 0:
                        partie_moins.append(f"AUTRES SERVICES EXTÉRIEURS ({abs(autres_services_exterieurs):.2f})")
                    
                    # Gestion des cas où il n'y a que des négatifs
                    if not partie_plus and partie_moins:
                        formule_text = f"VA = - {' - '.join(partie_moins)} = {montant:.2f}"
                        formule_numeric = f"VA = - ({' + '.join([f'{abs(v):.2f}' for v in [achats_stockes, achats_non_stockes, fournitures, services_exterieurs, autres_services_exterieurs] if v != 0])}) = {montant:.2f}"
                    elif not partie_plus and not partie_moins:
                        formule_text = f"VA = 0 = {montant:.2f}"
                        formule_numeric = f"VA = 0 = {montant:.2f}"
                    else:
                        formule_text = f"VA = {' + '.join(partie_plus)} - {' - '.join(partie_moins)} = {montant:.2f}"
                        formule_numeric = f"VA = ({' + '.join([f'{v:.2f}' for v in [mc_value, prestations_services, ventes_produits, production_stockee, production_immobilisee] if v != 0])}) - ({' + '.join([f'{abs(v):.2f}' for v in [achats_stockes, achats_non_stockes, fournitures, services_exterieurs, autres_services_exterieurs] if v != 0])}) = {montant:.2f}"
                    valeur_formule = montant
                # EBE
                elif code == "EBE":
                    va_value = indicateurs_calcules.get('VA', 0)
                    subventions = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["SUBVENTIONS D'EXPLOITATION"]))
                    impots_taxes = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["IMPÔTS ET TAXES"]))
                    charges_personnel = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'EBE' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES DE PERSONNEL"]))
                    formule_text = f"EBE = VA ({va_value:.2f}) + SUBVENTIONS D'EXPLOITATION ({subventions:.2f}) - IMPÔTS ET TAXES ({abs(impots_taxes):.2f}) - CHARGES DE PERSONNEL ({abs(charges_personnel):.2f}) = {montant:.2f}"
                    formule_numeric = f"EBE = ({va_value:.2f} + {subventions:.2f}) - ({abs(impots_taxes):.2f} + {abs(charges_personnel):.2f}) = {montant:.2f}"
                    valeur_formule = montant
                # RE
                elif code == "RE":
                    ebe_value = indicateurs_calcules.get('EBE', 0)
                    autres_produits = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES PRODUITS DE GESTION COURANTE"]))
                    reprises_amortissements = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["REPRISES AMORTISSEMENTS"]))
                    autres_charges = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["AUTRES CHARGES DE GESTION COURANTE"]))
                    dotations_amortissements = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'RE' and any(si in l.get('sous_indicateur', []) for si in ["DOTATIONS AMORTISSEMENTS"]))
                    
                    # Construire la formule selon les sous-indicateurs disponibles
                    partie_plus = []
                    partie_moins = []
                    
                    # Partie positive
                    if ebe_value != 0:
                        partie_plus.append(f"EBE ({ebe_value:.2f})")
                    if autres_produits != 0:
                        partie_plus.append(f"AUTRES PRODUITS DE GESTION COURANTE ({autres_produits:.2f})")
                    if reprises_amortissements != 0:
                        partie_plus.append(f"REPRISES AMORTISSEMENTS ({reprises_amortissements:.2f})")
                    
                    # Partie négative
                    if autres_charges != 0:
                        partie_moins.append(f"AUTRES CHARGES DE GESTION COURANTE ({abs(autres_charges):.2f})")
                    if dotations_amortissements != 0:
                        partie_moins.append(f"DOTATIONS AMORTISSEMENTS ({abs(dotations_amortissements):.2f})")
                    
                    # Gestion des cas où il n'y a que des négatifs ou rien
                    if not partie_plus and partie_moins:
                        formule_text = f"RE = - {' - '.join(partie_moins)} = {montant:.2f}"
                        formule_numeric = f"RE = - ({' + '.join([f'{abs(v):.2f}' for v in [autres_charges, dotations_amortissements] if v != 0])}) = {montant:.2f}"
                    elif not partie_plus and not partie_moins:
                        formule_text = f"RE = 0 = {montant:.2f}"
                        formule_numeric = f"RE = 0 = {montant:.2f}"
                    else:
                        formule_text = f"RE = {' + '.join(partie_plus)} - {' - '.join(partie_moins)} = {montant:.2f}"
                        formule_numeric = f"RE = ({' + '.join([f'{v:.2f}' for v in [ebe_value, autres_produits, reprises_amortissements] if v != 0])}) - ({' + '.join([f'{abs(v):.2f}' for v in [autres_charges, dotations_amortissements] if v != 0])}) = {montant:.2f}"
                    valeur_formule = montant
                # R
                elif code == "R":
                    re_value = indicateurs_calcules.get('RE', 0)
                    produits_financiers = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["PRODUITS FINANCIERS"]))
                    charges_financieres = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES FINANCIÈRES"]))
                    produits_exceptionnels = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["PRODUITS EXCEPTIONNELS"]))
                    charges_exceptionnelles = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["CHARGES EXCEPTIONNELLES"]))
                    impots_benefices = sum(l.get('montant', 0) for l in lignes_annee if l.get('indicateur') == 'R' and any(si in l.get('sous_indicateur', []) for si in ["IMPÔTS SUR LES BÉNÉFICES"]))
                    formule_text = f"R = RE ({re_value:.2f}) + PRODUITS FINANCIERS ({produits_financiers:.2f}) + PRODUITS EXCEPTIONNELS ({produits_exceptionnels:.2f}) - CHARGES FINANCIÈRES ({abs(charges_financieres):.2f}) - CHARGES EXCEPTIONNELLES ({abs(charges_exceptionnelles):.2f}) - IMPÔTS SUR LES BÉNÉFICES ({abs(impots_benefices):.2f}) = {montant:.2f}"
                    formule_numeric = f"R = ({re_value:.2f} + {produits_financiers:.2f} + {produits_exceptionnels:.2f}) - ({abs(charges_financieres):.2f} + {abs(charges_exceptionnelles):.2f} + {abs(impots_benefices):.2f}) = {montant:.2f}"
                    valeur_formule = montant
                indicateurs_list.append({
                    "indicateur": code,
                    "libelle": libelles.get(code, code),
                    "valeur_calculee": montant,
                    "formule_text": formule_text,
                    "formule_numeric": formule_numeric,
                    "valeur_formule": valeur_formule,
                    "ecart": ecart,
                    "associe": associe_mapping.get(code, [])
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
            indicateurs_calcules = calcul_sig_adapte(lignes_trim)
            indicateurs_list = []
            for code, montant in indicateurs_calcules.items():
                indicateurs_list.append({
                    "indicateur": code,
                    "libelle": libelles.get(code, code),
                    "valeur": montant,
                    "associe": associe_mapping.get(code, [])
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
            # Utiliser la nouvelle fonction pour avoir les indicateurs
            indicateurs_calcules = calcul_sig_adapte(lignes_annee)
            sous_indicateurs = {}
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            for ind_key in indicateurs_calcules.keys():
                if ind_key:
                    sous_indicateurs[ind_key] = navision_sig.get_sous_indicateurs_from_lines(lignes_annee, ind_key)
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
            # Utiliser la nouvelle fonction pour avoir les indicateurs
            indicateurs_calcules = calcul_sig_adapte(lignes_trim)
            sous_indicateurs = {}
            
            # Pour chaque indicateur calculé, récupérer ses sous-indicateurs
            for ind_key in indicateurs_calcules.keys():
                if ind_key:
                    sous_indicateurs[ind_key] = navision_sig.get_sous_indicateurs_from_lines(lignes_trim, ind_key)
            result[a] = sous_indicateurs
        return {"periode": "trimestre", "trimestre": trimestre_int, "sous_indicateurs": result}
    else:
        return {"error": "Période inconnue. Utilisez 'annee' ou 'trimestre'."}