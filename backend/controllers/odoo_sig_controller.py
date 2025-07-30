from services.odoo.odoo_api import OdooService
from models.PlanComptable import MappingIndicateurSIG
import datetime

class OdooSIGController:
    def __init__(self):
        self.odoo = OdooService()

    def get_period_domain(self, periode, trimestre=None):
        today = datetime.date.today()
        annees = [today.year, today.year - 1, today.year - 2, today.year - 3]
        domains = []
        for annee in annees:
            if periode == "trimestre" and trimestre:
                mois_debut = (trimestre - 1) * 3 + 1
                mois_fin = mois_debut + 2
                date_debut = f"{annee}-{mois_debut:02d}-01"
                if mois_fin == 12:
                    date_fin = f"{annee}-12-31"
                else:
                    next_month = mois_fin + 1
                    date_fin = (datetime.date(annee, next_month, 1) - datetime.timedelta(days=1)).isoformat()
                domains.append([['date', '>=', date_debut], ['date', '<=', date_fin]])
            else:
                domains.append([['date', '>=', f"{annee}-01-01"], ['date', '<=', f"{annee}-12-31"]])
        return domains

    def get_lines(self, periode, trimestre=None):
        domains = self.get_period_domain(periode, trimestre)
        all_lines = []
        for domain in domains:
            domain.append(['move_id.state', '=', 'posted'])
            fields = ['account_id', 'debit', 'credit', 'date']
            lines = self.odoo.search_read('account.move.line', domain, fields + ['account_id'])
            enriched = []
            for l in lines:
                if isinstance(l['account_id'], list):
                    l['code_compte'] = l['account_id'][1].split(' ')[0]
                    l['libelle_compte'] = ' '.join(l['account_id'][1].split(' ')[1:])
                else:
                    l['code_compte'] = ''
                    l['libelle_compte'] = ''
                code = l["code_compte"]
                l['classe'] = code[:1] if code else ''
                l['sous_classe'] = code[:2] if code else ''
                l['sss_classe'] = code[:3] if code else ''
                
                # Amélioration du mapping : utiliser le même système que Navision
                mapping = MappingIndicateurSIG.find_best_mapping(code)
                if mapping:
                    l['indicateur'] = mapping.indicateur
                    l['sous_indicateur'] = [mapping.sous_indicateur] if mapping.sous_indicateur else []
                else:
                    l['indicateur'] = None
                    l['sous_indicateur'] = []
                
                l['montant'] = l['debit'] - l['credit']
                # Ajout de l'année
                try:
                    l['annee'] = int(str(l['date'])[:4])
                except Exception:
                    l['annee'] = None
                enriched.append(l)
            all_lines.extend(enriched)
        return all_lines

    def get_indicateurs(self, periode, trimestre=None):
        lines = self.get_lines(periode, trimestre)
        indicateurs = {}
        libelles = {'MC': 'Marge commerciale', 'VA': 'Valeur ajoutée', 'EBE': 'EBE', 'RE': 'Résultat exploitation', 'R': 'Résultat net'}
        for line in lines:
            ind = line["indicateur"]
            if ind:
                indicateurs.setdefault(ind, 0)
                indicateurs[ind] += line["montant"]
        return [
            {"indicateur": k, "libelle": libelles.get(k, k), "montant": v}
            for k, v in indicateurs.items()
        ]

    def get_sous_indicateurs(self, indicateur, periode, trimestre=None):
        lines = self.get_lines(periode, trimestre)
        sous = {}
        for line in lines:
            if line["indicateur"] == indicateur:
                for sous_ind in line["sous_indicateur"]:
                    if sous_ind:
                        sous.setdefault(sous_ind, 0)
                        sous[sous_ind] += line["montant"]
        return [
            {
                "sousIndicateur": k, 
                "libelle": k, 
                "initiales": MappingIndicateurSIG.get_initiales_pour_libelle(k),
                "montant": v
            }
            for k, v in sous.items()
        ]

    def get_comptes_sous_indicateur(self, sous_indicateur, periode, trimestre=None):
        lines = self.get_lines(periode, trimestre)
        comptes = {}
        for line in lines:
            if sous_indicateur in line["sous_indicateur"]:
                code = line["code_compte"]
                comptes.setdefault(code, {"libelle": line["libelle_compte"], "montant": 0})
                comptes[code]["montant"] += line["montant"]
        return [
            {"code_compte": k, "libelle": v["libelle"], "montant": v["montant"]}
            for k, v in comptes.items()
        ]

    def get_sous_indicateurs_par_annee(self, lignes, classes_autorisees=None, with_initiales=False):
        # Dictionnaire : { sous_indicateur: { annee: montant } }
        result = {}
        for l in lignes:
            # Filtrer par classe si demandé
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
        result = {}

        # --- Calcul de la Marge Commerciale (MC) ---
        # MC = Ventes de marchandises - Coût d'achat des marchandises vendues
        mc_ventes = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and 'VENTES DE MARCHANDISES' in l['sous_indicateur'])
        mc_achats = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and 'ACHATS DE MARCHANDISES' in l['sous_indicateur'])
        MC = mc_ventes - abs(mc_achats)  # MC = Ventes - Achats (en valeur absolue car les achats sont des charges)
        if MC != 0:
            result['MC'] = MC
        else:
            MC = None
            
        # --- Calcul de la Valeur Ajoutée (VA) ---
        # VA = MC + Production de l'exercice - Consommations de l'exercice
        va_production = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and any(si in l['sous_indicateur'] for si in ['VENTES DE PRODUITS FINIS', 'PRESTATIONS DE SERVICES']))
        va_consommations = sum(l['montant'] for l in lignes if l['indicateur'] == 'MC' and any(si in l['sous_indicateur'] for si in ['ACHATS DE MARCHANDISES']))
        
        if MC is not None or va_production != 0 or va_consommations != 0:
            VA = (MC if MC else 0) + va_production - abs(va_consommations)
            if VA != 0:
                result['VA'] = VA
        else:
            VA = None
            
        # --- Calcul de l'Excédent Brut d'Exploitation (EBE) ---
        # EBE = VA - Charges de personnel - Impôts et taxes
        if VA is not None:
            # Pour l'instant, on utilise VA comme EBE car on n'a pas les charges de personnel
            EBE = VA
            result['EBE'] = EBE
        else:
            EBE = None
            
        # --- Calcul du Résultat d'Exploitation (RE) ---
        # RE = EBE + Autres produits - Autres charges
        if EBE is not None:
            # Pour l'instant, on utilise EBE comme RE
            RE = EBE
            result['RE'] = RE
        else:
            RE = None
            
        # --- Calcul du Résultat Net (R) ---
        # R = RE + Résultat financier + Résultat exceptionnel
        if RE is not None:
            # Pour l'instant, on utilise RE comme R
            R = RE
            result['R'] = R

        return result

    def calcul_sig_par_annee(self, lignes):
        # Regroupe les lignes par année
        lignes_par_annee = {}
        for l in lignes:
            annee = l.get('annee')
            if annee is not None:
                lignes_par_annee.setdefault(annee, []).append(l)
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée',
            'EBE': 'Excédent brut d\'exploitation',
            'RE': 'Résultat d\'exploitation',
            'R': 'Résultat net',
        }
        result = {}
        for annee, lignes_annee in lignes_par_annee.items():
            sig = self.calcul_sig(lignes_annee)
            sig_filtre = {k: {"valeur": v, "libelle": libelles.get(k, k)} for k, v in sig.items() if v not in (None, 0)}
            result[annee] = sig_filtre
        return result

