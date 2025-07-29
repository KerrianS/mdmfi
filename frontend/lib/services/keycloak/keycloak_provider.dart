import 'package:flutter/material.dart';

class KeycloakProvider extends ChangeNotifier {
  bool get isOdooSelected => _selectedCompany?.toLowerCase() == 'aitecservice';
  String? _accessToken;
  String? _userName;
  List<String>? _userGroups;
  List<String>? _userRoles;
  List<Map<String, String>> _accessibleCompanies = [];
  String? _selectedCompany;
  bool _isReloadingData = false;

  String? get accessToken => _accessToken;
  String? get userName => _userName;
  List<String>? get userGroups => _userGroups;
  List<String>? get userRoles => _userRoles;
  bool get isConnected => _accessToken != null && _accessToken!.isNotEmpty;
  bool get isReloadingData => _isReloadingData;

  List<Map<String, String>> get accessibleCompanies => _accessibleCompanies;
  String? get selectedCompany => _selectedCompany;

  bool get hasMDMFi => _userRoles?.contains('MDM-Fi') ?? false;
  bool get isAdmin => _userRoles?.contains('permissions-admin') ?? false;
  bool get isClient => _userRoles?.contains('permissions-client') ?? false;

  void setAuth({
    required String accessToken,
    required String userName,
    required List<String> userGroups,
    required List<String> userRoles,
  }) {
    print('[KeycloakProvider] setAuth appelé');
    print('  accessToken: ' + accessToken);
    print('  userName: ' + userName);
    print('  userGroups: ' + userGroups.toString());
    print('  userRoles: ' + userRoles.toString());
    _accessToken = accessToken;
    _userName = userName;
    _userGroups = userGroups;
    _userRoles = userRoles;
    notifyListeners();
  }

  void clearAuth() {
    print('[KeycloakProvider] clearAuth appelé');
    _accessToken = null;
    _userName = null;
    _userGroups = null;
    _userRoles = null;
    _accessibleCompanies = [];
    _selectedCompany = null;
    _isReloadingData = false;
    notifyListeners();
  }

  void setAccessibleCompanies(List<Map<String, String>> companies) {
    print('[KeycloakProvider] setAccessibleCompanies appelé avec: ' + companies.toString());
    _accessibleCompanies = companies;
    notifyListeners();
  }

  void setSelectedCompany(String company) {
    print('[KeycloakProvider] setSelectedCompany appelé avec: ' + company);
    if (_selectedCompany != company) {
      _selectedCompany = company;
      notifyListeners();
    }
  }

  void setDataReloading(bool isReloading) {
    if (_isReloadingData != isReloading) {
      _isReloadingData = isReloading;
      notifyListeners();
    }
  }
} 