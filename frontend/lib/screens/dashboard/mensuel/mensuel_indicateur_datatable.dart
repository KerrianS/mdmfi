import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data; // indicateur -> {mois: montant}
  final List<String>
      mois; // tous les mois à afficher en colonnes (format YYYYMM)
  final String? selectedIndicateur;
  final void Function(String) onSelectIndicateur;
  final dynamic indicateursResponse; // pour accéder aux libellés
  final bool isKEuros; // Paramètre pour affichage en KEuros

  const MensuelIndicateurDataTable({
    super.key,
    required this.data,
    required this.mois,
    required this.selectedIndicateur,
    required this.onSelectIndicateur,
    this.indicateursResponse,
    this.isKEuros = false,
  });

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via formule_text)
    List<String> associeLibelles = [];
    if (indicateursResponse != null && selectedIndicateur != null) {
      for (final moisEntry in indicateursResponse.mois.entries) {
        final indicateursList = moisEntry.value;
        dynamic indObj = indicateursList.cast<dynamic>().firstWhere(
              (i) => i.indicateur == selectedIndicateur,
              orElse: () => null,
            );
        if (indObj != null &&
            indObj.formuleText != null &&
            indObj.formuleText.isNotEmpty) {
          // Extraire les sous-indicateurs depuis formule_text
          final Set<String> sousIndicateursTrouves = {};
          final pattern = RegExp(r'([A-Z][A-Z\sÉÈÊËÀÂÄÔÙÛÜÇ]+)\s*\([^)]+\)');
          final matches = pattern.allMatches(indObj.formuleText);

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

    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 12,
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columns: [
        DataColumn(
          label: Container(
            width: 110,
            alignment: Alignment.centerLeft,
            child: Text('Indicateur', style: TextStyle(fontSize: 13)),
          ),
        ),
        DataColumn(
          label: Container(
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text('Libellé', style: TextStyle(fontSize: 13)),
          ),
        ),
        ...mois.map((m) => DataColumn(
              label: Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: Text(m, style: TextStyle(fontSize: 13)),
              ),
            )),
      ],
      rows: data.entries.map((entry) {
        final ind = entry.key;
        final montants = entry.value;
        String? initiales;
        String? libelle;
        if (indicateursResponse != null) {
          for (final moisEntry in indicateursResponse.mois.entries) {
            final indicateursList = moisEntry.value;
            dynamic indicateurObj = indicateursList.cast<dynamic>().firstWhere(
                  (i) => i.indicateur == ind,
                  orElse: () => null,
                );
            if (indicateurObj != null &&
                indicateurObj.libelle != null &&
                indicateurObj.libelle.isNotEmpty) {
              initiales = indicateurObj.initiales;
              libelle = indicateurObj.libelle;
              break;
            }
          }
        }
        final isSelected = ind == selectedIndicateur;
        final isAssocie = associeLibelles.contains(ind) ||
            (libelle != null && associeLibelles.contains(libelle));

        // Calculer le signe pour la colonne libellé
        String? signeLibelle;
        if (indicateursResponse != null &&
            selectedIndicateur != null &&
            isAssocie) {
          // Prendre le premier mois disponible pour calculer le signe
          if (mois.isNotEmpty) {
            final premierMois = mois.first;
            final moisSimple = int.parse(premierMois.substring(4)).toString();
            final indicateursList = indicateursResponse.mois[moisSimple] ?? [];
            final indObj = indicateursList.cast<dynamic>().firstWhere(
                  (i) => i != null && i.indicateur == selectedIndicateur,
                  orElse: () => null,
                );
            if (indObj != null && indObj.formuleText != null) {
              final formuleText = indObj.formuleText;
              if (formuleText.contains('$ind ') ||
                  formuleText.contains('$ind(')) {
                final pattern = RegExp(r'([+-])\s*$ind\s*\(');
                final match = pattern.firstMatch(formuleText);
                if (match != null) {
                  signeLibelle = match.group(1);
                }
              }
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
                width: 110,
                alignment: Alignment.centerLeft,
                child: Text(
                  ind,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 150,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    if (isAssocie && signeLibelle?.isNotEmpty == true)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: signeLibelle == '+'
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
                              color: (signeLibelle == '+'
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
                            signeLibelle == '+' ? Icons.add : Icons.remove,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        libelle ?? ind,
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          // Récupérer les formules pour chaque mois
                          List<Widget> formuleWidgets = [];
                          if (indicateursResponse != null &&
                              indicateursResponse.mois != null) {
                            print(
                                '[DEBUG] indicateursResponse.mois.keys: ${indicateursResponse.mois.keys}');
                            print('[DEBUG] mois list: $mois');
                            for (final mois in mois) {
                              String formuleText = '';
                              String formuleNumeric = '';

                              // Extraire le mois simple (1, 2, 3, etc.) du format YYYYMM
                              final moisSimple = int.parse(mois.substring(4))
                                  .toString(); // Convertit "01" en "1"
                              print(
                                  '[DEBUG] mois: $mois, moisSimple: $moisSimple');

                              final indicateursList =
                                  indicateursResponse.mois[moisSimple] ?? [];
                              print(
                                  '[DEBUG] indicateursList for $moisSimple: ${indicateursList.length} items');

                              final indObj =
                                  indicateursList.cast<dynamic>().firstWhere(
                                        (i) => i != null && i.indicateur == ind,
                                        orElse: () => null,
                                      );
                              if (indObj != null) {
                                formuleText = indObj.formuleText ?? '';
                                formuleNumeric = indObj.formuleNumeric ?? '';
                                print(
                                    '[DEBUG] Found formuleText: $formuleText');
                                print(
                                    '[DEBUG] Found formuleNumeric: $formuleNumeric');
                              } else {
                                print(
                                    '[DEBUG] No indObj found for indicateur: $ind');
                              }
                              formuleWidgets.add(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mois : ' + mois,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Formule (textuelle) : ' +
                                      (formuleText.isNotEmpty
                                          ? formuleText
                                          : '-')),
                                  Text('Formule (numérique) : ' +
                                      (formuleNumeric.isNotEmpty
                                          ? formuleNumeric
                                          : '-')),
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
                                    Text('Indicateur : ' + ind,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 16),
                                    Text('Libellé : ' + (libelle ?? ind),
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
            ...mois.map((m) {
              // Déterminer le signe basé sur la formule de l'indicateur sélectionné
              String? signe;
              if (indicateursResponse != null &&
                  selectedIndicateur != null &&
                  isAssocie) {
                final moisSimple = int.parse(m.substring(4)).toString();
                final indicateursList =
                    indicateursResponse.mois[moisSimple] ?? [];
                final indObj = indicateursList.cast<dynamic>().firstWhere(
                      (i) => i != null && i.indicateur == selectedIndicateur,
                      orElse: () => null,
                    );
                if (indObj != null && indObj.formuleText != null) {
                  // Chercher le signe dans la formule pour cet indicateur dans la ligne actuelle
                  final formuleText = indObj.formuleText;
                  if (formuleText.contains('$ind ') ||
                      formuleText.contains('$ind(')) {
                    // Chercher le signe avant cet indicateur dans la formule
                    final pattern = RegExp(r'([+-])\s*$ind\s*\(');
                    final match = pattern.firstMatch(formuleText);
                    if (match != null) {
                      signe = match.group(1);
                    }
                  }
                }
              }

              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (signe != null)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: signe == '+' ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            signe == '+' ? Icons.add : Icons.remove,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          montants[m]?.format(isKEuros: isKEuros) ?? '0,00 €',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
