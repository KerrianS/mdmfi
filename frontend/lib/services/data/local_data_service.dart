import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mobaitec_decision_making/models/SIGModel.dart';

/// Service pour charger les données depuis les fichiers JSON locaux
class LocalDataService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static List<String> _availableSocietes = [];

  /// Initialise le service et charge toutes les données au démarrage
  static Future<void> initialize() async {
    print('🚀 Initialisation du service de données locales...');

    // Découvrir les sociétés disponibles
    _availableSocietes = await _discoverSocietes();
    print('📁 Sociétés découvertes: $_availableSocietes');

    // Charger toutes les données pour chaque société
    for (String societe in _availableSocietes) {
      await _loadAllDataForSociete(societe);
    }

    print(
        '✅ Service de données locales initialisé avec ${_cache.length} sociétés');
  }

  /// Découvre les sociétés disponibles dans le dossier data
  static Future<List<String>> _discoverSocietes() async {
    try {
      // Pour l'instant, retourner les sociétés connues
      // TODO: Implémenter la découverte automatique depuis AssetManifest.json
      return ['rsp-bgs', 'rsp-neg', 'rsp-sb'];
    } catch (e) {
      print('❌ Erreur lors de la découverte des sociétés: $e');
      return [];
    }
  }

  /// Charge toutes les données pour une société donnée
  static Future<void> _loadAllDataForSociete(String societe) async {
    try {
      final societeData = <String, dynamic>{};

      // Charger les différents types de données
      final dataTypes = [
        'comptes_global_annee',
        'comptes_mensuel_2020',
        'comptes_mensuel_2021',
        'comptes_mensuel_2022',
        'indicateurs_global_annee',
        'indicateurs_mensuel_2020',
        'indicateurs_mensuel_2021',
        'indicateurs_mensuel_2022',
        'sous_indicateurs_global_annee',
        'sous_indicateurs_mensuel_2020',
        'sous_indicateurs_mensuel_2021',
        'sous_indicateurs_mensuel_2022',
      ];

      for (String dataType in dataTypes) {
        try {
          final data = await _loadJsonFile('lib/data/$societe/$dataType.json');
          if (data != null) {
            societeData[dataType] = data;
          }
        } catch (e) {
          // Fichier non trouvé, c'est normal pour certaines années
          print('⚠️ Fichier non trouvé: lib/data/$societe/$dataType.json');
        }
      }

      _cache[societe] = societeData;
      print(
          '✅ Données chargées pour $societe: ${societeData.keys.length} types');
    } catch (e) {
      print('❌ Erreur lors du chargement des données pour $societe: $e');
    }
  }

  /// Charge un fichier JSON depuis le système de fichiers
  static Future<Map<String, dynamic>?> _loadJsonFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return json.decode(jsonString) as Map<String, dynamic>;
      } else {
        print('⚠️ Fichier non trouvé: $path');
        return null;
      }
    } catch (e) {
      print('⚠️ Erreur lors de la lecture du fichier: $path - $e');
      return null;
    }
  }

  /// Obtient la liste des sociétés disponibles
  static List<String> getAvailableSocietes() {
    return List.from(_availableSocietes);
  }

  /// Vérifie si une société est disponible
  static bool isSocieteAvailable(String societe) {
    return _availableSocietes.contains(societe);
  }

  /// Obtient les données comptes globales pour une société
  static Map<String, dynamic>? getComptesGlobalAnnee(String societe) {
    return _cache[societe]?['comptes_global_annee'];
  }

  /// Obtient les données comptes mensuelles pour une société et une année
  static Map<String, dynamic>? getComptesMensuel(String societe, int annee) {
    return _cache[societe]?['comptes_mensuel_$annee'];
  }

  /// Obtient les données indicateurs globales pour une société
  static Map<String, dynamic>? getIndicateursGlobalAnnee(String societe) {
    return _cache[societe]?['indicateurs_global_annee'];
  }

  /// Obtient les données indicateurs mensuelles pour une société et une année
  static Map<String, dynamic>? getIndicateursMensuel(
      String societe, int annee) {
    return _cache[societe]?['indicateurs_mensuel_$annee'];
  }

  /// Obtient les données sous-indicateurs globales pour une société
  static Map<String, dynamic>? getSousIndicateursGlobalAnnee(String societe) {
    return _cache[societe]?['sous_indicateurs_global_annee'];
  }

  /// Obtient les données sous-indicateurs mensuelles pour une société et une année
  static Map<String, dynamic>? getSousIndicateursMensuel(
      String societe, int annee) {
    return _cache[societe]?['sous_indicateurs_mensuel_$annee'];
  }

  /// Convertit les données JSON en modèle SIGComptesMensuelPage
  static SIGComptesMensuelPage? convertToComptesMensuelPage(
    Map<String, dynamic>? jsonData,
    String societe,
    int annee,
    int mois,
    String sousIndicateur,
  ) {
    if (jsonData == null) return null;

    try {
      // Adapter la structure JSON au format attendu par le modèle
      final comptesData = jsonData['mois']?[mois.toString()]?[sousIndicateur];
      if (comptesData == null) {
        print(
            '⚠️ Données non trouvées pour $societe, année $annee, mois $mois, sous-indicateur $sousIndicateur');
        return null;
      }

      // Convertir les comptes pour correspondre au modèle
      final List<Map<String, dynamic>> adaptedComptes = [];
      final comptesList = comptesData['comptes'] as List<dynamic>? ?? [];

      for (final compte in comptesList) {
        final compteMap = compte as Map<String, dynamic>;
        adaptedComptes.add({
          'code_compte': compteMap['code_compte'] ?? '',
          'libelle_compte': compteMap['libelle_compte'] ?? '',
          'montant': (compteMap['montant'] as num?)?.toDouble() ?? 0.0,
          'debit': (compteMap['debit'] as num?)?.toDouble() ?? 0.0,
          'credit': (compteMap['credit'] as num?)?.toDouble() ?? 0.0,
          'date_ecriture': DateTime(annee, mois, 1).toIso8601String(),
          'document': compteMap['document'] ?? '',
          'utilisateur': compteMap['utilisateur'] ?? '',
        });
      }

      final adaptedData = {
        'societe': societe,
        'annee': annee,
        'mois': mois,
        'sous_indicateur': sousIndicateur,
        'total': comptesData['total'] ?? 0,
        'limit': comptesData['limit'] ?? 50,
        'offset': comptesData['offset'] ?? 0,
        'comptes': adaptedComptes,
      };

      return SIGComptesMensuelPage.fromJson(adaptedData);
    } catch (e) {
      print('❌ Erreur lors de la conversion des données comptes: $e');
      return null;
    }
  }

  /// Convertit les données JSON en modèle SIGIndicateursMensuelResponse
  static SIGIndicateursMensuelResponse? convertToIndicateursMensuelResponse(
    Map<String, dynamic>? jsonData,
    String societe,
    int annee,
  ) {
    if (jsonData == null) return null;

    try {
      // Adapter la structure JSON au format attendu par le modèle
      final adaptedData = {
        'societe': societe,
        'annee': annee,
        'mois': jsonData['mois'] ?? {},
      };

      print(
          '🔍 Conversion des données indicateurs pour $societe, année $annee');
      print('🔍 Données JSON: ${jsonData.keys}');
      print(
          '🔍 Mois disponibles: ${(jsonData['mois'] as Map<String, dynamic>?)?.keys}');

      return SIGIndicateursMensuelResponse.fromJson(adaptedData);
    } catch (e) {
      print('❌ Erreur lors de la conversion des données indicateurs: $e');
      return null;
    }
  }

  /// Convertit les données JSON en modèle SIGSousIndicateursMensuelResponse
  static SIGSousIndicateursMensuelResponse?
      convertToSousIndicateursMensuelResponse(
    Map<String, dynamic>? jsonData,
    String societe,
    int annee,
  ) {
    if (jsonData == null) return null;

    try {
      // Adapter la structure JSON au format attendu par le modèle
      final adaptedData = {
        'societe': societe,
        'annee': annee,
        'mois': jsonData['mois'] ?? {},
      };

      print(
          '🔍 Conversion des données sous-indicateurs pour $societe, année $annee');
      print('🔍 Données JSON: ${jsonData.keys}');
      print(
          '🔍 Mois disponibles: ${(jsonData['mois'] as Map<String, dynamic>?)?.keys}');

      return SIGSousIndicateursMensuelResponse.fromJson(adaptedData);
    } catch (e) {
      print('❌ Erreur lors de la conversion des données sous-indicateurs: $e');
      return null;
    }
  }

  /// Obtient les statistiques des données chargées
  static Map<String, dynamic> getDataStats() {
    final stats = <String, dynamic>{
      'societes_disponibles': _availableSocietes.length,
      'societes': _availableSocietes,
      'donnees_chargees': _cache.length,
      'details_par_societe': {},
    };

    for (String societe in _availableSocietes) {
      final societeData = _cache[societe];
      stats['details_par_societe'][societe] = {
        'types_de_donnees': societeData?.keys.length ?? 0,
        'types_disponibles': societeData?.keys.toList() ?? [],
      };
    }

    return stats;
  }

  /// Obtient les informations de cache pour l'écran settings
  static Future<Map<String, dynamic>> getCacheInfo() async {
    final stats = getDataStats();
    return {
      'has_navision_data': stats['donnees_chargees'] > 0,
      'has_odoo_data': stats['donnees_chargees'] > 0,
      'navision_indicateurs_last_update': DateTime.now().toIso8601String(),
      'odoo_indicateurs_last_update': DateTime.now().toIso8601String(),
      'societes_disponibles': stats['societes_disponibles'],
      'donnees_chargees': stats['donnees_chargees'],
    };
  }
}
