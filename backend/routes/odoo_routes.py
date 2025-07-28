from fastapi import APIRouter, Query, Response
from typing import Optional
from controllers.odoo_sig_controller import OdooSIGController
import json

odoo_router = APIRouter()
odoo_sig = OdooSIGController()

@odoo_router.get("/odoo/comptes/global", tags=["Odoo"])
def get_comptes_global_odoo(
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
                    "date_ecriture": l.get("date"),  # ou "l.get('date_ecriture')" si tu l'ajoutes dans tes lignes
                    "document": l.get("document"),   # ou à ajuster selon tes champs
                    "utilisateur": l.get("utilisateur")  # idem
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
                    "date_ecriture": l.get("date"),
                    "document": l.get("document"),
                    "utilisateur": l.get("utilisateur")
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

@odoo_router.get("/odoo/indicateurs/global", tags=["Odoo"])
def get_odoo_indicateurs_global(
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

@odoo_router.get("/odoo/sous_indicateurs/global", tags=["Odoo"])
def get_odoo_sous_indicateurs_global(
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
                    sous_indicateurs[ind_key] = odoo_sig.get_sous_indicateurs(ind_key, periode, trimestre)

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
                    sous_indicateurs[ind_key] = odoo_sig.get_sous_indicateurs(lignes_trim, ind_key)

            result[a] = sous_indicateurs
        return {"periode": "trimestre", "trimestre": trimestre, "sous_indicateurs": result}

