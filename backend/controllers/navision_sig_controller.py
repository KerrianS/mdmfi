# -*- coding: utf-8 -*-
from services.navision.navision_api import NavisionService
from models.PlanComptable import MappingIndicateurSIG
import datetime
import time

class NavisionSIGController:
    def __init__(self, vue="neg_view_entry"):
        self.navision = NavisionService()
        self.vue = vue

    def get_period_filter(self, periode, annee, trimestre=None):
        if periode == "trimestre" and trimestre:
            mois_debut = (trimestre - 1) * 3 + 1
            mois_fin = mois_debut + 2
            if annee is not None:
                # Cas classique : trimestre d'une année précise
                date_debut = f"{annee}-{mois_debut:02d}-01"
                if mois_fin == 12:
                    date_fin = f"{annee}-12-31"
                else:
                    next_month = mois_fin + 1
                    date_fin = (datetime.date(annee, next_month, 1) - datetime.timedelta(days=1)).isoformat()
                return f"date_ecriture.gte.{date_debut}&date_ecriture.lte.{date_fin}"
            else:
                # Cas demandé : tous les trimestres de toutes les années
                # On filtre sur les mois du trimestre, toutes années confondues
                mois = [f"{m:02d}" for m in range(mois_debut, mois_fin + 1)]
                # On retourne une indication spéciale pour le post-traitement
                return f"mois_in.{','.join(mois)}"
        elif periode == "annee" and annee is not None:
            return f"date_ecriture.gte.{annee}-01-01&date_ecriture.lte.{annee}-12-31"
        return ""

    def get_nature_compte(self, code_compte):
        """
        Détermine la nature du compte selon le plan comptable français.
        Retourne 'actif' pour les comptes d'actif et de charge, 'passif' pour les comptes de passif et de produit.
        """
        if not code_compte:
            return 'actif'  # Par défaut
        
        classe = code_compte[:1]
        
        # Comptes d'actif et de charge (solde = Débit - Crédit)
        if classe in ['1', '2', '3', '4', '5', '6']:
            return 'actif'
        
        # Comptes de passif et de produit (solde = Crédit - Débit)
        elif classe in ['7', '8']:
            return 'passif'
        
        # Par défaut
        return 'actif'

    def get_lines(self, periode, annee=None, trimestre=None, mois=None):
        table = self.vue
        fields = "id,date_ecriture,code_compte,description,document,montant,utilisateur,source,dimension_1,dimension_2,debit,credit,trimestre"
        params = [("select", fields)]
        if mois:
            date_debut = f"{annee}-{mois:02d}-01"
            if mois == 12:
                date_fin = f"{annee}-12-31"
            else:
                next_month = mois + 1
                date_fin = (datetime.date(annee, next_month, 1) - datetime.timedelta(days=1)).isoformat()
            params.append(("date_ecriture", f"gte.{date_debut}"))
            params.append(("date_ecriture", f"lte.{date_fin}"))
        elif periode == "trimestre" and trimestre:
            mois_debut = (trimestre - 1) * 3 + 1
            mois_fin = mois_debut + 2
            date_debut = f"{annee}-{mois_debut:02d}-01"
            if mois_fin == 12:
                date_fin = f"{annee}-12-31"
            else:
                next_month = mois_fin + 1
                date_fin = (datetime.date(annee, next_month, 1) - datetime.timedelta(days=1)).isoformat()
            params.append(("date_ecriture", f"gte.{date_debut}"))
            params.append(("date_ecriture", f"lte.{date_fin}"))
        elif periode == "annee" and annee is not None:
            params.append(("date_ecriture", f"gte.{annee}-01-01"))
            params.append(("date_ecriture", f"lte.{annee}-12-31"))
        print(f"[DEBUG] Appel SQL table={table} params={params}")
        start_sql = time.time()
        lines = self.navision.get(table, params=params)
        print(f"[DEBUG] {len(lines)} lignes SQL récupérées en {time.time() - start_sql:.2f}s")
        enriched = []
        mapping_cache = {}
        start_map = time.time()
        for l in lines:
            code = l.get("code_compte", "")
            if code in mapping_cache:
                mapping = mapping_cache[code]
            else:
                mapping = MappingIndicateurSIG.find_best_mapping(code)
                mapping_cache[code] = mapping
            l['classe'] = code[:1] if code else ''
            l['sous_classe'] = code[:2] if code else ''
            l['sss_classe'] = code[:3] if code else ''
            if mapping:
                l['indicateur'] = mapping.indicateur
                l['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
            else:
                l['indicateur'] = None
                l['sous_indicateur'] = []
            l['libelle_compte'] = l.get('description', '')
            
            # Calcul du solde selon la nature du compte
            nature = self.get_nature_compte(code)
            if nature == 'actif':
                # Comptes d'actif et de charge : Solde = Débit - Crédit
                l['montant'] = l.get('debit', 0) - l.get('credit', 0)
            else:
                # Comptes de passif et de produit : Solde = Crédit - Débit
                l['montant'] = l.get('credit', 0) - l.get('debit', 0)
            
            try:
                l['annee'] = int(str(l.get('date_ecriture', ''))[:4])
            except Exception:
                l['annee'] = None
            enriched.append(l)
        print(f"[DEBUG] Mapping SIG terminé en {time.time() - start_map:.2f}s pour {len(lines)} lignes")
        return enriched

    def get_sous_indicateurs_par_annee(self, lignes, classes_autorisees=None, with_initiales=False):
        result = {}
        for l in lignes:
            if classes_autorisees and l.get('classe') not in classes_autorisees:
                continue
            for sous_ind in l.get('sous_indicateur', []):
                if sous_ind:
                    annee = l.get('annee')
                    if annee is not None:
                        if with_initiales:
                            # Format enrichi avec initiales
                            result.setdefault(sous_ind, {})
                            if annee not in result[sous_ind]:
                                result[sous_ind][annee] = {
                                    'sousIndicateur': sous_ind,
                                    'libelle': sous_ind,
                                    'initiales': MappingIndicateurSIG.get_initiales_pour_libelle(sous_ind),
                                    'montant': 0
                                }
                            result[sous_ind][annee]['montant'] += l['montant']
                        else:
                            # Format simple (backward compatibility)
                            result.setdefault(sous_ind, {})
                            result[sous_ind].setdefault(annee, 0)
                            result[sous_ind][annee] += l['montant']
        return result

    def calcul_sig(self, lignes):
        # Copié depuis OdooSIGController
        result = {}
        # --- Calcul de la Marge Commerciale (MC) ---
        # MC = Ventes de marchandises - Achats de marchandises
        has_ventes_mc = any(l['indicateur'] == 'MC' and 'VENTES DE MARCHANDISES' in l['sous_indicateur'] for l in lignes)
        has_achats_mc = any(l['indicateur'] == 'VA' and 'ACHATS DE MARCHANDISES' in l['sous_indicateur'] for l in lignes)
        if has_ventes_mc or has_achats_mc:
            mc_ventes = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and 'VENTES DE MARCHANDISES' in l['sous_indicateur'])
            mc_achats = sum(l['montant'] for l in lignes if l['indicateur'] == 'VA' and 'ACHATS DE MARCHANDISES' in l['sous_indicateur'])
            MC = mc_ventes - mc_achats  # MC = Ventes - Achats
            result['MC'] = MC
        else:
            MC = None
        # --- Calcul de la Valeur Ajoutée (VA) ---
        # VA = MC + Production de l'exercice - Achats - Charges extérieures
        has_prod = any(l['indicateur'] == 'MC' and any(si in l['sous_indicateur'] for si in ['VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES']) for l in lignes)
        has_achats = any(l['indicateur'] in ['MC', 'VA'] and any(si in l['sous_indicateur'] for si in ['ACHATS', 'FOURNITURES', 'ACHATS DE MARCHANDISES']) for l in lignes)
        has_charges_ext = any(l['indicateur'] == 'EBE' and any(si in l['sous_indicateur'] for si in ['SERVICES EXTÉRIEURS', 'AUTRES SERVICES EXTÉRIEURS']) for l in lignes)
        if MC is not None and (has_prod or has_achats or has_charges_ext):
            # Production = ventes de produits finis, services, prestations + production stockée/immobilisée + subventions d'exploitation
            prod = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and any(si in l['sous_indicateur'] for si in ['VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES']))
            prod += sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and any(si in l['sous_indicateur'] for si in ['PRODUCTION STOCKÉE', 'PRODUCTION IMMOBILISÉE', 'SUBVENTIONS D’EXPLOITATION']))
            achats = sum(l['montant'] for l in lignes if l['indicateur'] in ['MC', 'VA'] and any(si in l['sous_indicateur'] for si in ['ACHATS', 'FOURNITURES', 'ACHATS DE MARCHANDISES']))
            charges_ext = sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and any(si in l['sous_indicateur'] for si in ['SERVICES EXTÉRIEURS', 'AUTRES SERVICES EXTÉRIEURS']))
            VA = MC + prod - achats - charges_ext  # VA = MC + Production - Achats - Charges extérieures
            result['VA'] = VA
        else:
            VA = None
        # --- Calcul de l'Excédent Brut d'Exploitation (EBE) ---
        # EBE = VA + Subventions d'exploitation - Impôts et taxes - Charges de personnel - Services extérieurs - Autres services extérieurs
        has_subventions = any(l['indicateur'] == 'EBE' and 'SUBVENTIONS D’EXPLOITATION' in l['sous_indicateur'] for l in lignes)
        has_impots_taxes = any(l['indicateur'] == 'RE' and 'IMPÔTS ET TAXES' in l['sous_indicateur'] for l in lignes)
        has_charges_pers = any(l['indicateur'] == 'EBE' and 'CHARGES DE PERSONNEL' in l['sous_indicateur'] for l in lignes)
        has_ebe_charges = any(l['indicateur'] == 'EBE' for l in lignes)
        if VA is not None and has_ebe_charges:
            subventions = sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and 'SUBVENTIONS D’EXPLOITATION' in l['sous_indicateur'])
            impots_taxes = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and 'IMPÔTS ET TAXES' in l['sous_indicateur'])
            charges_pers = sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and 'CHARGES DE PERSONNEL' in l['sous_indicateur'])
            # Ajoute aussi les autres charges EBE (services extérieurs, autres services extérieurs)
            services_ext = sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and 'SERVICES EXTÉRIEURS' in l['sous_indicateur'])
            autres_services_ext = sum(l['montant'] for l in lignes if l['indicateur'] == 'EBE' and 'AUTRES SERVICES EXTÉRIEURS' in l['sous_indicateur'])
            EBE = VA + subventions - impots_taxes - charges_pers - services_ext - autres_services_ext  # Formule EBE
            result['EBE'] = EBE
        else:
            EBE = None
        # --- Calcul du Résultat d'Exploitation (RE) ---
        # RE = EBE + Autres produits de gestion courante - Autres charges de gestion courante + Reprises sur amortissements - Dotations aux amortissements
        has_autres_prod_gest = any(l['indicateur'] == 'RE' and 'AUTRES PRODUITS DE GESTION COURANTE' in l['sous_indicateur'] for l in lignes)
        has_autres_charges_gest = any(l['indicateur'] == 'RE' and 'AUTRES CHARGES DE GESTION COURANTE' in l['sous_indicateur'] for l in lignes)
        has_reprises_amort = any(l['indicateur'] == 'RE' and 'REPRISES AMORTISSEMENTS' in l['sous_indicateur'] for l in lignes)
        has_dotations_amort = any(l['indicateur'] == 'RE' and any(si in l['sous_indicateur'] for si in ['DOTATIONS AMORTISSEMENTS']) for l in lignes)
        if EBE is not None and (has_autres_prod_gest or has_autres_charges_gest or has_reprises_amort or has_dotations_amort):
            autres_prod_gest = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and 'AUTRES PRODUITS DE GESTION COURANTE' in l['sous_indicateur'])
            autres_charges_gest = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and 'AUTRES CHARGES DE GESTION COURANTE' in l['sous_indicateur'])
            reprises_amort = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and 'REPRISES AMORTISSEMENTS' in l['sous_indicateur'])
            dotations_amort = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and any(si in l['sous_indicateur'] for si in ['DOTATIONS AMORTISSEMENTS']))
            RE = EBE + autres_prod_gest - autres_charges_gest + reprises_amort - dotations_amort  # Formule RE
            result['RE'] = RE
        else:
            RE = None
        # --- Calcul du Résultat Net (R) ---
        # R = RE + Produits financiers - Charges financières + Produits exceptionnels - Charges exceptionnelles - Impôts sur les bénéfices + Transferts de charges
        has_prod_fin = any(l['indicateur'] == 'RE' and 'PRODUITS FINANCIERS' in l['sous_indicateur'] for l in lignes)
        has_charges_fin = any(l['indicateur'] == 'R' and 'CHARGES FINANCIÈRES' in l['sous_indicateur'] for l in lignes)
        has_prod_excep = any(l['indicateur'] == 'R' and 'PRODUITS EXCEPTIONNELS' in l['sous_indicateur'] for l in lignes)
        has_charges_excep = any(l['indicateur'] == 'R' and 'CHARGES EXCEPTIONNELLES' in l['sous_indicateur'] for l in lignes)
        has_impots_benef = any(l['indicateur'] == 'R' and 'IMPÔTS SUR LES BÉNÉFICES' in l['sous_indicateur'] for l in lignes)
        has_transferts = any(l['indicateur'] == 'R' and 'TRANSFERTS DE CHARGES' in l['sous_indicateur'] for l in lignes)
        if RE is not None and (has_prod_fin or has_charges_fin or has_prod_excep or has_charges_excep or has_impots_benef or has_transferts):
            prod_fin = sum(l['montant'] for l in lignes if l['indicateur'] == 'RE' and 'PRODUITS FINANCIERS' in l['sous_indicateur'])
            charges_fin = sum(l['montant'] for l in lignes if l['indicateur'] == 'R' and 'CHARGES FINANCIÈRES' in l['sous_indicateur'])
            prod_excep = sum(l['montant'] for l in lignes if l['indicateur'] == 'R' and 'PRODUITS EXCEPTIONNELS' in l['sous_indicateur'])
            charges_excep = sum(l['montant'] for l in lignes if l['indicateur'] == 'R' and 'CHARGES EXCEPTIONNELLES' in l['sous_indicateur'])
            impots_benef = sum(l['montant'] for l in lignes if l['indicateur'] == 'R' and 'IMPÔTS SUR LES BÉNÉFICES' in l['sous_indicateur'])
            transferts = sum(l['montant'] for l in lignes if l['indicateur'] == 'R' and 'TRANSFERTS DE CHARGES' in l['sous_indicateur'])
            R = RE + prod_fin - charges_fin + prod_excep - charges_excep - impots_benef + transferts  # Formule Résultat Net
            result['R'] = R
        return result

    def calcul_sig_par_annee(self, lignes):
        lignes_par_annee = {}
        for l in lignes:
            annee = l.get('annee')
            if annee is not None:
                lignes_par_annee.setdefault(annee, []).append(l)
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée',
            'EBE': 'Excédent brut d’exploitation',
            'RE': 'Résultat d’exploitation',
            'R': 'Résultat net',
        }
        result = {}
        for annee, lignes_annee in lignes_par_annee.items():
            sig = self.calcul_sig(lignes_annee)
            # On ne garde que les indicateurs avec un montant non nul
            sig_filtre = {k: {"valeur": v, "libelle": libelles.get(k, k)} for k, v in sig.items() if v not in (None, 0)}
            result[annee] = sig_filtre
        return result

    def get_indicateurs(self, periode, annee, trimestre=None):
        lines = self.get_lines(periode, annee, trimestre)
        indicateurs = {}
        libelles = {'MC': 'Marge commerciale', 'VA': 'Valeur ajoutée', 'EBE': 'Excédent brut d\'exploitation', 'RE': 'Résultat d\'exploitation', 'R': 'Résultat net'}
        for line in lines:
            mapping = MappingIndicateurSIG.find_best_mapping(line["code_compte"])
            if mapping:
                ind = mapping.indicateur
                # Calcul du solde selon la nature du compte
                nature = self.get_nature_compte(line["code_compte"])
                if nature == 'actif':
                    # Comptes d'actif et de charge : Solde = Débit - Crédit
                    montant = line["debit"] - line["credit"]
                else:
                    # Comptes de passif et de produit : Solde = Crédit - Débit
                    montant = line["credit"] - line["debit"]
                indicateurs.setdefault(ind, 0)
                indicateurs[ind] += montant
        return [
            {"indicateur": k, "libelle": libelles.get(k, k), "montant": v}
            for k, v in indicateurs.items()
        ]

    def get_sous_indicateurs(self, indicateur, periode, annee, trimestre=None):
        lines = self.get_lines(periode, annee, trimestre)
        sous = {}
        comptes_par_sous_ind = {}  # Pour tracer les comptes utilisés dans chaque sous-indicateur
        
        for line in lines:
            mapping = MappingIndicateurSIG.find_best_mapping(line["code_compte"])
            if mapping and mapping.indicateur == indicateur:
                sous_ind = mapping.sous_indicateur
                # Calcul du solde selon la nature du compte
                nature = self.get_nature_compte(line["code_compte"])
                if nature == 'actif':
                    # Comptes d'actif et de charge : Solde = Débit - Crédit
                    montant = line["debit"] - line["credit"]
                else:
                    # Comptes de passif et de produit : Solde = Crédit - Débit
                    montant = line["credit"] - line["debit"]
                sous.setdefault(sous_ind, 0)
                sous[sous_ind] += montant
                
                # Tracer les comptes pour la formule détaillée
                comptes_par_sous_ind.setdefault(sous_ind, [])
                comptes_par_sous_ind[sous_ind].append({
                    "code": line["code_compte"],
                    "montant": montant
                })
        
        result = []
        for k, v in sous.items():
            # Générer la formule détaillée avec les comptes réels
            comptes_utilises = comptes_par_sous_ind.get(k, [])
            if comptes_utilises:
                codes_comptes = sorted(list(set([c["code"] for c in comptes_utilises])))
                # Déterminer la nature du compte pour la formule
                nature_comptes = set()
                for compte in comptes_utilises:
                    nature = self.get_nature_compte(compte["code"])
                    nature_comptes.add(nature)
                
                # Si tous les comptes ont la même nature, utiliser la formule appropriée
                if len(nature_comptes) == 1:
                    nature = list(nature_comptes)[0]
                    if nature == 'actif':
                        formule_detaillee = f"Σ (Débit - Crédit) des comptes: {', '.join(codes_comptes)}"
                    else:
                        formule_detaillee = f"Σ (Crédit - Débit) des comptes: {', '.join(codes_comptes)}"
                else:
                    # Si mélange de comptes actif/passif, utiliser une formule générique
                    formule_detaillee = f"Σ (Solde selon nature) des comptes: {', '.join(codes_comptes)}"
            else:
                formule_detaillee = MappingIndicateurSIG.get_formule_pour_sous_indicateur(k)
            
            result.append({
                "sousIndicateur": k, 
                "libelle": k, 
                "initiales": MappingIndicateurSIG.get_initiales_pour_libelle(k),
                "formule": formule_detaillee,
                "montant": v
            })
        
        return result

    def get_sous_indicateurs_from_lines(self, lignes, indicateur):
        sous = {}
        comptes_par_sous_ind = {}  # Pour tracer les comptes utilisés dans chaque sous-indicateur
        
        for line in lignes:
            mapping = MappingIndicateurSIG.find_best_mapping(line["code_compte"])
            if mapping and mapping.indicateur == indicateur:
                sous_ind = mapping.sous_indicateur
                # Calcul du solde selon la nature du compte
                nature = self.get_nature_compte(line["code_compte"])
                if nature == 'actif':
                    # Comptes d'actif et de charge : Solde = Débit - Crédit
                    montant = line["debit"] - line["credit"]
                else:
                    # Comptes de passif et de produit : Solde = Crédit - Débit
                    montant = line["credit"] - line["debit"]
                sous.setdefault(sous_ind, 0)
                sous[sous_ind] += montant
                
                # Tracer les comptes pour la formule détaillée
                comptes_par_sous_ind.setdefault(sous_ind, [])
                comptes_par_sous_ind[sous_ind].append({
                    "code": line["code_compte"],
                    "montant": montant
                })
        
        result = []
        for k, v in sous.items():
            if k and k.strip():  # Filtrer les sous-indicateurs vides
                # Générer la formule détaillée avec les comptes réels
                comptes_utilises = comptes_par_sous_ind.get(k, [])
                if comptes_utilises:
                    codes_comptes = sorted(list(set([c["code"] for c in comptes_utilises])))
                    # Déterminer la nature du compte pour la formule
                    nature_comptes = set()
                    for compte in comptes_utilises:
                        nature = self.get_nature_compte(compte["code"])
                        nature_comptes.add(nature)
                    
                    # Si tous les comptes ont la même nature, utiliser la formule appropriée
                    if len(nature_comptes) == 1:
                        nature = list(nature_comptes)[0]
                        if nature == 'actif':
                            formule_detaillee = f"Σ (Débit - Crédit) des comptes: {', '.join(codes_comptes)}"
                        else:
                            formule_detaillee = f"Σ (Crédit - Débit) des comptes: {', '.join(codes_comptes)}"
                    else:
                        # Si mélange de comptes actif/passif, utiliser une formule générique
                        formule_detaillee = f"Σ (Solde selon nature) des comptes: {', '.join(codes_comptes)}"
                else:
                    formule_detaillee = MappingIndicateurSIG.get_formule_pour_sous_indicateur(k)
                
                result.append({
                    "sousIndicateur": k, 
                    "libelle": k, 
                    "initiales": MappingIndicateurSIG.get_initiales_pour_libelle(k),
                    "formule": formule_detaillee,
                    "montant": v
                })
        
        return result

    def get_comptes_sous_indicateur(self, sous_indicateur, periode, annee, trimestre=None):
        lines = self.get_lines(periode, annee, trimestre)
        comptes = {}
        for line in lines:
            mapping = MappingIndicateurSIG.find_best_mapping(line["code_compte"])
            if mapping and mapping.sous_indicateur == sous_indicateur:
                code = line["code_compte"]
                # Calcul du solde selon la nature du compte
                nature = self.get_nature_compte(line["code_compte"])
                if nature == 'actif':
                    # Comptes d'actif et de charge : Solde = Débit - Crédit
                    montant = line["debit"] - line["credit"]
                else:
                    # Comptes de passif et de produit : Solde = Crédit - Débit
                    montant = line["credit"] - line["debit"]
                comptes.setdefault(code, {"libelle": line["libelle_compte"], "montant": 0})
                comptes[code]["montant"] += montant
        return [
            {"code_compte": k, "libelle": v["libelle"], "montant": v["montant"]}
            for k, v in comptes.items()
        ] 