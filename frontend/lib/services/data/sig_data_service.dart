import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:mobaitec_decision_making/services/data/local_data_service.dart';
import 'package:mobaitec_decision_making/services/data/societe_sync_service.dart';

/// Service unifié pour accéder aux données SIG depuis les fichiers JSON locaux
class SIGDataService {
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

  /// Comptes mensuels
  static Future<SIGComptesMensuelPage> fetchComptesMensuel({
    required String societe,
    required int annee,
    required int mois,
    required String sousIndicateur,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des comptes mensuels depuis les données locales');

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

    print(
        '[SIGDataService] Données chargées depuis les fichiers locaux pour $selectedSociete');
    return result;
  }

  // ===== INDICATEURS MENSUELS =====

  /// Indicateurs mensuels
  static Future<SIGIndicateursMensuelResponse> fetchIndicateursMensuel({
    required String societe,
    required int annee,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des indicateurs mensuels depuis les données locales');

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

    print(
        '[SIGDataService] Indicateurs mensuels chargés depuis les fichiers locaux pour $selectedSociete');
    return result;
  }

  // ===== SOUS-INDICATEURS MENSUELS =====

  /// Sous-indicateurs mensuels
  static Future<SIGSousIndicateursMensuelResponse> fetchSousIndicateursMensuel({
    required String societe,
    required int annee,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des sous-indicateurs mensuels depuis les données locales');

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
          '[SIGDataService] Sous-indicateurs mensuels chargés depuis les fichiers locaux pour $selectedSociete');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la conversion des données sous-indicateurs: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== INDICATEURS GLOBAUX =====

  /// Indicateurs globaux
  static Future<SIGIndicateursGlobalResponse> fetchIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des indicateurs globaux depuis les données locales');

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
          '[SIGDataService] Indicateurs globaux chargés depuis les fichiers locaux pour $selectedSociete');
      return result;
    } catch (e) {
      print(
          '❌ Erreur lors de la conversion des données indicateurs globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== SOUS-INDICATEURS GLOBAUX =====

  /// Sous-indicateurs globaux
  static Future<SIGSousIndicateursGlobalResponse> fetchSousIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des sous-indicateurs globaux depuis les données locales');

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
          '[SIGDataService] Sous-indicateurs globaux chargés depuis les fichiers locaux pour $selectedSociete');
      return result;
    } catch (e) {
      print(
          '❌ Erreur lors de la conversion des données sous-indicateurs globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }

  // ===== COMPTES GLOBAUX =====

  /// Comptes globaux
  static Future<SIGComptesGlobalResponse> fetchComptesGlobal({
    required String societe,
    required String sousIndicateur,
    required String periode,
    int? trimestre,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    print(
        '[SIGDataService] Chargement des comptes globaux depuis les données locales');

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
          '[SIGDataService] Comptes globaux chargés depuis les fichiers locaux pour $selectedSociete');
      return result;
    } catch (e) {
      print('❌ Erreur lors de la conversion des données comptes globaux: $e');
      throw Exception(
          'Erreur lors de la conversion des données pour $selectedSociete');
    }
  }
}
