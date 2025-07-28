import 'package:hive/hive.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';


class NavisionServiceCache {
  static const String navisionBox = 'navision_cache';

  // --- Save generic Navision data ---
  Future<void> saveData<T>(String societe, String type, T data, Map<String, dynamic> Function() toJson) async {
    var box = await Hive.openBox(navisionBox);
    box.put('${type}_$societe', toJson());
    box.put('${type}_${societe}_last_update', DateTime.now().toIso8601String());
  }

  // --- Load generic Navision data ---
  Future<T?> loadData<T>(String societe, String type, T Function(Map<String, dynamic>) fromJson) async {
    var box = await Hive.openBox(navisionBox);
    final json = box.get('${type}_$societe');
    if (json != null) {
      return fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  // --- Get last update for a type ---
  Future<DateTime?> getLastUpdate(String societe, String type) async {
    var box = await Hive.openBox(navisionBox);
    final dateStr = box.get('${type}_${societe}_last_update');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // --- Specific helpers for each Navision type ---
  Future<void> saveIndicateursMensuel(String societe, NavisionIndicateursMensuelResponse data) async {
    await saveData<NavisionIndicateursMensuelResponse>(
      societe,
      'navision_indicateurs_mensuel',
      data,
      () => data.toJson(),
    );
  }

  Future<NavisionIndicateursMensuelResponse?> loadIndicateursMensuel(String societe) async {
    return await loadData<NavisionIndicateursMensuelResponse>(
      societe,
      'navision_indicateurs_mensuel',
      (json) => NavisionIndicateursMensuelResponse.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateIndicateursMensuel(String societe) async {
    return await getLastUpdate(societe, 'navision_indicateurs_mensuel');
  }

  // Tu peux ajouter d'autres méthodes pour les autres modèles Navision ici
  // Exemple : comptes, global, sous-indicateurs, etc.


  // --- Comptes mensuels paginés ---
  Future<void> saveComptesMensuel(String societe, NavisionComptesMensuelPage data) async {
    await saveData<NavisionComptesMensuelPage>(
      societe,
      'navision_comptes_mensuel',
      data,
      () => {
        'total': data.total,
        'limit': data.limit,
        'offset': data.offset,
        'comptes': data.comptes.map((e) => {
          'code_compte': e.codeCompte,
          'libelle_compte': e.libelleCompte,
          'montant': e.montant,
          'date_ecriture': e.dateEcriture.toIso8601String(),
          'document': e.document,
          'utilisateur': e.utilisateur,
        }).toList(),
      },
    );
  }

  Future<NavisionComptesMensuelPage?> loadComptesMensuel(String societe) async {
    return await loadData<NavisionComptesMensuelPage>(
      societe,
      'navision_comptes_mensuel',
      (json) => NavisionComptesMensuelPage.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateComptesMensuel(String societe) async {
    return await getLastUpdate(societe, 'navision_comptes_mensuel');
  }

  // --- Sous-indicateurs mensuels ---
  Future<void> saveSousIndicateursMensuel(String societe, NavisionSousIndicateursMensuelResponse data) async {
    await saveData<NavisionSousIndicateursMensuelResponse>(
      societe,
      'navision_sous_indicateurs_mensuel',
      data,
      () => {
        'annee': data.annee,
        'mois': data.mois.map((mois, indicateursMap) => MapEntry(
          mois,
          indicateursMap.map((indicateur, list) => MapEntry(
            indicateur,
            list.map((sousInd) => {
              'sousIndicateur': sousInd.sousIndicateur,
              'libelle': sousInd.libelle,
              'initiales': sousInd.initiales,
              'formule': sousInd.formule,
              'montant': sousInd.montant,
            }).toList(),
          )),
        )),
      },
    );
  }

  Future<NavisionSousIndicateursMensuelResponse?> loadSousIndicateursMensuel(String societe) async {
    return await loadData<NavisionSousIndicateursMensuelResponse>(
      societe,
      'navision_sous_indicateurs_mensuel',
      (json) => NavisionSousIndicateursMensuelResponse.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateSousIndicateursMensuel(String societe) async {
    return await getLastUpdate(societe, 'navision_sous_indicateurs_mensuel');
  }

  // --- Global mensuel ---
  // Si tu as un modèle global mensuel, ajoute-le ici

  // --- Extension future pour Odoo ---
  // Tu pourras créer OdooServiceCache sur le même modèle

  // --- Méthode pour vider le cache Navision ---
  Future<void> clearNavisionCache() async {
    var box = await Hive.openBox(navisionBox);
    await box.clear();
  }
}