import 'package:http/http.dart' as http;
import 'package:mobaitec_decision_making/services/indicateur/navision_service_sig.dart';
import 'package:mobaitec_decision_making/services/cache/navision_service_cache.dart';
import 'package:mobaitec_decision_making/services/cache/odoo_service_cache.dart';

class DiagnosticUtils {
  static Future<Map<String, dynamic>> runDiagnostic(String societe) async {
    final results = <String, dynamic>{};

    try {
      // Test 1: Connexion au backend
      print('[DIAGNOSTIC] Test 1: Connexion au backend...');
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/'));
      results['backend_accessible'] = response.statusCode == 200;
      results['backend_status'] = response.statusCode;
      print('[DIAGNOSTIC] Backend accessible: ${response.statusCode}');

      // Test 2: Récupération des données Navision
      print('[DIAGNOSTIC] Test 2: Récupération des données Navision...');
      try {
        final navisionService = NavisionSIGService();
        final indicateurs = await navisionService.fetchIndicateursGlobal(
          societe: societe,
          periode: 'annee',
        );
        results['navision_data_loaded'] = true;
        results['navision_years_count'] = indicateurs.indicateurs.length;
        print(
            '[DIAGNOSTIC] Données Navision récupérées: ${indicateurs.indicateurs.length} années');
      } catch (e) {
        results['navision_data_loaded'] = false;
        results['navision_error'] = e.toString();
        print('[DIAGNOSTIC] Erreur Navision: $e');
      }

      // Test 3: Cache Navision
      print('[DIAGNOSTIC] Test 3: Cache Navision...');
      try {
        final navisionCache = NavisionServiceCache();
        final cachedData = await navisionCache.loadIndicateursMensuel(societe);
        results['navision_cache_has_data'] = cachedData != null;
        print(
            '[DIAGNOSTIC] Cache Navision: ${cachedData != null ? 'A des données' : 'Vide'}');
      } catch (e) {
        results['navision_cache_has_data'] = false;
        results['navision_cache_error'] = e.toString();
        print('[DIAGNOSTIC] Erreur cache Navision: $e');
      }

      // Test 4: Cache Odoo
      print('[DIAGNOSTIC] Test 4: Cache Odoo...');
      try {
        final odooCache = OdooServiceCache();
        final cachedData = await odooCache.loadIndicateursMensuel(societe);
        results['odoo_cache_has_data'] = cachedData != null;
        print(
            '[DIAGNOSTIC] Cache Odoo: ${cachedData != null ? 'A des données' : 'Vide'}');
      } catch (e) {
        results['odoo_cache_has_data'] = false;
        results['odoo_cache_error'] = e.toString();
        print('[DIAGNOSTIC] Erreur cache Odoo: $e');
      }
    } catch (e) {
      results['general_error'] = e.toString();
      print('[DIAGNOSTIC] Erreur générale: $e');
    }

    return results;
  }

  static Future<void> clearAllCaches() async {
    try {
      final navisionCache = NavisionServiceCache();
      final odooCache = OdooServiceCache();

      await navisionCache.clearNavisionCache();
      await odooCache.clearOdooCache();

      print('[DIAGNOSTIC] Tous les caches ont été vidés');
    } catch (e) {
      print('[DIAGNOSTIC] Erreur lors du vidage des caches: $e');
      rethrow;
    }
  }

  static String formatDiagnosticResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNOSTIC RÉSULTATS ===');

    if (results['backend_accessible'] == true) {
      buffer.writeln(
          '✅ Backend accessible (Status: ${results['backend_status']})');
    } else {
      buffer.writeln(
          '❌ Backend inaccessible (Status: ${results['backend_status']})');
    }

    if (results['navision_data_loaded'] == true) {
      buffer.writeln(
          '✅ Données Navision récupérées (${results['navision_years_count']} années)');
    } else {
      buffer.writeln(
          '❌ Erreur récupération Navision: ${results['navision_error']}');
    }

    if (results['navision_cache_has_data'] == true) {
      buffer.writeln('✅ Cache Navision contient des données');
    } else {
      buffer.writeln(
          '⚠️ Cache Navision vide ou erreur: ${results['navision_cache_error'] ?? 'Pas de données'}');
    }

    if (results['odoo_cache_has_data'] == true) {
      buffer.writeln('✅ Cache Odoo contient des données');
    } else {
      buffer.writeln(
          '⚠️ Cache Odoo vide ou erreur: ${results['odoo_cache_error'] ?? 'Pas de données'}');
    }

    if (results['general_error'] != null) {
      buffer.writeln('❌ Erreur générale: ${results['general_error']}');
    }

    return buffer.toString();
  }
}
