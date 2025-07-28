import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobaitec_decision_making/models/OdooSIGModel.dart';

class OdooSIGService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // --- Comptes mensuels paginés ---
  Future<OdooComptesMensuelPage> fetchComptesMensuel({
    required String societe,
    required int annee,
    required int mois,
    required String sousIndicateur,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = {
      'annee': annee.toString(),
      'mois': mois.toString(),
      'sous_indicateur': sousIndicateur,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final path = '/$societe/odoo/comptes/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return OdooComptesMensuelPage.fromJson(data);
    } else {
      print('Erreur lors du chargement des comptes mensuels: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des comptes mensuels');
    }
  }

  // --- Indicateurs mensuels ---
  Future<OdooIndicateursMensuelResponse> fetchIndicateursMensuel({
    required String societe,
    required int annee,
  }) async {
    final params = {
      'annee': annee.toString(),
    };
    final path = '/$societe/odoo/indicateurs/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return OdooIndicateursMensuelResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des indicateurs mensuels: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des indicateurs mensuels');
    }
  }

  // --- Sous-indicateurs mensuels ---
  Future<OdooSousIndicateursMensuelResponse> fetchSousIndicateursMensuel({
    required String societe,
    required int annee,
  }) async {
    final params = {
      'annee': annee.toString(),
    };
    final path = '/$societe/odoo/sous_indicateurs/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return OdooSousIndicateursMensuelResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des sous-indicateurs mensuels: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des sous-indicateurs mensuels');
    }
  }

  // --- GLOBAL : Indicateurs ---
  Future<OdooIndicateursGlobalResponse> fetchIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
  }) async {
    final params = {
      'periode': periode,
      if (trimestre != null) 'trimestre': trimestre.toString(),
    };
    final path = '/$societe/odoo/indicateurs/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    print('[API] GET $uri');
    print('[API] Status:  [33m${response.statusCode} [0m');
    print('[API] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[API] Parsed indicateurs: ' + data.toString());
      return OdooIndicateursGlobalResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des indicateurs globaux: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des indicateurs globaux');
    }
  }

  // --- GLOBAL : Sous-indicateurs ---
  Future<OdooSousIndicateursGlobalResponse> fetchSousIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
  }) async {
    final params = {
      'periode': periode,
      if (trimestre != null) 'trimestre': trimestre.toString(),
    };
    final path = '/$societe/odoo/sous_indicateurs/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    print('[API] GET $uri');
    print('[API] Status:  [33m${response.statusCode} [0m');
    print('[API] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[API] Parsed sous_indicateurs: ' + data.toString());
      return OdooSousIndicateursGlobalResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des sous-indicateurs globaux: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des sous-indicateurs globaux');
    }
  }

  // --- GLOBAL : Comptes paginés ---
  Future<OdooComptesGlobalResponse> fetchComptesGlobal({
    required String societe,
    required String sousIndicateur,
    required String periode,
    int? trimestre,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = {
      'sous_indicateur': sousIndicateur,
      'periode': periode,
      if (trimestre != null) 'trimestre': trimestre.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final path = '/$societe/odoo/comptes/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    print('[API] GET $uri');
    print('[API] Status:  [33m${response.statusCode} [0m');
    print('[API] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[API] Parsed comptes: ' + data.toString());
      return OdooComptesGlobalResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des comptes globaux: ' + response.body.toString());
      throw Exception('Erreur lors du chargement des comptes globaux');
    }
  }
}
