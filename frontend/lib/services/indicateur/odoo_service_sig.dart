import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobaitec_decision_making/models/OdooSIGModel.dart';

class SIGIndicateur {
  final double valeur;
  final String libelle;
  SIGIndicateur({required this.valeur, required this.libelle});
}

class OdooSIGResult {
  final Map<String, Map<String, SIGIndicateur>> sigAnnee; 
  final Map<String, Map<String, double>> sousIndicateursAnnee; 
  final List<OdooSIGCompte> comptes;
  OdooSIGResult({required this.sigAnnee, required this.sousIndicateursAnnee, required this.comptes});
}

class OdooSIGService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<OdooSIGResult> fetchSIGData({required String societe, required String periode, required int annee, int? trimestre}) async {
    final params = {
      'periode': periode,
      'annee': annee.toString(),
      if (trimestre != null) 'trimestre': trimestre.toString(),
    };
    final uri = Uri.parse('$baseUrl/$societe/comptes').replace(queryParameters: params);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // sig_annee
      final sigAnnee = <String, Map<String, SIGIndicateur>>{};
      (data['sig_annee'] as Map<String, dynamic>).forEach((annee, indicateurs) {
        sigAnnee[annee] = {};
        (indicateurs as Map).forEach((k, v) {
          if (v is Map) {
            sigAnnee[annee]![k] = SIGIndicateur(
              valeur: (v['valeur'] as num).toDouble(),
              libelle: v['libelle'] ?? k,
            );
          }
        });
      });

      // sous_indicateurs_annee
      final sousIndics = <String, Map<String, double>>{};
      (data['sous_indicateurs_annee'] as Map<String, dynamic>).forEach((sous, annees) {
        sousIndics[sous] = Map<String, double>.from(
          (annees as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
      });

      // comptes
      final comptes = (data['comptes'] as List)
          .map((json) => OdooSIGCompte.fromJson(json))
          .toList();

      return OdooSIGResult(sigAnnee: sigAnnee, sousIndicateursAnnee: sousIndics, comptes: comptes);
    } else {
      throw Exception('Erreur lors du chargement des comptes Odoo SIG');
    }
  }
}
