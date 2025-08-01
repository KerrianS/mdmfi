import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data; // indicateur -> {mois: montant}
  final List<String>
      mois; // tous les mois à afficher en colonnes (format YYYYMM)
  final String? selectedIndicateur;
  final void Function(String) onSelectIndicateur;
  final dynamic indicateursResponse; // pour accéder aux libellés
  final bool isKEuros; // Paramètre pour affichage en KEuros
  final Map<String, String> formuleTextParMois; // Formules textuelles par mois

  const MensuelIndicateurDataTable({
    super.key,
    required this.data,
    required this.mois,
    required this.selectedIndicateur,
    required this.onSelectIndicateur,
    this.indicateursResponse,
    this.isKEuros = false,
    this.formuleTextParMois = const {},
  });

  // Fonction pour déterminer le signe d'un indicateur
  String getSigneIndicateur(String ind, String? libelle) {
    if (formuleTextParMois.isEmpty) return '+'; // Par défaut positif

    final libelleToSearch = libelle ?? ind;

    // Debug: afficher la formule pour comprendre le format
    print('[DEBUG] Recherche signe indicateur pour: $libelleToSearch');
    print('[DEBUG] Formules disponibles: $formuleTextParMois');

    // Chercher le signe dans toutes les formules disponibles
    for (final formuleText in formuleTextParMois.values) {
      if (formuleText.isNotEmpty) {
        print('[DEBUG] Vérification formule indicateur: $formuleText');

        // Chercher avec le libellé
        if (formuleText.contains('-$libelleToSearch')) {
          print(
              '[DEBUG] Signe négatif détecté pour indicateur $libelleToSearch');
          return '-';
        } else if (formuleText.contains('+$libelleToSearch')) {
          print(
              '[DEBUG] Signe positif détecté pour indicateur $libelleToSearch');
          return '+';
        }

        // Chercher avec le code de l'indicateur
        if (formuleText.contains('-$ind')) {
          print('[DEBUG] Signe négatif détecté pour indicateur $ind');
          return '-';
        } else if (formuleText.contains('+$ind')) {
          print('[DEBUG] Signe positif détecté pour indicateur $ind');
          return '+';
        }

        // Chercher avec des espaces autour du signe
        if (formuleText.contains(' - $libelleToSearch') ||
            formuleText.contains(' - $ind')) {
          print(
              '[DEBUG] Signe négatif détecté (avec espaces) pour indicateur $libelleToSearch');
          return '-';
        } else if (formuleText.contains(' + $libelleToSearch') ||
            formuleText.contains(' + $ind')) {
          print(
              '[DEBUG] Signe positif détecté (avec espaces) pour indicateur $libelleToSearch');
          return '+';
        }
      }
    }

    print(
        '[DEBUG] Aucun signe détecté pour indicateur $libelleToSearch, défaut: +');
    return '+'; // Par défaut positif si aucun signe détecté
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via formule_text)
    List<String> associeLibelles = [];
    if (indicateursResponse != null && selectedIndicateur != null) {
      final moisData = indicateursResponse!['mois'] as Map<String, dynamic>?;
      if (moisData != null) {
        for (final moisEntry in moisData.entries) {
          final indicateursList = moisEntry.value as List<dynamic>?;
          if (indicateursList != null) {
            dynamic indObj = indicateursList.cast<dynamic>().firstWhere(
                  (i) => i['indicateur'] == selectedIndicateur,
                  orElse: () => null,
                );
            if (indObj != null &&
                indObj['formuleText'] != null &&
                indObj['formuleText'].isNotEmpty) {
              // Extraire les sous-indicateurs depuis formule_text
              final Set<String> sousIndicateursTrouves = {};
              final pattern =
                  RegExp(r'([A-Z][A-Z\sÉÈÊËÀÂÄÔÙÛÜÇ]+)\s*\([^)]+\)');
              final matches = pattern.allMatches(indObj['formuleText']);

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
      }
    }

    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 16,
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
        String? libelle;
        if (indicateursResponse != null) {
          final moisData =
              indicateursResponse!['mois'] as Map<String, dynamic>?;
          if (moisData != null) {
            for (final moisEntry in moisData.entries) {
              final indicateursList = moisEntry.value as List<dynamic>?;
              if (indicateursList != null) {
                dynamic indicateurObj =
                    indicateursList.cast<dynamic>().firstWhere(
                          (i) => i['indicateur'] == ind,
                          orElse: () => null,
                        );
                if (indicateurObj != null &&
                    indicateurObj['libelle'] != null &&
                    indicateurObj['libelle'].isNotEmpty) {
                  libelle = indicateurObj['libelle'];
                  break;
                }
              }
            }
          }
        }
        final isSelected = ind == selectedIndicateur;
        final isAssocie = associeLibelles.contains(ind) ||
            (libelle != null && associeLibelles.contains(libelle));

        // Calculer le signe pour la colonne libellé
        String? signeLibelle;
        if (isAssocie) {
          signeLibelle = getSigneIndicateur(ind, libelle);
        }

        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) {
            // Si la ligne est déjà sélectionnée, on la désélectionne
            if (isSelected) {
              onSelectIndicateur(
                  ''); // Passer une chaîne vide pour désélectionner
            } else {
              onSelectIndicateur(ind); // Sinon, sélectionner la ligne
            }
          },
          color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (isAssocie) {
              return Colors.grey.shade300;
            }
            if (isSelected) {
              return Colors.yellow.shade200;
            }
            if (states.contains(WidgetState.hovered)) {
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  ),
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
                    Expanded(
                      child: Text(
                        libelle ?? ind,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAssocie)
                      Container(
                        width: 17,
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
                            size: 13,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          // Récupérer les formules pour chaque mois
                          List<Widget> formuleWidgets = [];
                          if (indicateursResponse != null) {
                            final moisData = indicateursResponse!['mois']
                                as Map<String, dynamic>?;
                            if (moisData != null) {
                              print(
                                  '[DEBUG] indicateursResponse.mois.keys: ${moisData.keys}');
                              print('[DEBUG] mois list: $mois');
                              for (final moisItem in mois) {
                                String formuleText = '';
                                String formuleNumeric = '';

                                // Extraire le mois simple (1, 2, 3, etc.) du format YYYYMM
                                final moisSimple =
                                    int.parse(moisItem.substring(4))
                                        .toString(); // Convertit "01" en "1"
                                print(
                                    '[DEBUG] mois: $moisItem, moisSimple: $moisSimple');

                                final indicateursList =
                                    moisData[moisSimple] as List<dynamic>? ??
                                        [];
                                print(
                                    '[DEBUG] indicateursList for $moisSimple: ${indicateursList.length} items');

                                final indObj = indicateursList
                                    .cast<dynamic>()
                                    .firstWhere(
                                      (i) =>
                                          i != null && i['indicateur'] == ind,
                                      orElse: () => null,
                                    );
                                if (indObj != null) {
                                  formuleText = indObj['formuleText'] ?? '';
                                  formuleNumeric =
                                      indObj['formuleNumeric'] ?? '';
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
                                    Text('Mois : ' + moisItem,
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
              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    montants[m]?.format(isKEuros: isKEuros) ?? '0,00 €',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
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
