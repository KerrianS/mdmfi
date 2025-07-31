import 'package:mobaitec_decision_making/services/data/local_data_service.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';

/// Service pour synchroniser les sociétés Keycloak avec les données locales
class SocieteSyncService {
  static final Map<String, String> _keycloakToLocalMapping = {
    'rsp-bgs': 'rsp-bgs',
    'rsp-neg': 'rsp-neg',
    'rsp-sb': 'rsp-sb',
    'aitecservice': 'aitecservice', // Mapping aitecservice vers rsp-neg
    // Ajoutez d'autres mappings selon vos besoins
  };

  /// Obtient la société locale correspondante à une société Keycloak
  static String? getLocalSocieteFromKeycloak(String? keycloakSociete) {
    if (keycloakSociete == null) return null;

    // Essayer d'abord le mapping direct
    final mappedSociete = _keycloakToLocalMapping[keycloakSociete];
    if (mappedSociete != null &&
        LocalDataService.isSocieteAvailable(mappedSociete)) {
      return mappedSociete;
    }

    // Fallback : essayer avec le nom en minuscules
    final fallbackSociete = keycloakSociete.toLowerCase();
    if (LocalDataService.isSocieteAvailable(fallbackSociete)) {
      return fallbackSociete;
    }

    return null;
  }

  /// Obtient toutes les sociétés locales disponibles
  static List<String> getAvailableLocalSocietes() {
    return LocalDataService.getAvailableSocietes();
  }

  /// Vérifie si une société Keycloak a des données locales correspondantes
  static bool hasLocalDataForKeycloakSociete(String? keycloakSociete) {
    final localSociete = getLocalSocieteFromKeycloak(keycloakSociete);
    return localSociete != null;
  }

  /// Obtient les statistiques des données pour une société Keycloak
  static Map<String, dynamic>? getDataStatsForKeycloakSociete(
      String? keycloakSociete) {
    final localSociete = getLocalSocieteFromKeycloak(keycloakSociete);
    if (localSociete == null) return null;

    final allStats = LocalDataService.getDataStats();
    final details = allStats['details_par_societe']?[localSociete];

    return {
      'keycloak_societe': keycloakSociete,
      'local_societe': localSociete,
      'has_data': details != null,
      'data_types': details?['types_disponibles'] ?? [],
      'data_count': details?['types_de_donnees'] ?? 0,
    };
  }

  /// Obtient le mapping complet Keycloak -> Local
  static Map<String, String> getKeycloakToLocalMapping() {
    return Map.from(_keycloakToLocalMapping);
  }

  /// Ajoute un nouveau mapping
  static void addMapping(String keycloakSociete, String localSociete) {
    _keycloakToLocalMapping[keycloakSociete] = localSociete;
  }
}
