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
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via le champ formule_text de l'indicateur sélectionné)
    List<String> associeLibelles = [];
    if (sigResult != null && selectedIndicateur != null) {
      for (final annee in sigResult.indicateurs.keys) {
        final indicateursList = sigResult.indicateurs[annee] as List<dynamic>;
        final indObj = indicateursList.cast<dynamic>().firstWhere(
              (i) => i != null && i.indicateur == selectedIndicateur,
              orElse: () => null,
            );
        if (indObj != null &&
            indObj.formuleText != null &&
            indObj.formuleText.isNotEmpty) {
          // Extraire les sous-indicateurs depuis formule_text
          final formuleText = indObj.formuleText;
          final Set<String> sousIndicateursTrouves = {};

          // Pattern pour capturer les sous-indicateurs dans la formule
          // Cherche les patterns comme "MC (1234.56)", "PRESTATIONS DE SERVICES (5678.90)", etc.
          final pattern = RegExp(r'([A-Z][A-Z\sÉÈÊËÀÂÄÔÙÛÜÇ]+)\s*\([^)]+\)');
          final matches = pattern.allMatches(formuleText);

          for (final match in matches) {
            final sousIndicateur = match.group(1)?.trim();
            if (sousIndicateur != null && sousIndicateur.isNotEmpty) {
              sousIndicateursTrouves.add(sousIndicateur);
            }
          }

          associeLibelles = sousIndicateursTrouves.toList();
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
          const DataColumn(
              label: Text('Indicateur', style: TextStyle(fontSize: 12))),
          const DataColumn(
              label: Text('Libellé', style: TextStyle(fontSize: 12))),
          ...annees.map((an) =>
              DataColumn(label: Text(an, style: TextStyle(fontSize: 12)))),
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
              final indicateursList =
                  sigResult.indicateurs[annee] as List<dynamic>;
              final indObj = indicateursList.cast<dynamic>().firstWhere(
                    (i) => i != null && i.indicateur == ind,
                    orElse: () => null,
                  );
              if (indObj != null &&
                  indObj.libelle != null &&
                  indObj.libelle.isNotEmpty) {
                libelle = indObj.libelle;
                break;
              }
            }
          }
          return DataRow(
            selected: isSelected,
            onSelectChanged: (_) => onSelectIndicateur(ind),
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          libelle,
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            List<Widget> formuleWidgets = [];
                            if (sigResult != null &&
                                sigResult.indicateurs != null) {
                              for (final annee in annees) {
                                String formuleText = '';
                                String formuleNumeric = '';
                                if (sigResult.indicateurs[annee] != null) {
                                  final indicateursList = sigResult
                                      .indicateurs[annee] as List<dynamic>;
                                  final indObj = indicateursList
                                      .cast<dynamic>()
                                      .firstWhere(
                                        (i) =>
                                            i != null &&
                                            ((i is Map &&
                                                    (i['indicateur'] == ind)) ||
                                                (i is! Map &&
                                                    (i.indicateur == ind))),
                                        orElse: () => null,
                                      );
                                  if (indObj != null) {
                                    if (indObj is Map) {
                                      formuleText = indObj['formule_text'] ??
                                          indObj['formuleText'] ??
                                          '';
                                      formuleNumeric =
                                          indObj['formule_numeric'] ??
                                              indObj['formuleNumeric'] ??
                                              '';
                                    } else {
                                      // Pour les modèles Dart, utilise les propriétés du modèle
                                      formuleText = indObj.formuleText ?? '';
                                      formuleNumeric =
                                          indObj.formuleNumeric ?? '';
                                    }
                                  }
                                }
                                formuleWidgets.add(Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Année : $annee',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'Formule (textuelle) : ${formuleText.isNotEmpty ? formuleText : '-'}'),
                                    Text(
                                        'Formule (numérique) : ${formuleNumeric.isNotEmpty ? formuleNumeric : '-'}'),
                                    SizedBox(height: 8),
                                  ],
                                ));
                              }
                            }
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue, size: 20),
                                      SizedBox(width: 8),
                                      Text('Indicateur : $ind',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(width: 16),
                                      Text('Libellé : $libelle',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...formuleWidgets,
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text('Fermer'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Icon(Icons.info_outline,
                              size: 18, color: Colors.blue),
                        ),
                      ),
                    ],
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
