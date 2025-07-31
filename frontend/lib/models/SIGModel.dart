// --- NOUVEAUX MODÈLES POUR LES NOUVEAUX ENDPOINTS ---

// Compte mensuel paginé
class SIGCompteMensuel {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final DateTime dateEcriture;
  final String document;
  final String utilisateur;

  SIGCompteMensuel({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.dateEcriture,
    required this.document,
    required this.utilisateur,
  });

  factory SIGCompteMensuel.fromJson(Map<String, dynamic> json) {
    return SIGCompteMensuel(
      codeCompte: json['code_compte'],
      libelleCompte: json['libelle_compte'],
      montant: (json['montant'] as num).toDouble(),
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      dateEcriture:
          DateTime.tryParse(json['date_ecriture'] ?? '') ?? DateTime(2000),
      document: json['document'] ?? '',
      utilisateur: json['utilisateur'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code_compte': codeCompte,
      'libelle_compte': libelleCompte,
      'montant': montant,
      'debit': debit,
      'credit': credit,
      'date_ecriture': dateEcriture.toIso8601String(),
      'document': document,
      'utilisateur': utilisateur,
    };
  }
}

class SIGComptesMensuelPage {
  final int total;
  final int limit;
  final int offset;
  final List<SIGCompteMensuel> comptes;

  SIGComptesMensuelPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.comptes,
  });

  factory SIGComptesMensuelPage.fromJson(Map<String, dynamic> json) {
    return SIGComptesMensuelPage(
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      comptes: (json['comptes'] as List)
          .map((e) => SIGCompteMensuel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'limit': limit,
      'offset': offset,
      'comptes': comptes.map((e) => e.toJson()).toList(),
    };
  }
}

// Indicateur mensuel
class SIGIndicateurMensuel {
  final String indicateur;
  final String libelle;
  final String initiales;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;

  SIGIndicateurMensuel({
    required this.indicateur,
    required this.libelle,
    required this.initiales,
    required this.valeur,
    this.formuleText = '',
    this.formuleNumeric = '',
  });

  factory SIGIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return SIGIndicateurMensuel(
      indicateur: json['indicateur'],
      libelle: json['libelle'],
      initiales: json['initiales'] ?? '',
      valeur: (json['valeur_calculee'] as num?)?.toDouble() ??
          (json['valeur'] as num?)?.toDouble() ??
          0.0,
      formuleText: json['formule_text'] ?? '',
      formuleNumeric: json['formule_numeric'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indicateur': indicateur,
      'libelle': libelle,
      'initiales': initiales,
      'valeur': valeur,
      'formule_text': formuleText,
      'formule_numeric': formuleNumeric,
    };
  }
}

class SIGIndicateursMensuelResponse {
  final int annee;
  final Map<String, List<SIGIndicateurMensuel>> mois;

  SIGIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory SIGIndicateursMensuelResponse.fromJson(Map<String, dynamic> json) {
    final moisMap = <String, List<SIGIndicateurMensuel>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, list) {
      final moisStr = mois.toString();
      moisMap[moisStr] =
          (list as List).map((e) => SIGIndicateurMensuel.fromJson(e)).toList();
    });
    return SIGIndicateursMensuelResponse(
      annee: json['annee'],
      mois: moisMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annee': annee,
      'mois': mois.map((key, value) => MapEntry(
            key,
            value.map((e) => e.toJson()).toList(),
          )),
    };
  }
}

class SIGSousIndicateurMensuel {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final String formule;
  final double montant;

  SIGSousIndicateurMensuel({
    required this.sousIndicateur,
    required this.libelle,
    required this.initiales,
    required this.formule,
    required this.montant,
  });

  factory SIGSousIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return SIGSousIndicateurMensuel(
      sousIndicateur: json['sousIndicateur'] ?? '',
      libelle: json['libelle'] ?? '',
      initiales: json['initiales'] ?? '',
      formule: json['formule'] ?? '',
      montant: (json['montant'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sousIndicateur': sousIndicateur,
      'libelle': libelle,
      'initiales': initiales,
      'formule': formule,
      'montant': montant,
    };
  }
}

class SIGSousIndicateursMensuelResponse {
  final int annee;
  final Map<String, Map<String, List<SIGSousIndicateurMensuel>>> mois;

  SIGSousIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory SIGSousIndicateursMensuelResponse.fromJson(
      Map<String, dynamic> json) {
    final moisMap = <String, Map<String, List<SIGSousIndicateurMensuel>>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, indicateurs) {
      // Convertir la clé mois en String (elle peut être un int ou un String dans le JSON)
      final moisStr = mois.toString();
      final indicateurMap = <String, List<SIGSousIndicateurMensuel>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => SIGSousIndicateurMensuel.fromJson(e))
            .toList();
      });
      moisMap[moisStr] = indicateurMap;
    });
    return SIGSousIndicateursMensuelResponse(
      annee: json['annee'],
      mois: moisMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annee': annee,
      'mois': mois.map((moisKey, indicateurMap) => MapEntry(
            moisKey,
            indicateurMap.map((indicateurKey, list) => MapEntry(
                  indicateurKey,
                  list.map((e) => e.toJson()).toList(),
                )),
          )),
    };
  }
}

