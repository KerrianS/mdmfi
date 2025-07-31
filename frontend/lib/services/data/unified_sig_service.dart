import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:mobaitec_decision_making/services/data/local_data_service.dart';
import 'package:mobaitec_decision_making/services/data/societe_sync_service.dart';

/// Service unifié pour adapter les données locales aux modèles attendus par les écrans
class UnifiedSIGService {
  /// Obtient la société sélectionnée via Keycloak
  static String? _getSelectedSociete() {
    try {
      // TODO: Récupérer la société sélectionnée depuis KeycloakProvider
      final keycloakSociete = 'RSP-BGS'; // Société par défaut
      return SocieteSyncService.getLocalSocieteFromKeycloak(keycloakSociete);
    } catch (e) {
      print('❌ Erreur lors de la récupération de la société sélectionnée: $e');
      return null;
    }
  }

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

    final selectedSociete = _getSelectedSociete();
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
    return {
      'comptes': result.comptes,
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

    final selectedSociete = _getSelectedSociete();
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
    return {
      'mois': result.mois,
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

    final selectedSociete = _getSelectedSociete();
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    final jsonData =
        LocalDataService.getSousIndicateursMensuel(selectedSociete, annee);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete et l\'année $annee');
    }

    try {
      final result = SIGSousIndicateursMensuelResponse.fromJson(jsonData);
      print(
          '[UnifiedSIGService] Sous-indicateurs mensuels chargés depuis les fichiers locaux pour $selectedSociete');

      // Convertir en format attendu par les écrans
      return {
        'mois': result.mois,
      };
    } catch (e) {
      print('❌ Erreur lors de la conversion des données sous-indicateurs: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
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

    final selectedSociete = _getSelectedSociete();
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
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
      return {
        'indicateurs': result.indicateurs,
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

    final selectedSociete = _getSelectedSociete();
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
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
      return {
        'sousIndicateurs': result.sousIndicateurs,
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

    final selectedSociete = _getSelectedSociete();
    if (selectedSociete == null) {
      throw Exception('Aucune société sélectionnée');
    }

    final jsonData = LocalDataService.getComptesGlobalAnnee(selectedSociete);
    if (jsonData == null) {
      throw Exception(
          'Données non disponibles pour la société $selectedSociete');
    }

    try {
      final result = SIGComptesGlobalResponse.fromJson(jsonData);
      print(
          '[UnifiedSIGService] Comptes globaux chargés depuis les fichiers locaux pour $selectedSociete');

      // Convertir en format attendu par les écrans
      return {
        'comptes': result.comptes,
        'total': result.comptes.length,
        'limit': limit,
        'offset': offset,
      };
    } catch (e) {
      print('❌ Erreur lors de la conversion des données comptes globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }
}
