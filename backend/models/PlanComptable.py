# -*- coding: utf-8 -*-

class PlanComptable:
    """
    Represente un compte du plan comptable.
    """
    def __init__(self, data):
        self.classe = data.get('classe', '')
        self.sous_classe = data.get('sous_classe', '')
        self.code_compte = data.get('code_compte', '')
        self.libelle_compte = data.get('libelle_compte', '')
        self.bloque = data.get('bloque', False)
        self.poste_direct = data.get('poste_direct', False)
        self.type_compte = data.get('type_compte', '')
        self.sig_indicateur = data.get('sig_indicateur', '')
        self.sig_sous_indicateur = data.get('sig_sous_indicateur', '')
        self.debit = data.get('debit', 0)
        self.credit = data.get('credit', 0)

    def to_dict(self):
        return {
            'classe': self.classe,
            'sous_classe': self.sous_classe,
            'code_compte': self.code_compte,
            'libelle_compte': self.libelle_compte,
            'bloque': self.bloque,
            'poste_direct': self.poste_direct,
            'type_compte': self.type_compte,
            'sig_indicateur': self.sig_indicateur,
            'sig_sous_indicateur': self.sig_sous_indicateur,
            'debit': self.debit,
            'credit': self.credit
        }

class MappingIndicateurSIG:
    @staticmethod
    def get_libelle(sous_indicateur):
        """
        Retourne le libellé lisible pour un sous-indicateur (identique à l'entrée, mais permet d'unifier l'accès).
        """
        return sous_indicateur

    @staticmethod
    def get_initiales(sous_indicateur):
        """
        Retourne les initiales pour un sous-indicateur donné.
        """
        return MappingIndicateurSIG.get_initiales_pour_libelle(sous_indicateur)

    @staticmethod
    def get_formule(sous_indicateur):
        """
        Retourne la formule de calcul pour un sous-indicateur donné.
        """
        return MappingIndicateurSIG.get_formule_pour_sous_indicateur(sous_indicateur)
    """
    Mapping entre un code de compte et son indicateur SIG (ex: EBE, VA, MC...).
    """
    def __init__(self, prefixe_compte, indicateur, sous_indicateur=''):
        self.prefixe_compte = str(prefixe_compte)
        self.indicateur = indicateur
        self.sous_indicateur = sous_indicateur

    @staticmethod
    def get_mapping():
        """
        Liste des mappings SIG selon le plan comptable general francais.
        """
        return [
            # Classe 1 : Capitaux
            MappingIndicateurSIG('1', 'R'),
            MappingIndicateurSIG('10', 'R', 'CAPITAL'),
            MappingIndicateurSIG('106', 'R', 'RESERVES'),
            MappingIndicateurSIG('108', 'R', 'COMPTE DE LEXPLOITANT'),

            # Classe 2 : Immobilisations
            MappingIndicateurSIG('2', 'R'),
            MappingIndicateurSIG('20', 'R', 'INCORPORELLES'),
            MappingIndicateurSIG('21', 'R', 'CORPORELLES'),
            MappingIndicateurSIG('22', 'R', 'EN COURS'),
            MappingIndicateurSIG('23', 'R', 'FINANCIERES'),

            # Classe 3 : Stocks
            MappingIndicateurSIG('3', 'MC'),
            MappingIndicateurSIG('31', 'MC', 'MATIERES PREMIERES'),
            MappingIndicateurSIG('32', 'MC', 'AUTRES APPROVISIONNEMENTS'),
            MappingIndicateurSIG('33', 'MC', 'EN-COURS DE PRODUCTION'),
            MappingIndicateurSIG('34', 'MC', 'STOCKS DE PRODUITS'),
            MappingIndicateurSIG('35', 'MC', 'STOCKS DE MARCHANDISES'),

            # Classe 4 : Tiers
            MappingIndicateurSIG('4', 'MC'),
            MappingIndicateurSIG('40', 'MC', 'FOURNISSEURS'),
            MappingIndicateurSIG('408', 'MC', 'FACTURES NON PARVENUES'),
            MappingIndicateurSIG('41', 'MC', 'CLIENTS'),
            MappingIndicateurSIG('419', 'MC', 'AVANCES ET ACOMPTES CLIENTS'),
            MappingIndicateurSIG('42', 'MC', 'PERSONNEL'),
            MappingIndicateurSIG('43', 'MC', 'ORGANISMES SOCIAUX'),
            MappingIndicateurSIG('445', 'MC', 'TVA'),
            MappingIndicateurSIG('4456', 'MC', 'TVA DEDUCTIBLE'),
            MappingIndicateurSIG('4457', 'MC', 'TVA COLLECTEE'),
            MappingIndicateurSIG('46', 'MC', 'DIVERS'),
            MappingIndicateurSIG('47', 'MC', 'TRANSITOIRES'),

            # Classe 5 : Financiers
            MappingIndicateurSIG('5', 'MC'),
            MappingIndicateurSIG('50', 'MC', 'VMP'),
            MappingIndicateurSIG('51', 'MC', 'BANQUES'),
            MappingIndicateurSIG('53', 'MC', 'CAISSE'),

            # Classe 6 : Charges
            MappingIndicateurSIG('6', 'VA'),
            MappingIndicateurSIG('601', 'VA', 'ACHATS STOCKES'),
            MappingIndicateurSIG('6011', 'VA', 'MATIERES PREMIERES'),
            MappingIndicateurSIG('602', 'VA', 'ACHATS NON STOCKES'),
            MappingIndicateurSIG('606', 'VA', 'FOURNITURES'),
            MappingIndicateurSIG('6061', 'VA', 'FOURNITURES ADMINISTRATIVES'),
            MappingIndicateurSIG('607', 'MC', 'ACHATS DE MARCHANDISES'),
            MappingIndicateurSIG('61', 'EBE', 'SERVICES EXTÉRIEURS'),
            MappingIndicateurSIG('62', 'EBE', 'AUTRES SERVICES EXTÉRIEURS'),
            MappingIndicateurSIG('63', 'RE', 'IMPÔTS ET TAXES'),
            MappingIndicateurSIG('64', 'EBE', 'CHARGES DE PERSONNEL'),
            MappingIndicateurSIG('65', 'RE', 'AUTRES CHARGES DE GESTION COURANTE'),
            MappingIndicateurSIG('66', 'R', 'CHARGES FINANCIÈRES'),
            MappingIndicateurSIG('67', 'R', 'CHARGES EXCEPTIONNELLES'),
            MappingIndicateurSIG('68', 'RE', 'DOTATIONS AMORTISSEMENTS'),
            MappingIndicateurSIG('681', 'RE', 'DOTATIONS AMORTISSEMENTS'),
            MappingIndicateurSIG('69', 'R', 'IMPÔTS SUR LES BÉNÉFICES'),

            # Classe 7 : Produits
            MappingIndicateurSIG('7', 'VA'),
            MappingIndicateurSIG('701', 'MC', 'VENTES DE PRODUITS FINIS'),
            MappingIndicateurSIG('702', 'MC', 'VENTES DE SERVICES'),
            MappingIndicateurSIG('706', 'MC', 'PRESTATIONS DE SERVICES'),
            MappingIndicateurSIG('707', 'MC', 'VENTES DE MARCHANDISES'),
            MappingIndicateurSIG('71', 'EBE', 'PRODUCTION STOCKÉE'),
            MappingIndicateurSIG('72', 'EBE', 'PRODUCTION IMMOBILISÉE'),
            MappingIndicateurSIG('73', 'EBE', 'SUBVENTIONS D\'EXPLOITATION'),
            MappingIndicateurSIG('74', 'RE', 'AUTRES PRODUITS DE GESTION COURANTE'),
            MappingIndicateurSIG('75', 'RE', 'PRODUITS FINANCIERS'),
            MappingIndicateurSIG('76', 'R', 'PRODUITS EXCEPTIONNELS'),
            MappingIndicateurSIG('77', 'R', 'PRODUITS EXCEPTIONNELS'),
            MappingIndicateurSIG('78', 'RE', 'REPRISES AMORTISSEMENTS'),
            MappingIndicateurSIG('79', 'R', 'TRANSFERTS DE CHARGES'),

            # Classe 8 : Speciaux
            MappingIndicateurSIG('8', 'R'),
            MappingIndicateurSIG('86', 'R', 'ENGAGEMENTS DONNES'),
            MappingIndicateurSIG('87', 'R', 'ENGAGEMENTS RECUS'),
        ]

    @staticmethod
    def find_best_mapping(code_compte):
        """
        Recherche le meilleur mapping SIG pour un code de compte donne.
        Exemple : pour '6061', il retournera dabord 6061, puis 606, puis 60, puis 6.
        """
        code = str(code_compte)
        mappings = MappingIndicateurSIG.get_mapping()

        for length in range(len(code), 0, -1):
            prefix = code[:length]
            for mapping in mappings:
                if mapping.prefixe_compte == prefix:
                    return mapping
        return None

    @staticmethod
    def get_sous_indicateur_initiales():
        """
        Mapping des libellés de sous-indicateurs vers leurs initiales/abréviations.
        """
        return {
            # Classe 1 : Capitaux
            'CAPITAL': 'CAP',
            'RESERVES': 'RES',
            'COMPTE DE LEXPLOITANT': 'CDL',
            
            # Classe 2 : Immobilisations
            'INCORPORELLES': 'INC',
            'CORPORELLES': 'CORP',
            'EN COURS': 'EC',
            'FINANCIERES': 'FIN',
            
            # Classe 3 : Stocks
            'MATIERES PREMIERES': 'MP',
            'AUTRES APPROVISIONNEMENTS': 'APPR',
            'EN-COURS DE PRODUCTION': 'ECDP',
            'STOCKS DE PRODUITS': 'SDP',
            'STOCKS DE MARCHANDISES': 'SDM',
            
            # Classe 4 : Tiers
            'FOURNISSEURS': 'FRN',
            'FACTURES NON PARVENUES': 'FNP',
            'CLIENTS': 'CLI',
            'AVANCES ET ACOMPTES CLIENTS': 'AAC',
            'PERSONNEL': 'PERS',
            'ORGANISMES SOCIAUX': 'ORGSOC',
            'TVA': 'TVA',
            'TVA DEDUCTIBLE': 'TD',
            'TVA COLLECTEE': 'TC',
            'DIVERS': 'DIV',
            'TRANSITOIRES': 'TRANS',
            
            # Classe 5 : Financiers
            'VMP': 'VMP',
            'BANQUES': 'BQ',
            'CAISSE': 'CAISSE',
            
            # Classe 6 : Charges
            'ACHATS STOCKES': 'AS',
            'ACHATS NON STOCKES': 'ANS',
            'FOURNITURES': 'FRN',
            'FOURNITURES ADMINISTRATIVES': 'FA',
            'ACHATS DE MARCHANDISES': 'ADM',
            'SERVICES EXTÉRIEURS': 'SE',
            'AUTRES SERVICES EXTÉRIEURS': 'ASE',
            'IMPÔTS ET TAXES': 'IT',
            'CHARGES DE PERSONNEL': 'CDP',
            'AUTRES CHARGES DE GESTION COURANTE': 'ACGC',
            'CHARGES FINANCIÈRES': 'CF',
            'CHARGES EXCEPTIONNELLES': 'CE',
            'DOTATIONS AMORTISSEMENTS': 'DA',
            'IMPÔTS SUR LES BÉNÉFICES': 'ISLB',
            
            # Classe 7 : Produits
            'VENTES DE PRODUITS FINIS': 'VDPF',
            'VENTES DE SERVICES': 'VDS',
            'PRESTATIONS DE SERVICES': 'PDS',
            'VENTES DE MARCHANDISES': 'VDM',
            'PRODUCTION STOCKÉE': 'PS',
            'PRODUCTION IMMOBILISÉE': 'PI',
            'SUBVENTIONS D\'EXPLOITATION': 'SE',
            'AUTRES PRODUITS DE GESTION COURANTE': 'APDGC',
            'PRODUITS FINANCIERS': 'PF',
            'PRODUITS EXCEPTIONNELS': 'PE',
            'REPRISES AMORTISSEMENTS': 'RA',
            'TRANSFERTS DE CHARGES': 'TDC',
            
            # Classe 8 : Speciaux
            'ENGAGEMENTS DONNES': 'ED',
            'ENGAGEMENTS RECUS': 'ER',
        }

    @staticmethod
    def get_initiales_pour_libelle(libelle):
        """
        Retourne les initiales pour un libellé de sous-indicateur donné.
        """
        mapping = MappingIndicateurSIG.get_sous_indicateur_initiales()
        return mapping.get(libelle, libelle[:5].upper())  # Fallback: premiers 5 caractères en majuscules

    @staticmethod
    def get_formule_pour_sous_indicateur(sous_indicateur):
        """
        Retourne la formule de calcul pour un sous-indicateur donné.
        """
        formules = {
            # Classe 3 : Stocks (Actif - Solde = Débit - Crédit)
            'MATIERES PREMIERES': 'Σ (Débit - Crédit) des comptes 31*',
            'AUTRES APPROVISIONNEMENTS': 'Σ (Débit - Crédit) des comptes 32*',
            'EN-COURS DE PRODUCTION': 'Σ (Débit - Crédit) des comptes 33*',
            'STOCKS DE PRODUITS': 'Σ (Débit - Crédit) des comptes 34*',
            'STOCKS DE MARCHANDISES': 'Σ (Débit - Crédit) des comptes 35*',
            
            # Classe 4 : Tiers (Actif - Solde = Débit - Crédit)
            'FOURNISSEURS': 'Σ (Débit - Crédit) des comptes 40*',
            'FACTURES NON PARVENUES': 'Σ (Débit - Crédit) des comptes 408*',
            'CLIENTS': 'Σ (Débit - Crédit) des comptes 41*',
            'AVANCES ET ACOMPTES CLIENTS': 'Σ (Débit - Crédit) des comptes 419*',
            'PERSONNEL': 'Σ (Débit - Crédit) des comptes 42*',
            'ORGANISMES SOCIAUX': 'Σ (Débit - Crédit) des comptes 43*',
            'TVA': 'Σ (Débit - Crédit) des comptes 445*',
            'TVA DEDUCTIBLE': 'Σ (Débit - Crédit) des comptes 4456*',
            'TVA COLLECTEE': 'Σ (Débit - Crédit) des comptes 4457*',
            'DIVERS': 'Σ (Débit - Crédit) des comptes 46*',
            'TRANSITOIRES': 'Σ (Débit - Crédit) des comptes 47*',
            
            # Classe 5 : Financiers (Actif - Solde = Débit - Crédit)
            'VMP': 'Σ (Débit - Crédit) des comptes 50*',
            'BANQUES': 'Σ (Débit - Crédit) des comptes 51*',
            'CAISSE': 'Σ (Débit - Crédit) des comptes 53*',
            
            # Classe 6 : Charges (Actif - Solde = Débit - Crédit)
            'ACHATS STOCKES': 'Σ (Débit - Crédit) des comptes 601*',
            'ACHATS NON STOCKES': 'Σ (Débit - Crédit) des comptes 602*',
            'FOURNITURES': 'Σ (Débit - Crédit) des comptes 606*',
            'FOURNITURES ADMINISTRATIVES': 'Σ (Débit - Crédit) des comptes 6061*',
            'ACHATS DE MARCHANDISES': 'Σ (Débit - Crédit) des comptes 607*',
            'SERVICES EXTÉRIEURS': 'Σ (Débit - Crédit) des comptes 61*',
            'AUTRES SERVICES EXTÉRIEURS': 'Σ (Débit - Crédit) des comptes 62*',
            'IMPÔTS ET TAXES': 'Σ (Débit - Crédit) des comptes 63*',
            'CHARGES DE PERSONNEL': 'Σ (Débit - Crédit) des comptes 64*',
            'AUTRES CHARGES DE GESTION COURANTE': 'Σ (Débit - Crédit) des comptes 65*',
            'CHARGES FINANCIÈRES': 'Σ (Débit - Crédit) des comptes 66*',
            'CHARGES EXCEPTIONNELLES': 'Σ (Débit - Crédit) des comptes 67*',
            'DOTATIONS AMORTISSEMENTS': 'Σ (Débit - Crédit) des comptes 68*',
            'IMPÔTS SUR LES BÉNÉFICES': 'Σ (Débit - Crédit) des comptes 69*',
            
            # Classe 7 : Produits (Passif - Solde = Crédit - Débit)
            'VENTES DE PRODUITS FINIS': 'Σ (Crédit - Débit) des comptes 701*',
            'VENTES DE SERVICES': 'Σ (Crédit - Débit) des comptes 702*',
            'PRESTATIONS DE SERVICES': 'Σ (Crédit - Débit) des comptes 706*',
            'VENTES DE MARCHANDISES': 'Σ (Crédit - Débit) des comptes 707*',
            'PRODUCTION STOCKÉE': 'Σ (Crédit - Débit) des comptes 71*',
            'PRODUCTION IMMOBILISÉE': 'Σ (Crédit - Débit) des comptes 72*',
            'SUBVENTIONS D\'EXPLOITATION': 'Σ (Crédit - Débit) des comptes 73*',
            'AUTRES PRODUITS DE GESTION COURANTE': 'Σ (Crédit - Débit) des comptes 74*',
            'PRODUITS FINANCIERS': 'Σ (Crédit - Débit) des comptes 75*',
            'PRODUITS EXCEPTIONNELS': 'Σ (Crédit - Débit) des comptes 76* + 77*',
            'REPRISES AMORTISSEMENTS': 'Σ (Crédit - Débit) des comptes 78*',
            'TRANSFERTS DE CHARGES': 'Σ (Crédit - Débit) des comptes 79*',
            
            # Classe 1 : Capitaux (Actif - Solde = Débit - Crédit)
            'CAPITAL': 'Σ (Débit - Crédit) des comptes 10*',
            'RESERVES': 'Σ (Débit - Crédit) des comptes 106*',
            'COMPTE DE LEXPLOITANT': 'Σ (Débit - Crédit) des comptes 108*',
            
            # Classe 2 : Immobilisations (Actif - Solde = Débit - Crédit)
            'INCORPORELLES': 'Σ (Débit - Crédit) des comptes 20*',
            'CORPORELLES': 'Σ (Débit - Crédit) des comptes 21*',
            'EN COURS': 'Σ (Débit - Crédit) des comptes 22*',
            'FINANCIERES': 'Σ (Débit - Crédit) des comptes 23*',
            
            # Classe 8 : Speciaux (Actif - Solde = Débit - Crédit)
            'ENGAGEMENTS DONNES': 'Σ (Débit - Crédit) des comptes 86*',
            'ENGAGEMENTS RECUS': 'Σ (Débit - Crédit) des comptes 87*',
        }
        
        return formules.get(sous_indicateur, f'Σ (Crédit - Débit) des comptes liés à "{sous_indicateur}"')

    @staticmethod
    def get_associe_mapping():
        """
        Mapping exhaustif des indicateurs SIG vers tous les sous-indicateurs impliqués dans leur formule.
        """
        return {
            'MC': [
                'VENTES DE MARCHANDISES', 'VENTES DE PRODUITS FINIS', 'VENTES DE SERVICES', 'PRESTATIONS DE SERVICES', 'TVA COLLECTEE',
                'ACHATS DE MARCHANDISES'
            ],
            'VA': [
                'MC', 'PRESTATIONS DE SERVICES', 'VENTES DE PRODUITS FINIS', 'PRODUCTION STOCKÉE', 'PRODUCTION IMMOBILISÉE',
                'ACHATS STOCKES', 'ACHATS NON STOCKES', 'FOURNITURES', 'SERVICES EXTÉRIEURS', 'AUTRES SERVICES EXTÉRIEURS'
            ],
            'EBE': [
                'VA', "SUBVENTIONS D'EXPLOITATION", 'IMPÔTS ET TAXES', 'CHARGES DE PERSONNEL'
            ],
            'RE': [
                'EBE', 'AUTRES PRODUITS DE GESTION COURANTE', 'REPRISES AMORTISSEMENTS',
                'AUTRES CHARGES DE GESTION COURANTE', 'DOTATIONS AMORTISSEMENTS'
            ],
            'R': [
                'RE', 'PRODUITS FINANCIERS', 'CHARGES FINANCIÈRES', 'PRODUITS EXCEPTIONNELS', 'CHARGES EXCEPTIONNELLES', 'IMPÔTS SUR LES BÉNÉFICES'
            ],
        }