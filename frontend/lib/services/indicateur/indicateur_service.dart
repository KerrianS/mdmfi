import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/theme/data_mode_provider.dart';
import 'package:mobaitec_decision_making/services/cache/navision_service_cache.dart';
import 'package:mobaitec_decision_making/services/cache/odoo_service_cache.dart';
import 'package:mobaitec_decision_making/services/indicateur/navision_service_sig.dart';
import 'package:mobaitec_decision_making/services/indicateur/odoo_service_sig.dart';
import 'package:hive/hive.dart';

class IndicateurService {
  static Future<dynamic> getIndicateursMensuel(
      BuildContext context, String societe, String annee, String mois) async {
    final dataModeProvider =
        Provider.of<DataModeProvider>(context, listen: false);

    if (dataModeProvider.isCacheMode) {
      // Mode Cache : utiliser les données locales Hive
      print('📦 Mode Cache : Récupération depuis le cache Hive local');
      final navisionCache = NavisionServiceCache();
      final odooCache = OdooServiceCache();

      // Récupérer les données Navision et Odoo depuis le cache
      final navisionData = await navisionCache.loadIndicateursMensuel(societe);
      final odooData = await odooCache.loadIndicateursMensuel(societe);

      // Retourner un objet combiné ou le plus récent
      return {
        'navision': navisionData,
        'odoo': odooData,
        'source': 'cache',
        'last_update_navision':
            await navisionCache.getLastUpdateIndicateursMensuel(societe),
        'last_update_odoo':
            await odooCache.getLastUpdateIndicateursMensuel(societe),
      };
    } else {
      // Mode Webservice : utiliser les données temps réel
      print('🌐 Mode Webservice : Récupération depuis l\'API');
      // TODO: Implémenter les appels API réels
      // final navisionService = NavisionServiceSIG();
      // final odooService = OdooServiceSIG();

      // TODO: Implémenter les appels API réels
      // Pour l'instant, retourner null pour le mode webservice
      return null;
    }
  }

  static Future<dynamic> getIndicateursGlobal(
      BuildContext context, String societe, String annee) async {
    final dataModeProvider =
        Provider.of<DataModeProvider>(context, listen: false);

    if (dataModeProvider.isCacheMode) {
      // Mode Cache : utiliser les données locales Hive
      print('📦 Mode Cache : Récupération depuis le cache Hive local');
      final navisionCache = NavisionServiceCache();
      final odooCache = OdooServiceCache();

      // Récupérer les données Navision et Odoo depuis le cache
      final navisionData = await navisionCache
          .loadIndicateursMensuel(societe); // Fallback sur mensuel
      final odooData = await odooCache.loadIndicateursMensuel(societe);

      return {
        'navision': navisionData,
        'odoo': odooData,
        'source': 'cache',
        'last_update_navision':
            await navisionCache.getLastUpdateIndicateursMensuel(societe),
        'last_update_odoo':
            await odooCache.getLastUpdateIndicateursMensuel(societe),
      };
    } else {
      // Mode Webservice : utiliser les données temps réel
      print('🌐 Mode Webservice : Récupération depuis l\'API');
      // TODO: Implémenter les appels API réels
      return null;
    }
  }

  static String getModeInfo(BuildContext context) {
    final dataModeProvider =
        Provider.of<DataModeProvider>(context, listen: false);
    return dataModeProvider.modeDescription;
  }

  // Méthodes utilitaires pour la gestion du cache
  static Future<void> clearAllCaches() async {
    print('🗑️ Vidage de tous les caches Hive...');
    final navisionCache = NavisionServiceCache();
    final odooCache = OdooServiceCache();

    try {
      // Vider les boxes Hive
      var navisionBox = await Hive.openBox('navision_cache');
      var odooBox = await Hive.openBox('odoo_cache');

      await navisionBox.clear();
      await odooBox.clear();

      print('✅ Caches vidés avec succès');
    } catch (e) {
      print('❌ Erreur lors du vidage des caches: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> getCacheInfo(String societe) async {
    final navisionCache = NavisionServiceCache();
    final odooCache = OdooServiceCache();

    final navisionLastUpdate =
        await navisionCache.getLastUpdateIndicateursMensuel(societe);
    final odooLastUpdate =
        await odooCache.getLastUpdateIndicateursMensuel(societe);

    return {
      'navision_last_update': navisionLastUpdate,
      'odoo_last_update': odooLastUpdate,
      'navision_has_data': navisionLastUpdate != null,
      'odoo_has_data': odooLastUpdate != null,
    };
  }

  static Future<void> forceRefreshCache(
      BuildContext context, String societe, String annee, String mois) async {
    print('🔄 Forçage du rafraîchissement du cache...');

    // Temporairement passer en mode webservice pour forcer la récupération
    final dataModeProvider =
        Provider.of<DataModeProvider>(context, listen: false);
    final originalMode = dataModeProvider.isCacheMode;

    try {
      await dataModeProvider.setCacheMode(false);
      await getIndicateursMensuel(context, societe, annee, mois);
    } finally {
      // Restaurer le mode original
      await dataModeProvider.setCacheMode(originalMode);
    }
  }
}
