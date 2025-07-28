import 'dart:convert';
import 'package:http/http.dart' as http;

class KeycloakService {
  static const String baseUrl = 'https://api.client.aitecservice.com/api/keycloak';

  Future<String> login({required String username, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data']['access_token'] ?? '';
      }
      throw Exception('Échec de la connexion : ${response.body}');
    } else {
      throw Exception('Échec de la connexion : ${response.body}');
    }
  }

  Future<KeycloakUserInfo> getUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return KeycloakUserInfo.fromJson(data['data']);
      }
      throw Exception('Impossible de récupérer les infos utilisateur :  {response.body}');
    } else {
      throw Exception('Impossible de récupérer les infos utilisateur :  {response.body}');
    }
  }

  Future<void> logout(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la déconnexion :  {response.body}');
    }
  }

  Future<List<Map<String, String>>> fetchAccessibleCompanies(String token, List<String> userGroups) async {
    print('[fetchAccessibleCompanies] Token reçu: ' + token);
    print('[fetchAccessibleCompanies] UserGroups reçus: ' + userGroups.toString());
    final response = await http.get(
      Uri.parse('https://api-client.aitecservice.com/api/keycloak/clients-accessibles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('[KeycloakService] Réponse brute: ' + response.body);
    print('[KeycloakService] Status code: ' + response.statusCode.toString());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      print('[KeycloakService] Data décodée: ' + data.toString());
      final List<Map<String, String>> companies = [];
      // Ajout du sous-groupe employé si présent
      final employeeSubGroup = userGroups.firstWhere(
        (g) => g.startsWith('/Employees/') && g != '/Employees',
        orElse: () => '',
      );
      print('[KeycloakService] employeeSubGroup: ' + employeeSubGroup);
      String? defaultEmployeeCompany;
      if (employeeSubGroup.isNotEmpty) {
        defaultEmployeeCompany = employeeSubGroup.split('/').last;
        companies.add({'id': employeeSubGroup, 'name': defaultEmployeeCompany});
        print('[KeycloakService] Ajout employé: $defaultEmployeeCompany');
      }
      // Ajout des clients et sous-groupes à plat
      final clients = _flattenClientsWithMDMFi(data['clients']);
      print('[KeycloakService] Clients filtrés MDM-Fi: ' + clients.toString());
      companies.addAll(clients);
      print('[KeycloakService] Liste finale sociétés: $companies');
      return companies;
    } else {
      print('[KeycloakService] Erreur HTTP: ${response.statusCode}');
      throw Exception('Erreur lors de la récupération des sociétés accessibles');
    }
  }

  List<Map<String, String>> _flattenClientsWithMDMFi(List clients) {
    List<Map<String, String>> result = [];
    for (final client in clients) {
      final parentName = client['name'];
      final parentLogo = client['logoURL']?.toString() ?? '';
      final parentRoles = (client['roles'] as List<dynamic>? ?? []).map((r) => r['name']?.toString() ?? '').toList();
      final subGroups = client['subGroups'] as List<dynamic>? ?? [];
      // Si le client a le rôle MDM-Fi et pas de sous-groupes, on l'ajoute
      if (subGroups.isEmpty && parentRoles.contains('MDM-Fi')) {
        result.add({'id': client['id'], 'name': parentName, 'logoURL': parentLogo});
      }
      // Sinon, on regarde les sous-groupes
      for (final sub in subGroups) {
        final subRoles = (sub['roles'] as List<dynamic>? ?? []).map((r) => r['name']?.toString() ?? '').toList();
        if (subRoles.contains('MDM-Fi')) {
          result.add({
            'id': sub['id'],
            'name': '$parentName-${sub['name']}',
            'logoURL': sub['logoURL']?.toString() ?? '',
          });
        }
      }
    }
    return result;
  }
}

class KeycloakUserInfo {
  final String name;
  final List<String> groups;
  final List<String> roles;

  KeycloakUserInfo({required this.name, required this.groups, required this.roles});

  factory KeycloakUserInfo.fromJson(Map<String, dynamic> json) {
    return KeycloakUserInfo(
      name: json['name'] ?? '',
      groups: (json['groups'] as List<dynamic>?)?.map((g) => g.toString()).toList() ?? [],
      roles: (json['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [],
    );
  }

  bool get hasMDMFi => roles.contains('MDM-Fi');
  bool get isAdmin => roles.contains('permissions-admin');
  bool get isClient => roles.contains('permissions-client');
}
