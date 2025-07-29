import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';

class NavisionSIGService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // --- NOUVEAU : Comptes mensuels paginés ---
  Future<NavisionComptesMensuelPage> fetchComptesMensuel({
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
    final path = '/$societe/comptes/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NavisionComptesMensuelPage.fromJson(data);
    } else {
      print('Erreur lors du chargement des comptes mensuels: ' +
          response.body.toString());
      throw Exception('Erreur lors du chargement des comptes mensuels');
    }
  }

  // --- NOUVEAU : Indicateurs mensuels ---
  Future<NavisionIndicateursMensuelResponse> fetchIndicateursMensuel({
    required String societe,
    required int annee,
  }) async {
    final params = {
      'annee': annee.toString(),
    };
    final path = '/$societe/indicateurs/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NavisionIndicateursMensuelResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des indicateurs mensuels: ' +
          response.body.toString());
      throw Exception('Erreur lors du chargement des indicateurs mensuels');
    }
  }

  // --- NOUVEAU : Sous-indicateurs mensuels ---
  Future<NavisionSousIndicateursMensuelResponse> fetchSousIndicateursMensuel({
    required String societe,
    required int annee,
  }) async {
    final params = {
      'annee': annee.toString(),
    };
    final path = '/$societe/sous_indicateurs/mensuel';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return NavisionSousIndicateursMensuelResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des sous-indicateurs mensuels: ' +
          response.body.toString());
      throw Exception(
          'Erreur lors du chargement des sous-indicateurs mensuels');
    }
  }

  // --- GLOBAL : Indicateurs ---
  Future<NavisionIndicateursGlobalResponse> fetchIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
  }) async {
    final params = {
      'periode': periode,
      if (trimestre != null) 'trimestre': trimestre.toString(),
    };
    final path = '/$societe/indicateurs/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);

    print('[NavisionSIGService] Tentative de connexion à: $uri');
    print('[NavisionSIGService] Paramètres: $params');

    try {
      final response = await http.get(uri);
      print('[API] GET $uri');
      print('[API] Status: ${response.statusCode}');
      print('[API] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[API] Parsed indicateurs: ' + data.toString());
        return NavisionIndicateursGlobalResponse.fromJson(data);
      } else {
        print('Erreur lors du chargement des indicateurs globaux: ' +
            response.body.toString());
        throw Exception(
            'Erreur lors du chargement des indicateurs globaux: ${response.statusCode}');
      }
    } catch (e) {
      print('[NavisionSIGService] Exception lors de la requête: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // --- GLOBAL : Sous-indicateurs ---
  Future<NavisionSousIndicateursGlobalResponse> fetchSousIndicateursGlobal({
    required String societe,
    required String periode,
    int? trimestre,
  }) async {
    final params = {
      'periode': periode,
      if (trimestre != null) 'trimestre': trimestre.toString(),
    };
    final path = '/$societe/sous_indicateurs/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    print('[API] GET $uri');
    print('[API] Status:  [33m${response.statusCode} [0m');
    print('[API] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[API] Parsed sous_indicateurs: ' + data.toString());
      return NavisionSousIndicateursGlobalResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des sous-indicateurs globaux: ' +
          response.body.toString());
      throw Exception('Erreur lors du chargement des sous-indicateurs globaux');
    }
  }

  // --- GLOBAL : Comptes paginés ---
  Future<NavisionComptesGlobalResponse> fetchComptesGlobal({
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
    final path = '/$societe/comptes/global';
    final uri = Uri.parse(baseUrl + path).replace(queryParameters: params);
    final response = await http.get(uri);
    print('[API] GET $uri');
    print('[API] Status:  [33m${response.statusCode} [0m');
    print('[API] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('[API] Parsed comptes: ' + data.toString());
      return NavisionComptesGlobalResponse.fromJson(data);
    } else {
      print('Erreur lors du chargement des comptes globaux: ' +
          response.body.toString());
      throw Exception('Erreur lors du chargement des comptes globaux');
    }
  }
}
