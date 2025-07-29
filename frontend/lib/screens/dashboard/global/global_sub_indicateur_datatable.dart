import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class GlobalSubIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final List<String> annees;
  final String? selectedSousIndicateur;
  final String? selectedIndicateur;
  final void Function(String) onSelectSousIndicateur;
  final dynamic sousIndicsResponse; // Peut être Navision ou Odoo
  final bool isKEuros;
  final List<String> associeLibelles;
  final Map<String, String> formuleTextParAnnee;

  const GlobalSubIndicateurDataTable({
    super.key,
    required this.data,
    required this.annees,
    required this.selectedSousIndicateur,
    required this.selectedIndicateur,
    required this.onSelectSousIndicateur,
    this.sousIndicsResponse,
    this.isKEuros = false,
    required this.associeLibelles,
    this.formuleTextParAnnee = const {},
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 16,
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columns: [
        const DataColumn(label: Text('Sous-indicateur', style: TextStyle(fontSize: 13))),
        const DataColumn(label: Text('Libellé', style: TextStyle(fontSize: 13))),
        ...annees.map((an) => DataColumn(label: Text(an, style: TextStyle(fontSize: 13)))),
      ],
      rows: data.entries.map((entry) {
        final sousInd = entry.key;
        final montants = entry.value;
        String? initiales;
        String? libelle;
        if (sousIndicsResponse != null) {
          try {
            final sousIndicsMap = sousIndicsResponse.sousIndicateurs;
            outerLoop:
            for (final annee in sousIndicsMap.keys) {
              final indicMap = sousIndicsMap[annee];
              if (indicMap == null) continue;
              for (final indicateurKey in indicMap.keys) {
                final sousIndicateursList = indicMap[indicateurKey] ?? [];
                for (final sousIndicateurObj in sousIndicateursList) {
                  if (sousIndicateurObj.sousIndicateur == sousInd) {
                    initiales = sousIndicateurObj.initiales;
                    libelle = sousIndicateurObj.libelle;
                    break outerLoop;
                  }
                }
              }
            }
          } catch (e) {
            // ignore, fallback null
          }
        }
        final isSelected = sousInd == selectedSousIndicateur;
        final libelleOriginal = libelle ?? '';
        final isAssocie = associeLibelles.contains(libelleOriginal);
        String signe = '';
        String? formuleText;
        // Récupérer la formule textuelle de l'indicateur sélectionné pour l'année courante
        if (formuleTextParAnnee.isNotEmpty && selectedIndicateur != null) {
          final anneeRef = annees.isNotEmpty ? annees.last : formuleTextParAnnee.keys.first;
          formuleText = formuleTextParAnnee[anneeRef];
          // DEBUG
          print('[DEBUG] formuleText utilisée: ' + (formuleText ?? ''));
          if (formuleText != null && formuleText.isNotEmpty) {
            // Cherche le signe pour le libellé (pas le code)
            final plusPattern = RegExp(r"\+\s*" + RegExp.escape(libelle ?? sousInd), caseSensitive: false);
            final minusPattern = RegExp(r"-\s*" + RegExp.escape(libelle ?? sousInd), caseSensitive: false);
            if (plusPattern.hasMatch(formuleText)) {
              signe = '+';
            } else if (minusPattern.hasMatch(formuleText)) {
              signe = '-';
            }
          }
        }
        // ...existing code...
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectSousIndicateur(sousInd),
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
                  initiales ?? sousInd,
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
                      child: Row(
                        children: [
                          if (isAssocie && signe.isNotEmpty)
                            Text(signe, style: TextStyle(fontWeight: FontWeight.bold, color: signe == '+' ? Colors.green : Colors.red)),
                          SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              libelle ?? sousInd,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sousIndicsResponse != null)
                      Builder(
                        builder: (context) {
                          String? formule;
                          try {
                            final sousIndicsMap = sousIndicsResponse.sousIndicateurs;
                            outerLoop:
                            for (final annee in sousIndicsMap.keys) {
                              final indicMap = sousIndicsMap[annee];
                              if (indicMap == null) continue;
                              for (final indicateurKey in indicMap.keys) {
                                final sousIndicateursList = indicMap[indicateurKey] ?? [];
                                for (final sousIndicateurObj in sousIndicateursList) {
                                  if (sousIndicateurObj.sousIndicateur == sousInd) {
                                    if (sousIndicateurObj.formule != null && sousIndicateurObj.formule.isNotEmpty) {
                                      formule = sousIndicateurObj.formule;
                                    }
                                    break outerLoop;
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            // ignore
                          }
                          if (formule != null && formule.isNotEmpty)
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Formule'),
                                        ],
                                      ),
                                      content: Text(formule!),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: Text('Fermer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              ),
                            );
                          return SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
            ...annees.map((an) => DataCell(
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(montants[an]?.format(isKEuros: isKEuros) ?? '0,00 €', style: TextStyle(fontSize: 12)),
              ),
            )),
          ],
        );
      }).toList(),
    );
}}