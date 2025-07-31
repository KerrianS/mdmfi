#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from controllers.odoo_sig_controller import OdooSIGController
from models.PlanComptable import MappingIndicateurSIG

def debug_odoo_data():
    print("=== DEBUG ODOO DATA ===")
    
    # Initialiser le contrôleur Odoo
    odoo = OdooSIGController()
    
    # Récupérer les lignes
    lignes = odoo.get_lines('annee')
    print(f"Total lignes récupérées: {len(lignes)}")
    
    if not lignes:
        print("Aucune ligne récupérée d'Odoo!")
        return
    
    # Analyser les premières lignes
    print("\n=== PREMIÈRES 10 LIGNES ===")
    for i, ligne in enumerate(lignes[:10]):
        print(f"Ligne {i+1}:")
        print(f"  Code compte: {ligne.get('code_compte', 'N/A')}")
        print(f"  Libellé compte: {ligne.get('libelle_compte', 'N/A')}")
        print(f"  Indicateur: {ligne.get('indicateur', 'N/A')}")
        print(f"  Sous-indicateurs: {ligne.get('sous_indicateur', [])}")
        print(f"  Montant: {ligne.get('montant', 0)}")
        print(f"  Débit: {ligne.get('debit', 0)}")
        print(f"  Crédit: {ligne.get('credit', 0)}")
        print(f"  Année: {ligne.get('annee', 'N/A')}")
        print("---")
    
    # Analyser les indicateurs
    print("\n=== ANALYSE DES INDICATEURS ===")
    indicateurs_count = {}
    sous_indicateurs_count = {}
    
    for ligne in lignes:
        ind = ligne.get('indicateur')
        if ind:
            indicateurs_count[ind] = indicateurs_count.get(ind, 0) + 1
        
        for si in ligne.get('sous_indicateur', []):
            if si:
                sous_indicateurs_count[si] = sous_indicateurs_count.get(si, 0) + 1
    
    print("Indicateurs trouvés:")
    for ind, count in indicateurs_count.items():
        print(f"  {ind}: {count} lignes")
    
    print("\nSous-indicateurs trouvés:")
    for si, count in sous_indicateurs_count.items():
        print(f"  {si}: {count} lignes")
    
    # Analyser les codes de compte
    print("\n=== ANALYSE DES CODES DE COMPTE ===")
    codes_count = {}
    for ligne in lignes:
        code = ligne.get('code_compte', '')
        if code:
            codes_count[code] = codes_count.get(code, 0) + 1
    
    print("Top 10 codes de compte:")
    sorted_codes = sorted(codes_count.items(), key=lambda x: x[1], reverse=True)
    for code, count in sorted_codes[:10]:
        print(f"  {code}: {count} lignes")
    
    # Tester le mapping
    print("\n=== TEST DU MAPPING ===")
    for code, count in sorted_codes[:5]:
        mapping = MappingIndicateurSIG.find_best_mapping(code)
        if mapping:
            print(f"Code {code} -> Indicateur: {mapping.indicateur}, Sous-indicateur: {mapping.sous_indicateur}")
        else:
            print(f"Code {code} -> Aucun mapping trouvé")

if __name__ == "__main__":
    debug_odoo_data() 