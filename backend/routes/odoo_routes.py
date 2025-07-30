
from fastapi import APIRouter, Query, Response
from typing import Optional
from controllers.odoo_sig_controller import OdooSIGController
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
        'EBE': 'Excédent brut d’exploitation',
        'RE': 'Résultat d’exploitation',
        'R': 'Résultat net',
    }
    from models.PlanComptable import MappingIndicateurSIG

    lignes = odoo_sig.get_lines("annee")
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}

    if periode == "annee":
        for annee in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == annee]
            indicateurs = odoo_sig.calcul_sig(lignes_annee)
            indicateurs_list = []
            for code, montant in indicateurs.items():
                indicateurs_list.append({
                    "indicateur": code,
                    "libelle": libelles.get(code, code),
                    "valeur": montant
                })
            result[annee] = indicateurs_list
        return {"periode": "annee", "indicateurs": result}

    elif periode == "trimestre":
        if trimestre not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}

        for annee in annees:
            lignes_trim = odoo_sig.get_lines("trimestre", trimestre=trimestre)
            lignes_trim = [l for l in lignes_trim if l.get('annee') == annee]
            indicateurs = odoo_sig.calcul_sig(lignes_trim)
            indicateurs_list = []
            for code, montant in indicateurs.items():
                indicateurs_list.append({
                    "indicateur": code,
                    "libelle": libelles.get(code, code),
                    "valeur": montant
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

    from models.PlanComptable import MappingIndicateurSIG
    lignes = odoo_sig.get_lines("annee")
    annees = sorted({l.get('annee') for l in lignes if l.get('annee')}, reverse=True)[:3]
    result = {}

    if periode == "annee":
        for a in annees:
            lignes_annee = [l for l in lignes if l.get('annee') == a]
            indicateurs = odoo_sig.calcul_sig(lignes_annee)
            sous_indicateurs = {}

            if isinstance(indicateurs, dict):
                indicateur_keys = indicateurs.keys()
            elif isinstance(indicateurs, list):
                indicateur_keys = [i if isinstance(i, str) else i.get("indicateur") for i in indicateurs]
            else:
                indicateur_keys = []

            for ind_key in indicateur_keys:
                if ind_key:
                    sous_indicateurs_list = odoo_sig.get_sous_indicateurs(ind_key, periode, trimestre)
                    for si in sous_indicateurs_list:
                        si["formules"] = MappingIndicateurSIG.get_formule(si.get("sousIndicateur", ""))
                    sous_indicateurs[ind_key] = sous_indicateurs_list

            result[a] = sous_indicateurs
        return {"periode": "annee", "sous_indicateurs": result}

    elif periode == "trimestre":
        if trimestre not in [1, 2, 3, 4]:
            return {"error": "Il faut fournir trimestre (1, 2, 3 ou 4) pour la période trimestre."}

        for a in annees:
            lignes_trim = odoo_sig.get_lines("trimestre", annee=a, trimestre=trimestre)
            indicateurs = odoo_sig.calcul_sig(lignes_trim)
            sous_indicateurs = {}

            if isinstance(indicateurs, dict):
                indicateur_keys = indicateurs.keys()
            elif isinstance(indicateurs, list):
                indicateur_keys = [i if isinstance(i, str) else i.get("indicateur") for i in indicateurs]
            else:
                indicateur_keys = []

            for ind_key in indicateur_keys:
                if ind_key:
                    sous_indicateurs_list = odoo_sig.get_sous_indicateurs(lignes_trim, ind_key)
                    for si in sous_indicateurs_list:
                        si["formules"] = MappingIndicateurSIG.get_formule(si.get("sousIndicateur", ""))
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
        'EBE': 'Excédent brut d’exploitation',
        'RE': 'Résultat d’exploitation',
        'R': 'Résultat net',
    }
    from models.PlanComptable import MappingIndicateurSIG
    result = {}
    for mois in range(1, 13):
        lignes = odoo_sig.get_lines("mois", (annee, mois))
        indicateurs = odoo_sig.calcul_sig(lignes)
        indicateurs_list = []
        for code, montant in indicateurs.items():
            indicateurs_list.append({
                "indicateur": code,
                "libelle": libelles.get(code, code),
                "valeur": montant
            })
        result[mois] = indicateurs_list
    return {"annee": annee, "mois": result}

@odoo_router.get("/{societe}/odoo/sous_indicateurs/mensuel", tags=["Odoo"])
def get_sous_indicateurs_mensuel_odoo(societe: str, annee: int):
    from models.PlanComptable import MappingIndicateurSIG
    result = {}
    for mois in range(1, 13):
        lignes = odoo_sig.get_lines("mois", (annee, mois))
        indicateurs = odoo_sig.calcul_sig(lignes)
        indicateurs_dict = {}
        for ind_key in indicateurs.keys():
            sous_indicateurs_montants = {}
            for l in lignes:
                if l.get('indicateur') == ind_key:
                    for si in l.get('sous_indicateur', []):
                        if si:
                            sous_indicateurs_montants[si] = sous_indicateurs_montants.get(si, 0) + l.get('montant', 0)
            sous_indicateurs = []
            for si, montant in sous_indicateurs_montants.items():
                libelle = MappingIndicateurSIG.get_libelle(si)
                initiales = MappingIndicateurSIG.get_initiales(si)
                formules = MappingIndicateurSIG.get_formule(si)
                sous_indicateurs.append({
                    "sousIndicateur": si,
                    "libelle": libelle,
                    "initiales": initiales,
                    "formules": formules,
                    "montant": montant
                })
            indicateurs_dict[ind_key] = sous_indicateurs
        result[mois] = indicateurs_dict
    return {"annee": annee, "mois": result}