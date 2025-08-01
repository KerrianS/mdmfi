import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class GlobalSubIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final List<String> annees;
  final String? selectedSousIndicateur;
  final String? selectedIndicateur;
  final void Function(String) onSelectSousIndicateur;
  final dynamic sousIndicsResponse; // Peut être Navision ou Odoo
  final bool isKEuros;

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
        const DataColumn(
            label: Text('Sous-indicateur', style: TextStyle(fontSize: 13))),
        const DataColumn(
            label: Text('Libellé', style: TextStyle(fontSize: 13))),
        ...annees.map((an) =>
            DataColumn(label: Text(an, style: TextStyle(fontSize: 13)))),
      ],
      rows: data.entries.map((entry) {
        final sousInd = entry.key;
        final montants = entry.value;
        String? initiales;
        String? libelle;
        if (sousIndicsResponse != null) {
          try {
            final sousIndicsMap =
                sousIndicsResponse['sousIndicateurs'] as Map<String, dynamic>?;
            if (sousIndicsMap != null) {
              outerLoop:
              for (final annee in sousIndicsMap.keys) {
                final indicMap = sousIndicsMap[annee] as Map<String, dynamic>?;
                if (indicMap == null) continue;
                for (final indicateurKey in indicMap.keys) {
                  final sousIndicateursList =
                      indicMap[indicateurKey] as List<dynamic>? ?? [];
                  for (final sousIndicateurObj in sousIndicateursList) {
                    final sousIndicateurName =
                        sousIndicateurObj['sousIndicateur'] as String?;
                    if (sousIndicateurName == sousInd) {
                      initiales = sousIndicateurObj['initiales'] as String?;
                      libelle = sousIndicateurObj['libelle'] as String?;
                      break outerLoop;
                    }
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
        String signe = '';
        String? formuleText;
        // Récupérer la formule textuelle de l'indicateur sélectionné pour l'année courante
        if (formuleTextParAnnee.isNotEmpty && selectedIndicateur != null) {
          final anneeRef =
              annees.isNotEmpty ? annees.last : formuleTextParAnnee.keys.first;
          formuleText = formuleTextParAnnee[anneeRef];
        }
        // Récupérer la formule textuelle de l'indicateur sélectionné pour l'année courante
        if (formuleTextParAnnee.isNotEmpty && selectedIndicateur != null) {
          final anneeRef =
              annees.isNotEmpty ? annees.last : formuleTextParAnnee.keys.first;
          formuleText = formuleTextParAnnee[anneeRef];
          // DEBUG
          print('[DEBUG] formuleText utilisée: ' + (formuleText ?? ''));
          if (formuleText != null && formuleText.isNotEmpty) {
            // Cherche le signe pour le libellé dans la formule
            final libelleToSearch = libelle ?? sousInd;

            // Pattern pour détecter les signes explicites + ou -
            final plusPattern = RegExp(
                r"\+\s*" + RegExp.escape(libelleToSearch) + r"\s*\(",
                caseSensitive: false);
            final minusPattern = RegExp(
                r"-\s*" + RegExp.escape(libelleToSearch) + r"\s*\(",
                caseSensitive: false);

            // Si on trouve un signe explicite, on l'utilise
            if (plusPattern.hasMatch(formuleText)) {
              signe = '+';
            } else if (minusPattern.hasMatch(formuleText)) {
              signe = '-';
            } else {
              // Sinon, on détermine le signe par défaut selon le contexte
              // Si le libellé apparaît dans la formule sans signe explicite,
              // on considère que c'est un terme positif (addition)
              final libellePattern = RegExp(
                  RegExp.escape(libelleToSearch) + r"\s*\(",
                  caseSensitive: false);
              if (libellePattern.hasMatch(formuleText)) {
                signe = '+'; // Par défaut, les termes sont positifs
              }
            }
          }
        }
        // Restauration de la fonctionnalité associe
        final isAssocie = formuleText != null &&
            formuleText.isNotEmpty &&
            (formuleText.contains(libelle ?? sousInd) ||
                formuleText.contains(initiales ?? sousInd));
        // ...existing code...
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectSousIndicateur(sousInd),
          color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (isAssocie) {
              return Colors.grey.shade300;
            }
            if (isSelected) {
              return Colors.yellow.shade200;
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
                      child: Text(
                        libelle ?? sousInd,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Row(
                        children: [
                          if (isAssocie && signe.isNotEmpty)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: signe == '+'
                                      ? [
                                          Color(0xFF4CAF50),
                                          Color(0xFF45A049)
                                        ] // Vert dégradé
                                      : [
                                          Color(0xFFF44336),
                                          Color(0xFFD32F2F)
                                        ], // Rouge dégradé
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (signe == '+'
                                            ? Color(0xFF4CAF50)
                                            : Color(0xFFF44336))
                                        .withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  signe == '+' ? Icons.add : Icons.remove,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          SizedBox(width: 4),
                          if (sousIndicsResponse != null)
                            Builder(
                              builder: (context) {
                                String? formule;
                                print(
                                    '[DEBUG] Recherche formule pour sousInd: $sousInd');
                                print(
                                    '[DEBUG] sousIndicsResponse: $sousIndicsResponse');

                                try {
                                  final sousIndicsMap =
                                      sousIndicsResponse['sousIndicateurs'];
                                  print(
                                      '[DEBUG] Type de sousIndicsMap: ${sousIndicsMap.runtimeType}');
                                  print(
                                      '[DEBUG] sousIndicsMap brut: $sousIndicsMap');
                                  print(
                                      '[DEBUG] sousIndicsMap: $sousIndicsMap');

                                  if (sousIndicsMap != null) {
                                    outerLoop:
                                    for (final annee in sousIndicsMap.keys) {
                                      print('[DEBUG] Année: $annee');
                                      final indicMap = sousIndicsMap[annee]
                                          as Map<String, dynamic>?;
                                      print('[DEBUG] indicMap: $indicMap');

                                      if (indicMap == null) continue;
                                      for (final indicateurKey
                                          in indicMap.keys) {
                                        print(
                                            '[DEBUG] Indicateur: $indicateurKey');
                                        final sousIndicateursList =
                                            indicMap[indicateurKey]
                                                    as List<dynamic>? ??
                                                [];
                                        print(
                                            '[DEBUG] Sous-indicateurs: $sousIndicateursList');

                                        for (final sousIndicateurObj
                                            in sousIndicateursList) {
                                          final sousIndicateurName =
                                              sousIndicateurObj[
                                                  'sousIndicateur'] as String?;
                                          print(
                                              '[DEBUG] Comparaison: $sousIndicateurName == $sousInd');

                                          if (sousIndicateurName == sousInd) {
                                            final formuleObj =
                                                sousIndicateurObj['formule']
                                                    as String?;
                                            print(
                                                '[DEBUG] Formule trouvée: $formuleObj');
                                            if (formuleObj != null &&
                                                formuleObj.isNotEmpty) {
                                              formule = formuleObj;
                                            }
                                            break outerLoop;
                                          }
                                        }
                                      }
                                    }
                                  }
                                } catch (e) {
                                  print('[DEBUG] Erreur: $e');
                                  // ignore
                                }
                                print('[DEBUG] Formule finale: $formule');
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Formule'),
                                          ],
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (formule != null &&
                                                  formule.isNotEmpty) ...[
                                                Text(
                                                  'Formule :',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  child: Text(
                                                    formule!,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'Aucune formule disponible pour ce sous-indicateur.',
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(),
                                            child: Text('Fermer'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Icon(Icons.info_outline,
                                      size: 18, color: Colors.blue),
                                );
                              },
                            ),
                        ],
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
                        montants[an]?.format(isKEuros: isKEuros) ?? '0,00 €',
                        style: TextStyle(fontSize: 12)),
                  ),
                )),
          ],
        );
      }).toList(),
    );
  }
}
