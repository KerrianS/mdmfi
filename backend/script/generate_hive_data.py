#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour générer un fichier .hive avec toutes les données SIG d'Odoo
"""

import sys
import os
import json
import datetime
from pathlib import Path

# Ajouter le répertoire parent au path pour importer les modules
sys.path.append(str(Path(__file__).parent.parent))

from controllers.odoo_sig_controller import OdooSIGController
from models.SIG_model import SIGCalculator
from models.PlanComptable import MappingIndicateurSIG

class HiveDataGenerator:
    """
    Générateur de données pour fichier .hive avec toutes les données SIG
    """
    
    def __init__(self):
        self.controller = OdooSIGController()
        
    def generate_hive_data(self, periode="annee", trimestre=None):
        """
        Génère toutes les données SIG pour un fichier .hive
        
        Args:
            periode: Période de calcul ("annee" ou "trimestre")
            trimestre: Numéro du trimestre (1-4) si periode="trimestre"
            
        Returns:
            Dictionnaire contenant toutes les données formatées pour .hive
        """
        print("Récupération des lignes comptables...")
        lignes = self.controller.get_lines(periode, trimestre)
        
        print(f"Nombre de lignes récupérées: {len(lignes)}")
        
        # Initialiser le calculateur SIG
        calculator = SIGCalculator(lignes)
        
        # Générer les données structurées
        hive_data = {
            "metadata": {
                "generated_at": datetime.datetime.now().isoformat(),
                "periode": periode,
                "trimestre": trimestre,
                "total_lignes": len(lignes)
            },
            "indicateurs_principaux": self._get_indicateurs_principaux(calculator),
            "sous_indicateurs": self._get_sous_indicateurs_detailles(calculator),
            "comptes_detailles": self._get_comptes_detailles(lignes),
            "evolution_par_annee": self._get_evolution_par_annee(lignes),
            "formules_calcul": self._get_formules_calcul(calculator),
            "statistiques": self._get_statistiques(lignes)
        }
        
        return hive_data
    
    def _get_indicateurs_principaux(self, calculator):
        """Récupère les indicateurs principaux avec leurs valeurs calculées"""
        indicateurs = calculator.calculer_tous_indicateurs()
        
        libelles = {
            'MC': 'Marge commerciale',
            'VA': 'Valeur ajoutée', 
            'EBE': 'Excédent brut d\'exploitation',
            'RE': 'Résultat d\'exploitation',
            'R': 'Résultat net'
        }
        
        result = []
        for code, valeur in indicateurs.items():
            if valeur != 0:
                result.append({
                    "code": code,
                    "libelle": libelles.get(code, code),
                    "valeur": valeur,
                    "formule_text": calculator.construire_formule_text(code, valeur),
                    "formule_numeric": calculator.construire_formule_numeric(code, valeur)
                })
        
        return result
    
    def _get_sous_indicateurs_detailles(self, calculator):
        """Récupère tous les sous-indicateurs avec leurs montants"""
        result = {}
        
        for indicateur in ['MC', 'VA', 'EBE', 'RE', 'R']:
            sous_indicateurs = calculator.get_sous_indicateurs_avec_montants(indicateur)
            result[indicateur] = []
            
            for sous_ind in sous_indicateurs:
                if sous_ind['montant'] != 0:
                    result[indicateur].append({
                        "sous_indicateur": sous_ind['sous_indicateur'],
                        "montant": sous_ind['montant'],
                        "initiales": MappingIndicateurSIG.get_initiales_pour_libelle(sous_ind['sous_indicateur']),
                        "formule": MappingIndicateurSIG.get_formule_pour_sous_indicateur(sous_ind['sous_indicateur'])
                    })
        
        return result
    
    def _get_comptes_detailles(self, lignes):
        """Récupère les comptes détaillés par classe"""
        comptes_par_classe = {}
        
        for ligne in lignes:
            classe = ligne.get('classe', '')
            code_compte = ligne.get('code_compte', '')
            libelle_compte = ligne.get('libelle_compte', '')
            montant = ligne.get('montant', 0)
            indicateur = ligne.get('indicateur', '')
            sous_indicateur = ligne.get('sous_indicateur', [])
            
            if classe not in comptes_par_classe:
                comptes_par_classe[classe] = []
            
            # Éviter les doublons de comptes
            compte_existant = next((c for c in comptes_par_classe[classe] if c['code_compte'] == code_compte), None)
            
            if compte_existant:
                compte_existant['montant'] += montant
            else:
                comptes_par_classe[classe].append({
                    "code_compte": code_compte,
                    "libelle_compte": libelle_compte,
                    "montant": montant,
                    "indicateur": indicateur,
                    "sous_indicateur": sous_indicateur
                })
        
        # Filtrer les comptes avec montant non nul
        for classe in comptes_par_classe:
            comptes_par_classe[classe] = [c for c in comptes_par_classe[classe] if c['montant'] != 0]
        
        return comptes_par_classe
    
    def _get_evolution_par_annee(self, lignes):
        """Récupère l'évolution des indicateurs par année"""
        return self.controller.calcul_sig_par_annee(lignes)
    
    def _get_formules_calcul(self, calculator):
        """Récupère les formules de calcul pour chaque indicateur"""
        result = {}
        
        for indicateur in ['MC', 'VA', 'EBE', 'RE', 'R']:
            composantes_positives, composantes_negatives = calculator.get_composantes_formule(indicateur)
            
            result[indicateur] = {
                "composantes_positives": composantes_positives,
                "composantes_negatives": composantes_negatives,
                "formule_text": calculator.construire_formule_text(indicateur),
                "formule_numeric": calculator.construire_formule_numeric(indicateur)
            }
        
        return result
    
    def _get_statistiques(self, lignes):
        """Calcule des statistiques sur les données"""
        if not lignes:
            return {}
        
        montants = [l.get('montant', 0) for l in lignes]
        annees = [l.get('annee') for l in lignes if l.get('annee') is not None]
        classes = [l.get('classe') for l in lignes if l.get('classe')]
        indicateurs = [l.get('indicateur') for l in lignes if l.get('indicateur')]
        
        return {
            "total_lignes": len(lignes),
            "montant_total": sum(montants),
            "montant_moyen": sum(montants) / len(montants) if montants else 0,
            "montant_min": min(montants) if montants else 0,
            "montant_max": max(montants) if montants else 0,
            "annees_couvertes": sorted(list(set(annees))) if annees else [],
            "classes_utilisees": sorted(list(set(classes))) if classes else [],
            "indicateurs_utilises": sorted(list(set(indicateurs))) if indicateurs else []
        }
    
    def save_hive_file(self, data, filename="sig_data.hive"):
        """
        Sauvegarde les données au format .hive
        
        Args:
            data: Données à sauvegarder
            filename: Nom du fichier de sortie
        """
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"Fichier {filename} généré avec succès!")
            print(f"Taille du fichier: {os.path.getsize(filename)} bytes")
        except Exception as e:
            print(f"Erreur lors de la sauvegarde: {e}")

