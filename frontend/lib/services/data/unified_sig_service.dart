import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:mobaitec_decision_making/services/data/local_data_service.dart';
import 'package:mobaitec_decision_making/services/data/societe_sync_service.dart';

/// Service unifié pour adapter les données locales aux modèles attendus par les écrans
class UnifiedSIGService {
  // ===== COMPTES MENSUELS =====

  /// Comptes mensuels - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchComptesMensuel({
    required String societe,
    required int annee,
    required int mois,
    required String sousIndicateur,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des comptes mensuels depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    final jsonData = LocalDataService.getComptesMensuel(selectedSociete, annee);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete et l\'année $annee');
    }

    final result = LocalDataService.convertToComptesMensuelPage(
      jsonData,
      selectedSociete,
      annee,
      mois,
      sousIndicateur,
    );

    if (result == null) {
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }

    // Convertir en format attendu par les écrans
    final List<Map<String, dynamic>> convertedComptes = result.comptes
        .map((compte) => {
              'codeCompte': compte.codeCompte,
              'libelleCompte': compte.libelleCompte,
              'montant': compte.montant,
              'debit': compte.debit,
              'credit': compte.credit,
              'dateEcriture': compte.dateEcriture,
              'document': compte.document,
              'utilisateur': compte.utilisateur,
            })
        .toList();

    return {
      'comptes': convertedComptes,
      'total': result.total,
      'limit': result.limit,
      'offset': result.offset,
    };
  }

  // ===== INDICATEURS MENSUELS =====

  /// Indicateurs mensuels - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchIndicateursMensuel({
    required String societe,
    required int annee,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des indicateurs mensuels depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    final jsonData =
        LocalDataService.getIndicateursMensuel(selectedSociete, annee);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete et l\'année $annee');
    }

    final result = LocalDataService.convertToIndicateursMensuelResponse(
      jsonData,
      selectedSociete,
      annee,
    );

    if (result == null) {
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }

    // Convertir en format attendu par les écrans
    final Map<String, List<Map<String, dynamic>>> convertedIndicateurs = {};
    for (final entry in result.mois.entries) {
      final mois = entry.key;
      final indicateurs = entry.value;
      convertedIndicateurs[mois] = indicateurs
          .map((ind) => {
                'indicateur': ind.indicateur,
                'libelle': ind.libelle,
                'valeur': ind.valeur,
                'formuleText': ind.formuleText,
              })
          .toList();
    }

    return {
      'mois': convertedIndicateurs,
    };
  }

  // ===== SOUS-INDICATEURS MENSUELS =====

  /// Sous-indicateurs mensuels - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchSousIndicateursMensuel({
    required String societe,
    required int annee,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des sous-indicateurs mensuels depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    final jsonData =
        LocalDataService.getSousIndicateursMensuel(selectedSociete, annee);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete et l\'année $annee');
    }

    final result = LocalDataService.convertToSousIndicateursMensuelResponse(
      jsonData,
      selectedSociete,
      annee,
    );

    if (result == null) {
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }

    // Convertir en format attendu par les écrans
    final Map<String, Map<String, List<Map<String, dynamic>>>>
        convertedSousIndicateurs = {};
    for (final entry in result.mois.entries) {
      final mois = entry.key;
      final indicateurs = entry.value;
      convertedSousIndicateurs[mois] = {};
      for (final indEntry in indicateurs.entries) {
        final indicateur = indEntry.key;
        final sousIndicateurs = indEntry.value;
        convertedSousIndicateurs[mois]![indicateur] = sousIndicateurs
            .map((sous) => {
                  'sousIndicateur': sous.sousIndicateur,
                  'libelle': sous.libelle,
                  'montant': sous.montant,
                })
            .toList();
      }
    }

    return {
      'mois': convertedSousIndicateurs,
    };
  }

  // ===== INDICATEURS GLOBAUX =====

  /// Indicateurs globaux - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des indicateurs globaux depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    // Si on demande des données trimestrielles, calculer à partir des données mensuelles
    if (periode == 'trimestre' && trimestre != null) {
      return _calculateTrimestreData(selectedSociete, trimestre);
    }

    final jsonData =
        LocalDataService.getIndicateursGlobalAnnee(selectedSociete);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete');
    }

    try {
      final result = SIGIndicateursGlobalResponse.fromJson(jsonData);
      print(
          '[UnifiedSIGService] Indicateurs globaux chargés depuis les fichiers locaux pour $selectedSociete');

      // Convertir en format attendu par les écrans
      final Map<String, List<Map<String, dynamic>>> convertedIndicateurs = {};
      for (final entry in result.indicateurs.entries) {
        final annee = entry.key;
        final indicateurs = entry.value;
        convertedIndicateurs[annee] = indicateurs
            .map((ind) => {
                  'indicateur': ind.indicateur,
                  'libelle': ind.libelle,
                  'valeur': ind.valeur,
                  'formuleText': ind.formuleText,
                })
            .toList();
      }

      return {
        'indicateurs': convertedIndicateurs,
      };
    } catch (e) {
      print(
          '❌ Erreur lors de la conversion des données indicateurs globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== SOUS-INDICATEURS GLOBAUX =====

  /// Sous-indicateurs globaux - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchSousIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des sous-indicateurs globaux depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    // Si on demande des données trimestrielles, calculer à partir des données mensuelles
    if (periode == 'trimestre' && trimestre != null) {
      return _calculateTrimestreSousIndicateursData(selectedSociete, trimestre);
    }

    final jsonData =
        LocalDataService.getSousIndicateursGlobalAnnee(selectedSociete);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete');
    }

    try {
      final result = SIGSousIndicateursGlobalResponse.fromJson(jsonData);
      print(
          '[UnifiedSIGService] Sous-indicateurs globaux chargés depuis les fichiers locaux pour $selectedSociete');

      // Convertir en format attendu par les écrans
      final Map<String, Map<String, List<Map<String, dynamic>>>>
          convertedSousIndicateurs = {};
      for (final entry in result.sousIndicateurs.entries) {
        final annee = entry.key;
        final indicateurs = entry.value;
        convertedSousIndicateurs[annee] = {};
        for (final indEntry in indicateurs.entries) {
          final indicateur = indEntry.key;
          final sousIndicateurs = indEntry.value;
          convertedSousIndicateurs[annee]![indicateur] = sousIndicateurs
              .map((sous) => {
                    'sousIndicateur': sous.sousIndicateur,
                    'libelle': sous.libelle,
                    'montant': sous.montant,
                  })
              .toList();
        }
      }

      return {
        'sousIndicateurs': convertedSousIndicateurs,
      };
    } catch (e) {
      print(
          '❌ Erreur lors de la conversion des données sous-indicateurs globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== COMPTES GLOBAUX =====

  /// Comptes globaux - adapté pour les écrans
  static Future<Map<String, dynamic>> fetchComptesGlobal({
    required String societe,
    required String sousIndicateur,
    required String periode,
    int? trimestre,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    print(
        '[UnifiedSIGService] Chargement des comptes globaux depuis les données locales');

    final selectedSociete =
        SocieteSyncService.getLocalSocieteFromKeycloak(societe);
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    // Si on demande des données trimestrielles, calculer à partir des données mensuelles
    if (periode == 'trimestre' && trimestre != null) {
      return _calculateTrimestreComptesData(
          selectedSociete, trimestre, sousIndicateur);
    }

    final jsonData = LocalDataService.getComptesGlobalAnnee(selectedSociete);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete');
    }

    try {
      // Traiter directement le JSON car la structure est différente
      final Map<String, Map<String, dynamic>> convertedComptes = {};
      final comptesData = jsonData['comptes'] as Map<String, dynamic>?;

      if (comptesData != null) {
        for (final entry in comptesData.entries) {
          final annee = entry.key;
          final anneeData = entry.value as Map<String, dynamic>;

          // Pour chaque sous-indicateur dans l'année
          final List<Map<String, dynamic>> allComptes = [];
          int totalComptes = 0;

          for (final sousIndicateurEntry in anneeData.entries) {
            final sousIndicateurKey = sousIndicateurEntry.key;
            final sousIndicateurData =
                sousIndicateurEntry.value as Map<String, dynamic>;

            // Filtrer par sous-indicateur demandé
            if (sousIndicateurKey == sousIndicateur) {
              final comptesList =
                  sousIndicateurData['comptes'] as List<dynamic>?;
              if (comptesList != null) {
                for (final compte in comptesList) {
                  final compteMap = compte as Map<String, dynamic>;
                  allComptes.add({
                    'codeCompte': compteMap['code_compte']?.toString() ?? '',
                    'libelleCompte':
                        compteMap['libelle_compte']?.toString() ?? '',
                    'montant':
                        (compteMap['montant'] as num?)?.toDouble() ?? 0.0,
                    'debit': (compteMap['debit'] as num?)?.toDouble() ?? 0.0,
                    'credit': (compteMap['credit'] as num?)?.toDouble() ?? 0.0,
                  });
                }
                totalComptes += (sousIndicateurData['total'] as int?) ?? 0;
              }
            }
          }

          convertedComptes[annee] = {
            'comptes': allComptes,
            'total': totalComptes,
          };
        }
      }

      print(
          '[UnifiedSIGService] Comptes globaux chargés depuis les fichiers locaux pour $selectedSociete');

      // Vérifier si des comptes ont été trouvés
      bool hasComptes = false;
      for (final anneeEntry in convertedComptes.entries) {
        final comptes = anneeEntry.value['comptes'] as List<dynamic>;
        if (comptes.isNotEmpty) {
          hasComptes = true;
          break;
        }
      }

      return {
        'comptes': convertedComptes,
        'total': convertedComptes.length,
        'limit': limit,
        'offset': offset,
        'hasComptes': hasComptes,
      };
    } catch (e) {
      print('❌ Erreur lors de la conversion des données comptes globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== CALCUL DES DONNÉES TRIMESTRIELLES =====

  /// Calcule les données trimestrielles à partir des données mensuelles
  static Future<Map<String, dynamic>> _calculateTrimestreData(
      String societe, int trimestre) async {
    print(
        '[UnifiedSIGService] Calcul des données trimestrielles T$trimestre pour $societe');

    // Définir les mois pour chaque trimestre
    final Map<int, List<int>> trimestreMois = {
      1: [1, 2, 3],
      2: [4, 5, 6],
      3: [7, 8, 9],
      4: [10, 11, 12],
    };

    final moisDuTrimestre = trimestreMois[trimestre];
    if (moisDuTrimestre == null) {
      throw Exception('Trimestre invalide: $trimestre');
    }

    // Charger les données mensuelles pour toutes les années disponibles
    final annees = ['2020', '2021', '2022'];
    final Map<String, List<Map<String, dynamic>>> resultat = {};

    for (final annee in annees) {
      try {
        final jsonData =
            LocalDataService.getIndicateursMensuel(societe, int.parse(annee));
        if (jsonData == null) continue;

        final result = LocalDataService.convertToIndicateursMensuelResponse(
          jsonData,
          societe,
          int.parse(annee),
        );

        if (result == null) continue;

        // Calculer les totaux trimestriels pour cette année
        final Map<String, double> totauxIndicateurs = {};
        final Map<String, String> libellesIndicateurs = {};

        for (final mois in moisDuTrimestre) {
          final moisStr = mois.toString();
          final indicateursMois = result.mois[moisStr];
          if (indicateursMois != null) {
            for (final ind in indicateursMois) {
              totauxIndicateurs[ind.indicateur] =
                  (totauxIndicateurs[ind.indicateur] ?? 0) + ind.valeur;
              libellesIndicateurs[ind.indicateur] = ind.libelle;
            }
          }
        }

        // Convertir en format attendu
        final List<Map<String, dynamic>> indicateursTrimestre =
            totauxIndicateurs.entries
                .map((entry) => {
                      'indicateur': entry.key,
                      'libelle': libellesIndicateurs[entry.key] ?? entry.key,
                      'valeur': entry.value,
                      'formuleText':
                          'Somme des mois ${moisDuTrimestre.join(', ')}',
                    })
                .toList();

        if (indicateursTrimestre.isNotEmpty) {
          resultat[annee] = indicateursTrimestre;
        }
      } catch (e) {
        print(
            '⚠️ Erreur lors du calcul des données trimestrielles pour $annee: $e');
      }
    }

    return {
      'indicateurs': resultat,
    };
  }

  /// Calcule les sous-indicateurs trimestriels à partir des données mensuelles
  static Future<Map<String, dynamic>> _calculateTrimestreSousIndicateursData(
      String societe, int trimestre) async {
    print(
        '[UnifiedSIGService] Calcul des sous-indicateurs trimestriels T$trimestre pour $societe');

    // Définir les mois pour chaque trimestre
    final Map<int, List<int>> trimestreMois = {
      1: [1, 2, 3],
      2: [4, 5, 6],
      3: [7, 8, 9],
      4: [10, 11, 12],
    };

    final moisDuTrimestre = trimestreMois[trimestre];
    if (moisDuTrimestre == null) {
      throw Exception('Trimestre invalide: $trimestre');
    }

    // Charger les données mensuelles pour toutes les années disponibles
    final annees = ['2020', '2021', '2022'];
    final Map<String, Map<String, List<Map<String, dynamic>>>> resultat = {};

    for (final annee in annees) {
      try {
        final jsonData = LocalDataService.getSousIndicateursMensuel(
            societe, int.parse(annee));
        if (jsonData == null) continue;

        final result = LocalDataService.convertToSousIndicateursMensuelResponse(
          jsonData,
          societe,
          int.parse(annee),
        );

        if (result == null) continue;

        // Calculer les totaux trimestriels pour cette année
        final Map<String, Map<String, double>> totauxSousIndicateurs = {};
        final Map<String, Map<String, String>> libellesSousIndicateurs = {};

        for (final mois in moisDuTrimestre) {
          final moisStr = mois.toString();
          final indicateursMois = result.mois[moisStr];
          if (indicateursMois != null) {
            for (final indEntry in indicateursMois.entries) {
              final indicateur = indEntry.key;
              final sousIndicateurs = indEntry.value;

              totauxSousIndicateurs.putIfAbsent(indicateur, () => {});
              libellesSousIndicateurs.putIfAbsent(indicateur, () => {});

              for (final sous in sousIndicateurs) {
                totauxSousIndicateurs[indicateur]![sous.sousIndicateur] =
                    (totauxSousIndicateurs[indicateur]![sous.sousIndicateur] ??
                            0) +
                        sous.montant;
                libellesSousIndicateurs[indicateur]![sous.sousIndicateur] =
                    sous.libelle;
              }
            }
          }
        }

        // Convertir en format attendu
        final Map<String, List<Map<String, dynamic>>> sousIndicateursTrimestre =
            {};
        for (final indEntry in totauxSousIndicateurs.entries) {
          final indicateur = indEntry.key;
          final sousIndicateurs = indEntry.value;

          sousIndicateursTrimestre[indicateur] = sousIndicateurs.entries
              .map((sousEntry) => {
                    'sousIndicateur': sousEntry.key,
                    'libelle':
                        libellesSousIndicateurs[indicateur]![sousEntry.key] ??
                            sousEntry.key,
                    'montant': sousEntry.value,
                  })
              .toList();
        }

        if (sousIndicateursTrimestre.isNotEmpty) {
          resultat[annee] = sousIndicateursTrimestre;
        }
      } catch (e) {
        print(
            '⚠️ Erreur lors du calcul des sous-indicateurs trimestriels pour $annee: $e');
      }
    }

    return {
      'sousIndicateurs': resultat,
    };
  }

  /// Calcule les données trimestrielles des comptes à partir des données mensuelles
  static Future<Map<String, dynamic>> _calculateTrimestreComptesData(
      String societe, int trimestre, String sousIndicateur) async {
    print(
        '[UnifiedSIGService] Calcul des données trimestrielles des comptes T$trimestre pour $societe');

    // Définir les mois pour chaque trimestre
    final Map<int, List<int>> trimestreMois = {
      1: [1, 2, 3],
      2: [4, 5, 6],
      3: [7, 8, 9],
      4: [10, 11, 12],
    };

    final moisDuTrimestre = trimestreMois[trimestre];
    if (moisDuTrimestre == null) {
      throw Exception('Trimestre invalide: $trimestre');
    }

    // Charger les données mensuelles pour toutes les années disponibles
    final annees = ['2020', '2021', '2022'];
    final Map<String, Map<String, dynamic>> resultat = {};

    for (final annee in annees) {
      try {
        final jsonData =
            LocalDataService.getComptesMensuel(societe, int.parse(annee));
        if (jsonData == null) continue;

        final result = LocalDataService.convertToComptesMensuelPage(
          jsonData,
          societe,
          int.parse(annee),
          moisDuTrimestre.first, // Prendre le premier mois du trimestre
          sousIndicateur,
        );

        if (result == null) continue;

        // Calculer les totaux trimestriels pour cette année
        final Map<String, double> totauxComptes = {};
        final Map<String, String> libellesComptes = {};

        for (final compte in result.comptes) {
          totauxComptes[compte.codeCompte] =
              (totauxComptes[compte.codeCompte] ?? 0) + compte.montant;
          libellesComptes[compte.codeCompte] = compte.libelleCompte;
        }

        // Convertir en format attendu
        final List<Map<String, dynamic>> comptesTrimestre =
            totauxComptes.entries
                .map((entry) => {
                      'codeCompte': entry.key,
                      'libelleCompte': libellesComptes[entry.key] ?? entry.key,
                      'montant': entry.value,
                      'debit': 0.0, // Pas de débit trimestriel
                      'credit': 0.0, // Pas de crédit trimestriel
                    })
                .toList();

        if (comptesTrimestre.isNotEmpty) {
          resultat[annee] = {
            'comptes': comptesTrimestre,
            'total': result.total,
          };
        }
      } catch (e) {
        print(
            '⚠️ Erreur lors du calcul des données trimestrielles des comptes pour $annee: $e');
      }
    }

    return {
      'comptes': resultat,
    };
  }
}
