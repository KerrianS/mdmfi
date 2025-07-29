import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class GlobalIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final List<String> annees;
  final String? selectedIndicateur;
  final void Function(String) onSelectIndicateur;
  final dynamic sigResult; // Ajout du sigResult pour accéder aux libellés
  final bool isKEuros; // Paramètre pour affichage en KEuros

  const GlobalIndicateurDataTable({
    super.key,
    required this.data,
    required this.annees,
    required this.selectedIndicateur,
    required this.onSelectIndicateur,
    this.sigResult,
    this.isKEuros = false,
  });

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via le champ associe de l'indicateur sélectionné), façon mensuel
    List<String> associeLibelles = [];
    if (sigResult != null && selectedIndicateur != null) {
      for (final annee in sigResult.indicateurs.keys) {
        final indicateursList = sigResult.indicateurs[annee] as List<dynamic>;
        final indObj = indicateursList.cast<dynamic>().firstWhere(
          (i) => i != null && i.indicateur == selectedIndicateur,
          orElse: () => null,
        );
        if (indObj != null && indObj.associe != null && indObj.associe.isNotEmpty) {
          associeLibelles = List<String>.from(indObj.associe);
          break;
        }
      }
    }

    // Réordonner les entrées pour mettre 'MC' en premier
    final entries = [
      if (data.containsKey('MC')) MapEntry('MC', data['MC']!),
      ...data.entries.where((e) => e.key != 'MC'),
    ];

    return SingleChildScrollView(
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 16,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 32,
        columns: [
          const DataColumn(label: Text('Indicateur', style: TextStyle(fontSize: 12))),
          const DataColumn(label: Text('Libellé', style: TextStyle(fontSize: 12))),
          ...annees.map((an) => DataColumn(label: Text(an, style: TextStyle(fontSize: 12)))),
        ],
        rows: entries.map((entry) {
          final ind = entry.key;
          final montants = entry.value;
          final isSelected = ind == selectedIndicateur;
          final isAssocie = associeLibelles.contains(ind);
          // Chercher le libellé dans sigResult si possible
          String libelle = ind;
          if (sigResult != null) {
            for (final annee in sigResult.indicateurs.keys) {
              final indicateursList = sigResult.indicateurs[annee] as List<dynamic>;
              final indObj = indicateursList.cast<dynamic>().firstWhere(
                (i) => i != null && i.indicateur == ind,
                orElse: () => null,
              );
              if (indObj != null && indObj.libelle != null && indObj.libelle.isNotEmpty) {
                libelle = indObj.libelle;
                break;
              }
            }
          }
          return DataRow(
            selected: isSelected,
            onSelectChanged: (_) => onSelectIndicateur(ind),
            color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
              if (isAssocie) {
                return Colors.yellow.shade200;
              }
              if (isSelected) {
                return Colors.grey.shade300;
              }
              if (states.contains(MaterialState.hovered)) {
                return Colors.grey.withOpacity(0.1);
              }
              return null;
            }),
            cells: [
              DataCell(
                Container(
                  width: 100,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    ind,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  width: 200,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    libelle,
                    style: TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...annees.map((an) => DataCell(
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    montants[an]?.format(isKEuros: isKEuros) ?? '-',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }
}
