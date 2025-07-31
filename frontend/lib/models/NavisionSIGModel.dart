// --- NOUVEAUX MODÈLES POUR LES NOUVEAUX ENDPOINTS ---

// Compte mensuel paginé
class NavisionCompteMensuel {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final DateTime dateEcriture;
  final String document;
  final String utilisateur;

  NavisionCompteMensuel({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.dateEcriture,
    required this.document,
    required this.utilisateur,
  });

  factory NavisionCompteMensuel.fromJson(Map<String, dynamic> json) {
    return NavisionCompteMensuel(
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

class NavisionComptesMensuelPage {
  final int total;
  final int limit;
  final int offset;
  final List<NavisionCompteMensuel> comptes;

  NavisionComptesMensuelPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.comptes,
  });

  factory NavisionComptesMensuelPage.fromJson(Map<String, dynamic> json) {
    return NavisionComptesMensuelPage(
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      comptes: (json['comptes'] as List)
          .map((e) => NavisionCompteMensuel.fromJson(e))
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
class NavisionIndicateurMensuel {
  final String indicateur;
  final String libelle;
  final String initiales;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;

  NavisionIndicateurMensuel({
    required this.indicateur,
    required this.libelle,
    required this.initiales,
    required this.valeur,
    this.formuleText = '',
    this.formuleNumeric = '',
  });

  factory NavisionIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return NavisionIndicateurMensuel(
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

class NavisionIndicateursMensuelResponse {
  final int annee;
  final Map<String, List<NavisionIndicateurMensuel>> mois;

  NavisionIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory NavisionIndicateursMensuelResponse.fromJson(
      Map<String, dynamic> json) {
    final moisMap = <String, List<NavisionIndicateurMensuel>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, list) {
      final moisStr = mois.toString();
      moisMap[moisStr] = (list as List)
          .map((e) => NavisionIndicateurMensuel.fromJson(e))
          .toList();
    });
    return NavisionIndicateursMensuelResponse(
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

class NavisionSousIndicateurMensuel {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final String formule;
  final double montant;

  NavisionSousIndicateurMensuel({
    required this.sousIndicateur,
    required this.libelle,
    required this.initiales,
    required this.formule,
    required this.montant,
  });

  factory NavisionSousIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return NavisionSousIndicateurMensuel(
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

class NavisionSousIndicateursMensuelResponse {
  final int annee;
  final Map<String, Map<String, List<NavisionSousIndicateurMensuel>>> mois;

  NavisionSousIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory NavisionSousIndicateursMensuelResponse.fromJson(
      Map<String, dynamic> json) {
    final moisMap =
        <String, Map<String, List<NavisionSousIndicateurMensuel>>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, indicateurs) {
      // Convertir la clé mois en String (elle peut être un int ou un String dans le JSON)
      final moisStr = mois.toString();
      final indicateurMap = <String, List<NavisionSousIndicateurMensuel>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => NavisionSousIndicateurMensuel.fromJson(e))
            .toList();
      });
      moisMap[moisStr] = indicateurMap;
    });
    return NavisionSousIndicateursMensuelResponse(
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

class NavisionIndicateurGlobal {
  final String indicateur;
  final String libelle;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;

  NavisionIndicateurGlobal({
    required this.indicateur,
    required this.libelle,
    required this.valeur,
    this.formuleText = '',
    this.formuleNumeric = '',
  });

  factory NavisionIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return NavisionIndicateurGlobal(
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

class NavisionIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, List<NavisionIndicateurGlobal>>
      indicateurs; // année -> liste d'indicateurs

  NavisionIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.indicateurs,
  });

  factory NavisionIndicateursGlobalResponse.fromJson(
      Map<String, dynamic> json) {
    final indicateursMap = <String, List<NavisionIndicateurGlobal>>{};
    (json['indicateurs'] as Map<String, dynamic>).forEach((annee, list) {
      indicateursMap[annee] = (list as List)
          .map((e) => NavisionIndicateurGlobal.fromJson(e))
          .toList();
    });
    return NavisionIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      indicateurs: indicateursMap,
    );
  }
}

class NavisionSousIndicateurGlobal {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final double montant;
  final String formule;
  final List<String> associe;

  NavisionSousIndicateurGlobal({
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

  factory NavisionSousIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return NavisionSousIndicateurGlobal(
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

class NavisionSousIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, Map<String, List<NavisionSousIndicateurGlobal>>>
      sousIndicateurs; // année -> indicateur -> liste de sous-indicateurs

  NavisionSousIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.sousIndicateurs,
  });

  factory NavisionSousIndicateursGlobalResponse.fromJson(
      Map<String, dynamic> json) {
    final sousIndicsMap =
        <String, Map<String, List<NavisionSousIndicateurGlobal>>>{};
    (json['sous_indicateurs'] as Map<String, dynamic>)
        .forEach((annee, indicateurs) {
      final indicateurMap = <String, List<NavisionSousIndicateurGlobal>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => NavisionSousIndicateurGlobal.fromJson(e))
            .toList();
      });
      sousIndicsMap[annee] = indicateurMap;
    });
    return NavisionSousIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      sousIndicateurs: sousIndicsMap,
    );
  }
}

// --- MODÈLE POUR LES COMPTES GLOBALS (pagination par année) ---
class NavisionComptesGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, NavisionComptesMensuelPage>
      comptes; // année -> page paginée

  NavisionComptesGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.comptes,
  });

  factory NavisionComptesGlobalResponse.fromJson(Map<String, dynamic> json) {
    final comptesMap = <String, NavisionComptesMensuelPage>{};
    (json['comptes'] as Map<String, dynamic>).forEach((annee, page) {
      comptesMap[annee] = NavisionComptesMensuelPage.fromJson(page);
    });
    return NavisionComptesGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      comptes: comptesMap,
    );
  }
}

// --- MODÈLE POUR AFFICHAGE GLOBAL (compatibilité DataTable) ---
class NavisionCompteGlobal {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final int annee;

  NavisionCompteGlobal({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.annee,
  });

  /// Factory to safely create from dynamic or Map, always converting nulls to empty string and numbers to double
  factory NavisionCompteGlobal.fromDynamic(dynamic c, {int annee = 0}) {
    String code = (c['code_compte'] ?? c['codeCompte'] ?? '').toString();
    String libelle =
        (c['libelle_compte'] ?? c['libelleCompte'] ?? '').toString();
    double montant =
        (c['montant'] is num) ? (c['montant'] as num).toDouble() : 0.0;
    double debit = (c['debit'] is num) ? (c['debit'] as num).toDouble() : 0.0;
    double credit =
        (c['credit'] is num) ? (c['credit'] as num).toDouble() : 0.0;
    return NavisionCompteGlobal(
      codeCompte: (code == 'null') ? '' : code,
      libelleCompte: (libelle == 'null') ? '' : libelle,
      montant: montant,
      debit: debit,
      credit: credit,
      annee: annee,
    );
  }
}
