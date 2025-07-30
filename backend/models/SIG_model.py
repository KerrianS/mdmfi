# -*- coding: utf-8 -*-
"""
Modèle SIG (Système d'Information de Gestion) pour les calculs financiers
Contient les formules et logiques de calcul des indicateurs financiers
"""

from typing import Dict, List, Any, Tuple
from models.PlanComptable import MappingIndicateurSIG


class SIGCalculator:
    """
    Calculateur SIG pour les indicateurs financiers
    """
    
    def __init__(self, lignes: List[Dict[str, Any]]):
        """
        Initialise le calculateur avec les lignes comptables
        
        Args:
            lignes: Liste des lignes comptables avec indicateurs et sous-indicateurs
        """
        self.lignes = lignes
        self._cache_montants = {}
    
    def _get_montant_par_indicateur_sous_ind(self, indicateur: str, sous_indicateurs_list: List[str], exclure_tiers: bool = True) -> float:
        """
        Calcule le montant total pour un indicateur et ses sous-indicateurs spécifiques
        
        Args:
            indicateur: Code de l'indicateur (MC, VA, EBE, RE, R)
            sous_indicateurs_list: Liste des sous-indicateurs à inclure
            exclure_tiers: Si True, exclut les comptes de tiers (classes 4 et 5)
            
        Returns:
            Montant total calculé
        """
        cache_key = f"{indicateur}_{'_'.join(sous_indicateurs_list)}_{exclure_tiers}"
        if cache_key in self._cache_montants:
            return self._cache_montants[cache_key]
        
        total = 0
        for ligne in self.lignes:
            if ligne.get('indicateur') == indicateur:
                # Exclure les comptes de tiers (classes 4 et 5) sauf si explicitement demandé
                code_compte = str(ligne.get('code_compte', ''))
                if exclure_tiers and (code_compte.startswith('4') or code_compte.startswith('5')):
                    continue
                
                if any(si in ligne.get('sous_indicateur', []) for si in sous_indicateurs_list):
                    total += ligne['montant']
        
        self._cache_montants[cache_key] = total
        return total
    
    def _get_montant_par_indicateur(self, indicateur: str, exclure_tiers: bool = True) -> float:
        """
        Calcule le montant total pour un indicateur (tous sous-indicateurs confondus)
        
        Args:
            indicateur: Code de l'indicateur
            exclure_tiers: Si True, exclut les comptes de tiers
            
        Returns:
            Montant total calculé
        """
        cache_key = f"{indicateur}_all_{exclure_tiers}"
        if cache_key in self._cache_montants:
            return self._cache_montants[cache_key]
        
        total = 0
        for ligne in self.lignes:
            if ligne.get('indicateur') == indicateur:
                code_compte = str(ligne.get('code_compte', ''))
                if exclure_tiers and (code_compte.startswith('4') or code_compte.startswith('5')):
                    continue
                total += ligne['montant']
        
        self._cache_montants[cache_key] = total
        return total
    
    def calculer_marge_commerciale(self) -> float:
        """
        Calcule la Marge Commerciale (MC)
        MC = Ventes de marchandises - Coût d'achat des marchandises vendues
        
        Returns:
            Valeur de la marge commerciale
        """
        # Composantes positives (ventes)
        ventes_marchandises = self._get_montant_par_indicateur_sous_ind(
            'MC', 
            ['VENTES DE MARCHANDISES', 'VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 
             'PRESTATIONS DE SERVICES', 'TVA COLLECTEE']
        )
        
        # Composantes négatives (achats)
        cout_achat_marchandises = self._get_montant_par_indicateur_sous_ind(
            'MC', 
            ['ACHATS DE MARCHANDISES']
        )
        
        # Si pas de sous-indicateurs spécifiques, prendre tout MC (hors tiers)
        if ventes_marchandises == 0 and cout_achat_marchandises == 0:
            mc_total = self._get_montant_par_indicateur('MC')
            return mc_total if mc_total != 0 else 0
        
        return ventes_marchandises - abs(cout_achat_marchandises)
    
    def calculer_valeur_ajoutee(self, mc_value: float = 0) -> float:
        """
        Calcule la Valeur Ajoutée (VA)
        VA = Production de l'exercice - Consommations de l'exercice en provenance de tiers
        
        Args:
            mc_value: Valeur de la marge commerciale (si déjà calculée)
            
        Returns:
            Valeur de la valeur ajoutée
        """
        # Production = MC + Production vendue + Production stockée + Production immobilisée
        prestations_services = self._get_montant_par_indicateur_sous_ind('VA', ['PRESTATIONS DE SERVICES'])
        ventes_produits = self._get_montant_par_indicateur_sous_ind('VA', ['VENTES DE PRODUITS FINIS'])
        production_stockee = self._get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION STOCKÉE'])
        production_immobilisee = self._get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION IMMOBILISÉE'])
        
        production_exercice = mc_value + prestations_services + ventes_produits + production_stockee + production_immobilisee
        
        # Consommations = Achats stockés + Achats non stockés + Fournitures + Services extérieurs
        achats_stockes = self._get_montant_par_indicateur_sous_ind('VA', ['ACHATS STOCKES'])
        achats_non_stockes = self._get_montant_par_indicateur_sous_ind('VA', ['ACHATS NON STOCKES'])
        fournitures = self._get_montant_par_indicateur_sous_ind('VA', ['FOURNITURES'])
        services_exterieurs = self._get_montant_par_indicateur_sous_ind('VA', ['SERVICES EXTÉRIEURS'])
        autres_services_exterieurs = self._get_montant_par_indicateur_sous_ind('VA', ['AUTRES SERVICES EXTÉRIEURS'])
        
        consommations_tiers = abs(achats_stockes) + abs(achats_non_stockes) + abs(fournitures) + abs(services_exterieurs) + abs(autres_services_exterieurs)
        
        va_calculee = production_exercice - consommations_tiers
        
        # Si aucune donnée calculée, essayer de récupérer la VA directe
        if va_calculee == 0 and production_exercice == 0 and consommations_tiers == 0:
            va_direct = self._get_montant_par_indicateur('VA')
            return va_direct if va_direct != 0 else 0
        
        return va_calculee
    
    def calculer_excedent_brut_exploitation(self, va_value: float = 0) -> float:
        """
        Calcule l'Excédent Brut d'Exploitation (EBE)
        EBE = VA + Subventions d'exploitation - Impôts et taxes - Charges de personnel
        
        Args:
            va_value: Valeur de la valeur ajoutée (si déjà calculée)
            
        Returns:
            Valeur de l'excédent brut d'exploitation
        """
        subventions_exploitation = self._get_montant_par_indicateur_sous_ind('EBE', ['SUBVENTIONS D\'EXPLOITATION'])
        impots_taxes = self._get_montant_par_indicateur_sous_ind('EBE', ['IMPÔTS ET TAXES'])
        charges_personnel = self._get_montant_par_indicateur_sous_ind('EBE', ['CHARGES DE PERSONNEL'])
        
        if va_value != 0 or subventions_exploitation != 0 or impots_taxes != 0 or charges_personnel != 0:
            return va_value + subventions_exploitation - abs(impots_taxes) - abs(charges_personnel)
        
        return 0
    
    def calculer_resultat_exploitation(self, ebe_value: float = 0) -> float:
        """
        Calcule le Résultat d'Exploitation (RE)
        RE = EBE + Autres produits - Autres charges
        
        Args:
            ebe_value: Valeur de l'EBE (si déjà calculée)
            
        Returns:
            Valeur du résultat d'exploitation
        """
        autres_produits = self._get_montant_par_indicateur_sous_ind('RE', ['AUTRES PRODUITS DE GESTION COURANTE'])
        reprises_amortissements = self._get_montant_par_indicateur_sous_ind('RE', ['REPRISES AMORTISSEMENTS'])
        autres_charges = self._get_montant_par_indicateur_sous_ind('RE', ['AUTRES CHARGES DE GESTION COURANTE'])
        dotations_amortissements = self._get_montant_par_indicateur_sous_ind('RE', ['DOTATIONS AMORTISSEMENTS'])
        
        if ebe_value != 0 or autres_produits != 0 or reprises_amortissements != 0 or autres_charges != 0 or dotations_amortissements != 0:
            return ebe_value + autres_produits + reprises_amortissements - abs(autres_charges) - abs(dotations_amortissements)
        
        return 0
    
    def calculer_resultat_net(self, re_value: float = 0) -> float:
        """
        Calcule le Résultat Net (R)
        R = RE + Résultat financier + Résultat exceptionnel - Impôts sur les bénéfices
        
        Args:
            re_value: Valeur du RE (si déjà calculée)
            
        Returns:
            Valeur du résultat net
        """
        # Résultat financier
        produits_financiers = self._get_montant_par_indicateur_sous_ind('R', ['PRODUITS FINANCIERS'])
        charges_financieres = self._get_montant_par_indicateur_sous_ind('R', ['CHARGES FINANCIÈRES'])
        resultat_financier = produits_financiers - abs(charges_financieres)
        
        # Résultat exceptionnel
        produits_exceptionnels = self._get_montant_par_indicateur_sous_ind('R', ['PRODUITS EXCEPTIONNELS'])
        charges_exceptionnelles = self._get_montant_par_indicateur_sous_ind('R', ['CHARGES EXCEPTIONNELLES'])
        resultat_exceptionnel = produits_exceptionnels - abs(charges_exceptionnelles)
        
        # Impôts sur les bénéfices
        impots_benefices = self._get_montant_par_indicateur_sous_ind('R', ['IMPÔTS SUR LES BÉNÉFICES'])
        
        if (re_value != 0 or resultat_financier != 0 or resultat_exceptionnel != 0 or impots_benefices != 0):
            return re_value + resultat_financier + resultat_exceptionnel - abs(impots_benefices)
        
        return 0
    
    def calculer_tous_indicateurs(self) -> Dict[str, float]:
        """
        Calcule tous les indicateurs SIG dans l'ordre logique
        
        Returns:
            Dictionnaire avec tous les indicateurs calculés
        """
        result = {}
        
        # 1. Marge Commerciale (MC)
        mc_value = self.calculer_marge_commerciale()
        if mc_value != 0:
            result['MC'] = mc_value
        
        # 2. Valeur Ajoutée (VA)
        va_value = self.calculer_valeur_ajoutee(mc_value)
        if va_value != 0:
            result['VA'] = va_value
        
        # 3. Excédent Brut d'Exploitation (EBE)
        ebe_value = self.calculer_excedent_brut_exploitation(va_value)
        if ebe_value != 0:
            result['EBE'] = ebe_value
        
        # 4. Résultat d'Exploitation (RE)
        re_value = self.calculer_resultat_exploitation(ebe_value)
        if re_value != 0:
            result['RE'] = re_value
        
        # 5. Résultat Net (R)
        r_value = self.calculer_resultat_net(re_value)
        if r_value != 0:
            result['R'] = r_value
        
        return result
    
    def get_composantes_formule(self, indicateur: str) -> Tuple[List[str], List[str]]:
        """
        Récupère les composantes positives et négatives d'un indicateur pour la construction de formule
        
        Args:
            indicateur: Code de l'indicateur
            
        Returns:
            Tuple (composantes_positives, composantes_negatives)
        """
        if indicateur == 'MC':
            # MC = Ventes - Achats
            composantes_positives = []
            composantes_negatives = []
            
            # Composantes positives (ventes) - inclure si montant > 0
            ventes_composantes = ['VENTES DE MARCHANDISES', 'VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES', 'TVA COLLECTEE']
            for comp in ventes_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('MC', [comp])
                if montant > 0:
                    composantes_positives.append(comp)
            
            # Composantes négatives (achats) - inclure si montant > 0 (car ce sont des charges)
            achats_composantes = ['ACHATS DE MARCHANDISES']
            for comp in achats_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('MC', [comp])
                if montant > 0:  # Les achats sont des charges, donc on les inclut si > 0
                    composantes_negatives.append(comp)
            
            return composantes_positives, composantes_negatives
            
        elif indicateur == 'VA':
            # VA = Production - Consommations
            # Production = MC + Prestations + Ventes produits + Production stockée + Production immobilisée
            # Consommations = Achats stockés + Achats non stockés + Fournitures + Services extérieurs
            composantes_positives = []
            composantes_negatives = []
            
            # Composantes de production (positives) - inclure si montant > 0
            production_composantes = ['PRESTATIONS DE SERVICES', 'VENTES DE PRODUITS FINIS', 'PRODUCTION STOCKÉE', 'PRODUCTION IMMOBILISÉE']
            for comp in production_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('VA', [comp])
                if montant > 0:
                    composantes_positives.append(comp)
            
            # Ajouter MC si elle contribue positivement
            mc_value = self.calculer_marge_commerciale()
            if mc_value > 0:
                composantes_positives.append('MC')
            
            # Composantes de consommation (négatives) - inclure si montant > 0 (car ce sont des charges)
            consommation_composantes = ['ACHATS STOCKES', 'ACHATS NON STOCKES', 'FOURNITURES', 'SERVICES EXTÉRIEURS', 'AUTRES SERVICES EXTÉRIEURS']
            for comp in consommation_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('VA', [comp])
                if montant > 0:  # Les consommations sont des charges, donc on les inclut si > 0
                    composantes_negatives.append(comp)
            
            return composantes_positives, composantes_negatives
            
        elif indicateur == 'EBE':
            # EBE = VA + Subventions - Impôts - Charges personnel
            composantes_positives = []
            composantes_negatives = []
            
            # Ajouter VA comme composante positive si elle existe
            va_value = self.calculer_valeur_ajoutee()
            if va_value > 0:
                composantes_positives.append('VA')
            
            # Vérifier les autres composantes
            ebe_composantes = ['SUBVENTIONS D\'EXPLOITATION', 'IMPÔTS ET TAXES', 'CHARGES DE PERSONNEL']
            for comp in ebe_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('EBE', [comp])
                if montant > 0:
                    composantes_positives.append(comp)
                elif montant < 0:
                    composantes_negatives.append(comp)
            
            return composantes_positives, composantes_negatives
            
        elif indicateur == 'RE':
            # RE = EBE + Autres produits - Autres charges
            composantes_positives = []
            composantes_negatives = []
            
            # Ajouter EBE comme composante positive si elle existe
            ebe_value = self.calculer_excedent_brut_exploitation()
            if ebe_value > 0:
                composantes_positives.append('EBE')
            
            # Vérifier les autres composantes
            re_composantes = ['AUTRES PRODUITS DE GESTION COURANTE', 'REPRISES AMORTISSEMENTS', 'AUTRES CHARGES DE GESTION COURANTE', 'DOTATIONS AMORTISSEMENTS']
            for comp in re_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('RE', [comp])
                if montant > 0:
                    composantes_positives.append(comp)
                elif montant < 0:
                    composantes_negatives.append(comp)
            
            return composantes_positives, composantes_negatives
            
        elif indicateur == 'R':
            # R = RE + Résultat financier + Résultat exceptionnel - Impôts
            composantes_positives = []
            composantes_negatives = []
            
            # Ajouter RE comme composante positive si elle existe
            re_value = self.calculer_resultat_exploitation()
            if re_value > 0:
                composantes_positives.append('RE')
            
            # Vérifier les autres composantes
            r_composantes = ['PRODUITS FINANCIERS', 'CHARGES FINANCIÈRES', 'PRODUITS EXCEPTIONNELS', 'CHARGES EXCEPTIONNELLES', 'IMPÔTS SUR LES BÉNÉFICES']
            for comp in r_composantes:
                montant = self._get_montant_par_indicateur_sous_ind('R', [comp])
                if montant > 0:
                    composantes_positives.append(comp)
                elif montant < 0:
                    composantes_negatives.append(comp)
            
            return composantes_positives, composantes_negatives
        
        else:
            # Fallback pour les autres indicateurs
            sous_indicateurs_possibles = MappingIndicateurSIG.get_sous_indicateurs_possibles().get(indicateur, [])
            
            composantes_positives = []
            composantes_negatives = []
            
            # Vérifier quels sous-indicateurs ont réellement des montants dans les données
            for sous_ind in sous_indicateurs_possibles:
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [sous_ind])
                if montant > 0:
                    composantes_positives.append(sous_ind)
                elif montant < 0:
                    composantes_negatives.append(sous_ind)
            
            return composantes_positives, composantes_negatives
    
    def construire_formule_text(self, indicateur: str, valeur: float) -> str:
        """
        Construit la formule textuelle d'un indicateur
        
        Args:
            indicateur: Code de l'indicateur
            valeur: Valeur calculée de l'indicateur
            
        Returns:
            Formule textuelle formatée
        """
        composantes_positives, composantes_negatives = self.get_composantes_formule(indicateur)
        
        partie_plus = []
        partie_moins = []
        somme_calculee = 0
        
        # Construire la partie positive
        for comp in composantes_positives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            if montant > 0:
                partie_plus.append(f"{comp} ({montant:.2f})")
                somme_calculee += montant
        
        # Construire la partie négative
        for comp in composantes_negatives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            # Les composantes négatives sont maintenant incluses si montant > 0 (car ce sont des charges)
            if montant > 0:
                partie_moins.append(f"{comp} ({montant:.2f})")
                somme_calculee -= montant  # On soustrait car c'est une charge
        
        # Construire la formule avec la somme calculée
        if partie_plus and partie_moins:
            formule = f"{indicateur} = {' + '.join(partie_plus)} - {' + '.join(partie_moins)} = {somme_calculee:.2f}"
        elif partie_plus and not partie_moins:
            formule = f"{indicateur} = {' + '.join(partie_plus)} = {somme_calculee:.2f}"
        elif not partie_plus and partie_moins:
            formule = f"{indicateur} = -({' + '.join(partie_moins)}) = {somme_calculee:.2f}"
        else:
            formule = f"{indicateur} = {somme_calculee:.2f}"
        
        return formule
    
    def construire_formule_numeric(self, indicateur: str, valeur: float) -> str:
        """
        Construit la formule numérique d'un indicateur
        
        Args:
            indicateur: Code de l'indicateur
            valeur: Valeur calculée de l'indicateur
            
        Returns:
            Formule numérique formatée
        """
        composantes_positives, composantes_negatives = self.get_composantes_formule(indicateur)
        
        partie_plus = []
        partie_moins = []
        somme_calculee = 0
        
        # Construire la partie positive
        for comp in composantes_positives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            if montant > 0:
                partie_plus.append(f"{montant:.2f}")
                somme_calculee += montant
        
        # Construire la partie négative
        for comp in composantes_negatives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            # Les composantes négatives sont maintenant incluses si montant > 0 (car ce sont des charges)
            if montant > 0:
                partie_moins.append(f"{montant:.2f}")
                somme_calculee -= montant  # On soustrait car c'est une charge
        
        # Construire la formule avec la somme calculée
        if partie_plus and partie_moins:
            formule = f"{indicateur} = ({' + '.join(partie_plus)}) - ({' + '.join(partie_moins)}) = {somme_calculee:.2f}"
        elif partie_plus and not partie_moins:
            formule = f"{indicateur} = {' + '.join(partie_plus)} = {somme_calculee:.2f}"
        elif not partie_plus and partie_moins:
            formule = f"{indicateur} = -({' + '.join(partie_moins)}) = {somme_calculee:.2f}"
        else:
            formule = f"{indicateur} = {somme_calculee:.2f}"
        
        return formule
    
    def calculer_valeur_par_formule(self, indicateur: str) -> float:
        """
        Calcule la valeur d'un indicateur basée sur la somme des composantes de sa formule
        
        Args:
            indicateur: Code de l'indicateur
            
        Returns:
            Valeur calculée basée sur la somme des composantes de la formule
        """
        composantes_positives, composantes_negatives = self.get_composantes_formule(indicateur)
        
        somme_calculee = 0
        
        # Calculer la somme des composantes positives
        for comp in composantes_positives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            if montant > 0:
                somme_calculee += montant
        
        # Calculer la somme des composantes négatives
        for comp in composantes_negatives:
            if comp in ['MC', 'VA', 'EBE', 'RE']:
                # Pour les composantes calculées, récupérer leur valeur calculée
                if comp == 'MC':
                    montant = self.calculer_marge_commerciale()
                elif comp == 'VA':
                    montant = self.calculer_valeur_ajoutee()
                elif comp == 'EBE':
                    montant = self.calculer_excedent_brut_exploitation()
                elif comp == 'RE':
                    montant = self.calculer_resultat_exploitation()
                else:
                    montant = 0
            else:
                # Pour les sous-indicateurs individuels
                montant = self._get_montant_par_indicateur_sous_ind(indicateur, [comp])
            
            # Les composantes négatives sont maintenant incluses si montant > 0 (car ce sont des charges)
            if montant > 0:
                somme_calculee -= montant  # On soustrait car c'est une charge
        
        return somme_calculee
    
    def get_sous_indicateurs_avec_montants(self, indicateur: str) -> List[Dict[str, Any]]:
        """
        Récupère tous les sous-indicateurs possibles d'un indicateur avec leurs montants
        
        Args:
            indicateur: Code de l'indicateur
            
        Returns:
            Liste des sous-indicateurs avec leurs montants
        """
        sous_indicateurs_possibles = MappingIndicateurSIG.get_sous_indicateurs_possibles().get(indicateur, [])
        result = []
        
        for sous_ind in sous_indicateurs_possibles:
            montant = self._get_montant_par_indicateur_sous_ind(indicateur, [sous_ind])
            result.append({
                "sous_indicateur": sous_ind,
                "montant": montant
            })
        
        return result