// --- MODÈLES POUR LES ENDPOINTS GLOBAUX ---

class SIGIndicateurGlobal {
  final String indicateur;
  final String libelle;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;

  SIGIndicateurGlobal({
    required this.indicateur,
    required this.libelle,
    required this.valeur,
    this.formuleText = '',
    this.formuleNumeric = '',
  });

  factory SIGIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return SIGIndicateurGlobal(
      indicateur: json['indicateur'] ?? '',
      libelle: json['libelle'] ?? '',
      valeur: (json['valeur_calculee'] ?? json['valeur'] ?? 0).toDouble(),
      formuleText: json['formule_text'] ?? json['formuleText'] ?? '',
      formuleNumeric: json['formule_numeric'] ?? json['formuleNumeric'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indicateur': indicateur,
      'libelle': libelle,
      'valeur': valeur,
      'formule_text': formuleText,
      'formule_numeric': formuleNumeric,
    };
  }
}

class SIGIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, List<SIGIndicateurGlobal>>
      indicateurs; // année -> liste d'indicateurs

  SIGIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.indicateurs,
  });

  factory SIGIndicateursGlobalResponse.fromJson(Map<String, dynamic> json) {
    final indicateursMap = <String, List<SIGIndicateurGlobal>>{};
    (json['indicateurs'] as Map<String, dynamic>).forEach((annee, list) {
      indicateursMap[annee] =
          (list as List).map((e) => SIGIndicateurGlobal.fromJson(e)).toList();
    });
    return SIGIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      indicateurs: indicateursMap,
    );
  }
}

class SIGSousIndicateurGlobal {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final double montant;
  final String formule;
  final List<String> associe;

  SIGSousIndicateurGlobal({
    required this.sousIndicateur,
    required this.libelle,
    required this.initiales,
    required this.montant,
    required this.formule,
    this.associe = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sousIndicateur': sousIndicateur,
      'libelle': libelle,
      'initiales': initiales,
      'montant': montant,
      'formule': formule,
      'associe': associe,
    };
  }

  factory SIGSousIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return SIGSousIndicateurGlobal(
      sousIndicateur: json['sousIndicateur'] ?? '',
      libelle: json['libelle'] ?? '',
      initiales: json['initiales'] ?? '',
      montant: (json['montant'] as num).toDouble(),
      formule: json['formule'] ?? '',
      associe: (json['associe'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class SIGSousIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, Map<String, List<SIGSousIndicateurGlobal>>>
      sousIndicateurs; // année -> indicateur -> liste de sous-indicateurs

  SIGSousIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.sousIndicateurs,
  });

  factory SIGSousIndicateursGlobalResponse.fromJson(Map<String, dynamic> json) {
    final sousIndicsMap =
        <String, Map<String, List<SIGSousIndicateurGlobal>>>{};
    (json['sous_indicateurs'] as Map<String, dynamic>)
        .forEach((annee, indicateurs) {
      final indicateurMap = <String, List<SIGSousIndicateurGlobal>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => SIGSousIndicateurGlobal.fromJson(e))
            .toList();
      });
      sousIndicsMap[annee] = indicateurMap;
    });
    return SIGSousIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      sousIndicateurs: sousIndicsMap,
    );
  }
}

// --- MODÈLE POUR LES COMPTES GLOBALS (pagination par année) ---
class SIGComptesGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, SIGComptesMensuelPage> comptes; // année -> page paginée

  SIGComptesGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.comptes,
  });

  factory SIGComptesGlobalResponse.fromJson(Map<String, dynamic> json) {
    final comptesMap = <String, SIGComptesMensuelPage>{};
    (json['comptes'] as Map<String, dynamic>).forEach((annee, page) {
      comptesMap[annee] = SIGComptesMensuelPage.fromJson(page);
    });
    return SIGComptesGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      comptes: comptesMap,
    );
  }
}

// --- MODÈLE POUR AFFICHAGE GLOBAL (compatibilité DataTable) ---
class SIGCompteGlobal {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final int annee;

  SIGCompteGlobal({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.annee,
  });

  /// Factory to safely create from dynamic or Map, always converting nulls to empty string and numbers to double
  factory SIGCompteGlobal.fromDynamic(dynamic c, {int annee = 0}) {
    String code = (c['code_compte'] ?? c['codeCompte'] ?? '').toString();
    String libelle =
        (c['libelle_compte'] ?? c['libelleCompte'] ?? '').toString();
    double montant =
        (c['montant'] is num) ? (c['montant'] as num).toDouble() : 0.0;
    double debit = (c['debit'] is num) ? (c['debit'] as num).toDouble() : 0.0;
    double credit =
        (c['credit'] is num) ? (c['credit'] as num).toDouble() : 0.0;
    return SIGCompteGlobal(
      codeCompte: (code == 'null') ? '' : code,
      libelleCompte: (libelle == 'null') ? '' : libelle,
      montant: montant,
      debit: debit,
      credit: credit,
      annee: annee,
    );
  }
}
