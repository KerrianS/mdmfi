// --- MODÈLES ODOO SIG ---
// Généré sur la base de NavisionSIGModel.dart, adapté pour Odoo

class OdooCompteMensuel {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final DateTime dateEcriture;
  final String document;
  final String utilisateur;

  OdooCompteMensuel({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.dateEcriture,
    required this.document,
    required this.utilisateur,
  });

  factory OdooCompteMensuel.fromJson(Map<String, dynamic> json) {
    return OdooCompteMensuel(
      codeCompte: json['code_compte'],
      libelleCompte: json['libelle_compte'],
      montant: (json['montant'] as num).toDouble(),
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      dateEcriture: DateTime.tryParse(json['date_ecriture'] ?? '') ?? DateTime(2000),
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

class OdooComptesMensuelPage {
  final int total;
  final int limit;
  final int offset;
  final List<OdooCompteMensuel> comptes;

  OdooComptesMensuelPage({
    required this.total,
    required this.limit,
    required this.offset,
    required this.comptes,
  });

  factory OdooComptesMensuelPage.fromJson(Map<String, dynamic> json) {
    return OdooComptesMensuelPage(
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      comptes: (json['comptes'] as List)
          .map((e) => OdooCompteMensuel.fromJson(e))
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

class OdooIndicateurMensuel {
  final String indicateur;
  final String libelle;
  final String initiales;
  final double valeur;
  final List<String> associe;

  OdooIndicateurMensuel({
    required this.indicateur,
    required this.libelle,
    required this.initiales,
    required this.valeur,
    this.associe = const [],
  });

  factory OdooIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return OdooIndicateurMensuel(
      indicateur: json['indicateur'],
      libelle: json['libelle'],
      initiales: json['initiales'] ?? '',
      valeur: (json['valeur'] as num).toDouble(),
      associe: (json['associe'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indicateur': indicateur,
      'libelle': libelle,
      'initiales': initiales,
      'valeur': valeur,
      'associe': associe,
    };
  }
}

class OdooIndicateursMensuelResponse {
  final int annee;
  final Map<String, List<OdooIndicateurMensuel>> mois;

  OdooIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory OdooIndicateursMensuelResponse.fromJson(Map<String, dynamic> json) {
    final moisMap = <String, List<OdooIndicateurMensuel>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, list) {
      final moisStr = mois.toString();
      moisMap[moisStr] = (list as List)
          .map((e) => OdooIndicateurMensuel.fromJson(e))
          .toList();
    });
    return OdooIndicateursMensuelResponse(
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

class OdooSousIndicateurMensuel {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final String formule;
  final double montant;

  OdooSousIndicateurMensuel({
    required this.sousIndicateur,
    required this.libelle,
    required this.initiales,
    required this.formule,
    required this.montant,
  });

  factory OdooSousIndicateurMensuel.fromJson(Map<String, dynamic> json) {
    return OdooSousIndicateurMensuel(
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

class OdooSousIndicateursMensuelResponse {
  final int annee;
  final Map<String, Map<String, List<OdooSousIndicateurMensuel>>> mois;

  OdooSousIndicateursMensuelResponse({
    required this.annee,
    required this.mois,
  });

  factory OdooSousIndicateursMensuelResponse.fromJson(Map<String, dynamic> json) {
    final moisMap = <String, Map<String, List<OdooSousIndicateurMensuel>>>{};
    (json['mois'] as Map<String, dynamic>).forEach((mois, indicateurs) {
      final moisStr = mois.toString();
      final indicateurMap = <String, List<OdooSousIndicateurMensuel>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => OdooSousIndicateurMensuel.fromJson(e))
            .toList();
      });
      moisMap[moisStr] = indicateurMap;
    });
    return OdooSousIndicateursMensuelResponse(
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

// --- MODÈLES GLOBAUX ODOO ---

class OdooIndicateurGlobal {
  final String indicateur;
  final String libelle;
  final double valeur;
  final List<String> associe;

  OdooIndicateurGlobal({
    required this.indicateur,
    required this.libelle,
    required this.valeur,
    required this.associe,
  });

  factory OdooIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return OdooIndicateurGlobal(
      indicateur: json['indicateur'] ?? '',
      libelle: json['libelle'] ?? '',
      valeur: (json['valeur'] as num).toDouble(),
      associe: (json['associe'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'indicateur': indicateur,
      'libelle': libelle,
      'valeur': valeur,
      'associe': associe,
    };
  }
}

class OdooIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, List<OdooIndicateurGlobal>> indicateurs;

  OdooIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.indicateurs,
  });

  factory OdooIndicateursGlobalResponse.fromJson(Map<String, dynamic> json) {
    final indicateursMap = <String, List<OdooIndicateurGlobal>>{};
    (json['indicateurs'] as Map<String, dynamic>).forEach((annee, list) {
      indicateursMap[annee] = (list as List)
          .map((e) => OdooIndicateurGlobal.fromJson(e))
          .toList();
    });
    return OdooIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      indicateurs: indicateursMap,
    );
  }
}

class OdooSousIndicateurGlobal {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final double montant;
  final String formule;
  final List<String> associe;

  OdooSousIndicateurGlobal({
    required this.sousIndicateur,
    required this.libelle,
    required this.initiales,
    required this.montant,
    required this.formule,
    required this.associe,
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

  factory OdooSousIndicateurGlobal.fromJson(Map<String, dynamic> json) {
    return OdooSousIndicateurGlobal(
      sousIndicateur: json['sousIndicateur'] ?? '',
      libelle: json['libelle'] ?? '',
      initiales: json['initiales'] ?? '',
      montant: (json['montant'] as num).toDouble(),
      formule: json['formule'] ?? '',
      associe: (json['associe'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class OdooSousIndicateursGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, Map<String, List<OdooSousIndicateurGlobal>>> sousIndicateurs;

  OdooSousIndicateursGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.sousIndicateurs,
  });

  factory OdooSousIndicateursGlobalResponse.fromJson(Map<String, dynamic> json) {
    final sousIndicsMap = <String, Map<String, List<OdooSousIndicateurGlobal>>>{};
    (json['sous_indicateurs'] as Map<String, dynamic>).forEach((annee, indicateurs) {
      final indicateurMap = <String, List<OdooSousIndicateurGlobal>>{};
      (indicateurs as Map<String, dynamic>).forEach((indicateur, list) {
        indicateurMap[indicateur] = (list as List)
            .map((e) => OdooSousIndicateurGlobal.fromJson(e))
            .toList();
      });
      sousIndicsMap[annee] = indicateurMap;
    });
    return OdooSousIndicateursGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      sousIndicateurs: sousIndicsMap,
    );
  }
}

class OdooComptesGlobalResponse {
  final String periode;
  final int? trimestre;
  final Map<String, OdooComptesMensuelPage> comptes;

  OdooComptesGlobalResponse({
    required this.periode,
    this.trimestre,
    required this.comptes,
  });

  factory OdooComptesGlobalResponse.fromJson(Map<String, dynamic> json) {
    final comptesMap = <String, OdooComptesMensuelPage>{};
    (json['comptes'] as Map<String, dynamic>).forEach((annee, page) {
      comptesMap[annee] = OdooComptesMensuelPage.fromJson(page);
    });
    return OdooComptesGlobalResponse(
      periode: json['periode'],
      trimestre: json['trimestre'],
      comptes: comptesMap,
    );
  }
}

class OdooCompteGlobal {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final int annee;

  OdooCompteGlobal({
    required this.codeCompte,
    required this.libelleCompte,
    required this.montant,
    required this.debit,
    required this.credit,
    required this.annee,
  });

  factory OdooCompteGlobal.fromDynamic(dynamic c, {int annee = 0}) {
    String code = (c['code_compte'] ?? c['codeCompte'] ?? '').toString();
    String libelle = (c['libelle_compte'] ?? c['libelleCompte'] ?? '').toString();
    double montant = (c['montant'] is num) ? (c['montant'] as num).toDouble() : 0.0;
    double debit = (c['debit'] is num) ? (c['debit'] as num).toDouble() : 0.0;
    double credit = (c['credit'] is num) ? (c['credit'] as num).toDouble() : 0.0;
    return OdooCompteGlobal(
      codeCompte: (code == 'null') ? '' : code,
      libelleCompte: (libelle == 'null') ? '' : libelle,
      montant: montant,
      debit: debit,
      credit: credit,
      annee: annee,
    );
  }
}
