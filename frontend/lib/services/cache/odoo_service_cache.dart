
import 'package:hive/hive.dart';
import 'package:mobaitec_decision_making/models/OdooSIGModel.dart';

class OdooServiceCache {
  static const String odooBox = 'odoo_cache';

  // --- Save generic Odoo data ---
  Future<void> saveData<T>(String societe, String type, T data, Map<String, dynamic> Function() toJson) async {
    var box = await Hive.openBox(odooBox);
    box.put('[32m${type}_$societe[0m', toJson());
    box.put('[32m${type}_${societe}_last_update[0m', DateTime.now().toIso8601String());
  }

  // --- Load generic Odoo data ---
  Future<T?> loadData<T>(String societe, String type, T Function(Map<String, dynamic>) fromJson) async {
    var box = await Hive.openBox(odooBox);
    final json = box.get('[32m${type}_$societe[0m');
    if (json != null) {
      return fromJson(Map<String, dynamic>.from(json));
    }
    return null;
  }

  // --- Get last update for a type ---
  Future<DateTime?> getLastUpdate(String societe, String type) async {
    var box = await Hive.openBox(odooBox);
    final dateStr = box.get('[32m${type}_${societe}_last_update[0m');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // --- Specific helpers for each Odoo type ---
  Future<void> saveIndicateursMensuel(String societe, OdooIndicateursMensuelResponse data) async {
    await saveData<OdooIndicateursMensuelResponse>(
      societe,
      'odoo_indicateurs_mensuel',
      data,
      () => data.toJson(),
    );
  }

  Future<OdooIndicateursMensuelResponse?> loadIndicateursMensuel(String societe) async {
    return await loadData<OdooIndicateursMensuelResponse>(
      societe,
      'odoo_indicateurs_mensuel',
      (json) => OdooIndicateursMensuelResponse.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateIndicateursMensuel(String societe) async {
    return await getLastUpdate(societe, 'odoo_indicateurs_mensuel');
  }

  // --- Comptes mensuels paginés ---
  Future<void> saveComptesMensuel(String societe, OdooComptesMensuelPage data) async {
    await saveData<OdooComptesMensuelPage>(
      societe,
      'odoo_comptes_mensuel',
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

  Future<OdooComptesMensuelPage?> loadComptesMensuel(String societe) async {
    return await loadData<OdooComptesMensuelPage>(
      societe,
      'odoo_comptes_mensuel',
      (json) => OdooComptesMensuelPage.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateComptesMensuel(String societe) async {
    return await getLastUpdate(societe, 'odoo_comptes_mensuel');
  }

  // --- Sous-indicateurs mensuels ---
  Future<void> saveSousIndicateursMensuel(String societe, OdooSousIndicateursMensuelResponse data) async {
    await saveData<OdooSousIndicateursMensuelResponse>(
      societe,
      'odoo_sous_indicateurs_mensuel',
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

  Future<OdooSousIndicateursMensuelResponse?> loadSousIndicateursMensuel(String societe) async {
    return await loadData<OdooSousIndicateursMensuelResponse>(
      societe,
      'odoo_sous_indicateurs_mensuel',
      (json) => OdooSousIndicateursMensuelResponse.fromJson(json),
    );
  }

  Future<DateTime?> getLastUpdateSousIndicateursMensuel(String societe) async {
    return await getLastUpdate(societe, 'odoo_sous_indicateurs_mensuel');
  }

  // --- Méthode pour vider le cache Odoo ---
  Future<void> clearOdooCache() async {
    var box = await Hive.openBox(odooBox);
    await box.clear();
  }
}