def main():
    """Fonction principale"""
    print("=== Générateur de données SIG pour fichier .hive ===")
    
    generator = HiveDataGenerator()
    
    # Demander les paramètres à l'utilisateur
    print("\nOptions de génération:")
    print("1. Données annuelles")
    print("2. Données trimestrielles")
    
    choix = input("Votre choix (1 ou 2): ").strip()
    
    if choix == "2":
        trimestre = input("Numéro du trimestre (1-4): ").strip()
        try:
            trimestre = int(trimestre)
            if trimestre < 1 or trimestre > 4:
                raise ValueError("Trimestre invalide")
        except ValueError:
            print("Trimestre invalide, utilisation des données annuelles")
            trimestre = None
            periode = "annee"
        else:
            periode = "trimestre"
    else:
        periode = "annee"
        trimestre = None
    
    # Nom du fichier de sortie
    filename = input("Nom du fichier de sortie (défaut: sig_data.hive): ").strip()
    if not filename:
        filename = "sig_data.hive"
    
    if not filename.endswith('.hive'):
        filename += '.hive'
    
    print(f"\nGénération des données pour la période: {periode}")
    if trimestre:
        print(f"Trimestre: {trimestre}")
    print(f"Fichier de sortie: {filename}")
    
    # Générer les données
    print("\nGénération en cours...")
    data = generator.generate_hive_data(periode, trimestre)
    
    # Sauvegarder le fichier
    generator.save_hive_file(data, filename)
    
    # Afficher un résumé
    print("\n=== Résumé des données générées ===")
    print(f"Indicateurs principaux: {len(data['indicateurs_principaux'])}")
    
    total_sous_indicateurs = sum(len(sous_ind) for sous_ind in data['sous_indicateurs'].values())
    print(f"Sous-indicateurs: {total_sous_indicateurs}")
    
    total_comptes = sum(len(comptes) for comptes in data['comptes_detailles'].values())
    print(f"Comptes détaillés: {total_comptes}")
    
    print(f"Années couvertes: {len(data['statistiques']['annees_couvertes'])}")
    print(f"Montant total: {data['statistiques']['montant_total']:.2f}")

if __name__ == "__main__":
    main() 