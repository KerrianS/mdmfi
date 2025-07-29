def calcul_sig_adapte(lignes):
    """
    Calcul SIG avec formules comptables officielles françaises
    Retourne un dict : {'indicateurs': {...}, 'details': {...}}
    """
    # Helper functions pour sommer les montants (EXCLUANT les comptes de tiers)
    def get_montant_par_indicateur_sous_ind(indicateur, sous_indicateurs_list, exclure_tiers=True):
        total = 0
        for l in lignes:
            if l.get('indicateur') == indicateur:
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
                code_compte = str(l.get('code_compte', ''))
                if exclure_tiers and (code_compte.startswith('4') or code_compte.startswith('5')):
                    continue
                total += l['montant']
        return total

    # 1. MARGE COMMERCIALE (MC)
    ventes_marchandises = get_montant_par_indicateur_sous_ind('MC', ['VENTES DE MARCHANDISES', 'VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES', 'TVA COLLECTEE'])
    cout_achat_marchandises = get_montant_par_indicateur_sous_ind('MC', ['ACHATS DE MARCHANDISES'])
    valeur_formule = 0
    if ventes_marchandises == 0 and cout_achat_marchandises == 0:
        mc_total = get_montant_par_indicateur('MC')
        if mc_total != 0:
            result['MC'] = mc_total
            valeur_formule = mc_total
    else:
        mc_calculee = ventes_marchandises - abs(cout_achat_marchandises)
        if mc_calculee != 0:
            result['MC'] = mc_calculee
            valeur_formule = mc_calculee
    # Si aucun résultat, garder valeur_formule à 0
    if ventes_marchandises == 0 and cout_achat_marchandises == 0:
        formule_text = "MC : Non calculable"
        formule_numeric = "MC : Non calculable"
    else:
        formule_text = f"MC = VENTES DE MARCHANDISES ({ventes_marchandises:.2f}) - ACHATS DE MARCHANDISES ({abs(cout_achat_marchandises):.2f}) = {valeur_formule:.2f}"
        formule_numeric = f"MC = {ventes_marchandises:.2f} - {abs(cout_achat_marchandises):.2f} = {valeur_formule:.2f}"
    ecart = round(result.get('MC', 0) - valeur_formule, 2)
    details['MC'] = {
        'formule_text': formule_text,
        'formule_numeric': formule_numeric,
        'valeur_formule': valeur_formule,
        'ecart': ecart
    }

    # 2. VALEUR AJOUTÉE (VA)
    mc_value = result.get('MC', 0)
    production_vendue = get_montant_par_indicateur_sous_ind('VA', ['PRESTATIONS DE SERVICES', 'VENTES DE PRODUITS'])
    production_stockee = get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION STOCKÉE'])
    production_immobilisee = get_montant_par_indicateur_sous_ind('VA', ['PRODUCTION IMMOBILISÉE'])
    production_exercice = mc_value + production_vendue + production_stockee + production_immobilisee
    achats_matieres = get_montant_par_indicateur_sous_ind('VA', ['ACHATS', 'FOURNITURES'])
    services_exterieurs = get_montant_par_indicateur_sous_ind('EBE', ['SERVICES EXTÉRIEURS', 'AUTRES SERVICES EXTÉRIEURS'])
    consommations_tiers = abs(achats_matieres) + abs(services_exterieurs)
    va_direct = get_montant_par_indicateur('VA')
    if production_exercice == mc_value and consommations_tiers == 0 and va_direct != 0:
        result['VA'] = va_direct + mc_value
        valeur_formule = va_direct + mc_value
    else:
        va_calculee = production_exercice - consommations_tiers
        if va_calculee != 0:
            result['VA'] = va_calculee
            valeur_formule = va_calculee
    partie_plus = [mc_value, production_vendue, production_stockee, production_immobilisee]
    partie_moins = [abs(achats_matieres), abs(services_exterieurs)]
    if all(v == 0 for v in partie_plus + partie_moins):
        formule_text = "VA : Non calculable"
        formule_numeric = "VA : Non calculable"
    else:
        formule_text = f"VA = MC ({mc_value:.2f}) + PRESTATIONS DE SERVICES ({production_vendue:.2f}) + PRODUCTION STOCKÉE ({production_stockee:.2f}) + PRODUCTION IMMOBILISÉE ({production_immobilisee:.2f}) - ACHATS ({abs(achats_matieres):.2f}) - CHARGES EXTERNES ({abs(services_exterieurs):.2f}) = {valeur_formule:.2f}"
        formule_numeric = "VA = (" + " + ".join([f"{v:.2f}" for v in partie_plus]) + ") - (" + " + ".join([f"{v:.2f}" for v in partie_moins]) + f") = {valeur_formule:.2f}"
    ecart = round(result.get('VA', 0) - valeur_formule, 2)
    details['VA'] = {
        'formule_text': formule_text,
        'formule_numeric': formule_numeric,
        'valeur_formule': valeur_formule,
        'ecart': ecart
    }

    # 3. EXCÉDENT BRUT D'EXPLOITATION (EBE)
    va_value = result.get('VA', 0)
    subventions_exploitation = get_montant_par_indicateur_sous_ind('EBE', ["SUBVENTIONS D'EXPLOITATION"])
    impots_taxes = get_montant_par_indicateur_sous_ind('EBE', ['IMPÔTS ET TAXES'])
    charges_personnel = get_montant_par_indicateur_sous_ind('EBE', ['CHARGES DE PERSONNEL'])
    if va_value != 0 or subventions_exploitation != 0 or impots_taxes != 0 or charges_personnel != 0:
        result['EBE'] = va_value + subventions_exploitation - abs(impots_taxes) - abs(charges_personnel)
        valeur_formule = result['EBE']
    else:
        valeur_formule = 0
    partie_plus = [va_value, subventions_exploitation]
    partie_moins = [abs(impots_taxes), abs(charges_personnel)]
    if all(v == 0 for v in partie_plus + partie_moins):
        formule_text = "EBE : Non calculable"
        formule_numeric = "EBE : Non calculable"
    else:
        formule_text = f"EBE = VA ({va_value:.2f}) + SUBVENTIONS D'EXPLOITATION ({subventions_exploitation:.2f}) - IMPÔTS ET TAXES ({abs(impots_taxes):.2f}) - CHARGES DE PERSONNEL ({abs(charges_personnel):.2f}) = {valeur_formule:.2f}"
        formule_numeric = "EBE = (" + " + ".join([f"{v:.2f}" for v in partie_plus]) + ") - (" + " + ".join([f"{v:.2f}" for v in partie_moins]) + f") = {valeur_formule:.2f}"
    ecart = round(result.get('EBE', 0) - valeur_formule, 2)
    details['EBE'] = {
        'formule_text': formule_text,
        'formule_numeric': formule_numeric,
        'valeur_formule': valeur_formule,
        'ecart': ecart
    }

    # 4. RÉSULTAT D'EXPLOITATION (RE)
    ebe_value = result.get('EBE', 0)
    autres_produits = get_montant_par_indicateur_sous_ind('RE', ['AUTRES PRODUITS DE GESTION COURANTE', 'REPRISES AMORTISSEMENTS'])
    autres_charges = get_montant_par_indicateur_sous_ind('RE', ['AUTRES CHARGES DE GESTION COURANTE', 'DOTATIONS AMORTISSEMENTS'])
    if ebe_value != 0 or autres_produits != 0 or autres_charges != 0:
        result['RE'] = ebe_value + autres_produits - abs(autres_charges)
        valeur_formule = result['RE']
    else:
        valeur_formule = 0
    partie_plus = [ebe_value, autres_produits]
    partie_moins = [abs(autres_charges)]
    if all(v == 0 for v in partie_plus + partie_moins):
        formule_text = "RE : Non calculable"
        formule_numeric = "RE : Non calculable"
    else:
        formule_text = f"RE = EBE ({ebe_value:.2f}) + AUTRES PRODUITS ({autres_produits:.2f}) - AUTRES CHARGES ({abs(autres_charges):.2f}) = {valeur_formule:.2f}"
        formule_numeric = "RE = (" + " + ".join([f"{v:.2f}" for v in partie_plus]) + ") - (" + " + ".join([f"{v:.2f}" for v in partie_moins]) + f") = {valeur_formule:.2f}"
    ecart = round(result.get('RE', 0) - valeur_formule, 2)
    details['RE'] = {
        'formule_text': formule_text,
        'formule_numeric': formule_numeric,
        'valeur_formule': valeur_formule,
        'ecart': ecart
    }

    # 5. RÉSULTAT NET (R)
    re_value = result.get('RE', 0)
    produits_financiers = get_montant_par_indicateur_sous_ind('R', ['PRODUITS FINANCIERS'])
    charges_financieres = get_montant_par_indicateur_sous_ind('R', ['CHARGES FINANCIÈRES'])
    resultat_financier = produits_financiers - abs(charges_financieres)
    produits_exceptionnels = get_montant_par_indicateur_sous_ind('R', ['PRODUITS EXCEPTIONNELS'])
    charges_exceptionnelles = get_montant_par_indicateur_sous_ind('R', ['CHARGES EXCEPTIONNELLES'])
    resultat_exceptionnel = produits_exceptionnels - abs(charges_exceptionnelles)
    impots_benefices = get_montant_par_indicateur_sous_ind('R', ['IMPÔTS SUR LES BÉNÉFICES'])
    if (re_value != 0 or resultat_financier != 0 or resultat_exceptionnel != 0 or impots_benefices != 0):
        result['R'] = re_value + resultat_financier + resultat_exceptionnel - abs(impots_benefices)
        valeur_formule = result['R']
    else:
        valeur_formule = 0
    partie_plus = [re_value, produits_financiers, produits_exceptionnels]
    partie_moins = [abs(charges_financieres), abs(charges_exceptionnelles), abs(impots_benefices)]
    if all(v == 0 for v in partie_plus + partie_moins):
        formule_text = "R : Non calculable"
        formule_numeric = "R : Non calculable"
    else:
        formule_text = f"R = RE ({re_value:.2f}) + PRODUITS FINANCIERS ({produits_financiers:.2f}) + PRODUITS EXCEPTIONNELS ({produits_exceptionnels:.2f}) - CHARGES FINANCIÈRES ({abs(charges_financieres):.2f}) - CHARGES EXCEPTIONNELLES ({abs(charges_exceptionnelles):.2f}) - IMPÔTS SUR LES BÉNÉFICES ({abs(impots_benefices):.2f}) = {valeur_formule:.2f}"
        formule_numeric = "R = (" + " + ".join([f"{v:.2f}" for v in partie_plus]) + ") - (" + " + ".join([f"{v:.2f}" for v in partie_moins]) + f") = {valeur_formule:.2f}"
    ecart = round(result.get('R', 0) - valeur_formule, 2)
    details['R'] = {
        'formule_text': formule_text,
        'formule_numeric': formule_numeric,
        'valeur_formule': valeur_formule,
        'ecart': ecart
    }
