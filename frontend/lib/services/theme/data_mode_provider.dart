import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataModeProvider with ChangeNotifier {
  static const String _cacheModeKey = 'data_mode_cache';
  bool _isCacheMode = false;

  bool get isCacheMode => _isCacheMode;

  DataModeProvider() {
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isCacheMode = prefs.getBool(_cacheModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement du mode de données: $e');
      // En cas d'erreur, on garde le mode webservice par défaut
      _isCacheMode = false;
      notifyListeners();
    }
  }

  Future<void> setCacheMode(bool isCacheMode) async {
    if (_isCacheMode != isCacheMode) {
      _isCacheMode = isCacheMode;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_cacheModeKey, isCacheMode);
      } catch (e) {
        print('Erreur lors de la sauvegarde du mode de données: $e');
      }
    }
  }

  String get modeDescription => _isCacheMode
      ? 'Mode Cache (données locales)'
      : 'Mode Webservice (données temps réel)';

  String get modeIcon => _isCacheMode ? '📦' : '🌐';
}
