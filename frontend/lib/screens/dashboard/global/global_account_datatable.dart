import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class GlobalAccountDataTable extends StatelessWidget {
  final List<dynamic> comptes;
  final Map<String, Map<String, dynamic>> montantsParAnnee;
  final List<String> annees;
  final int total;
  final int currentPage;
  final int pageSize;
  final void Function(int)? onPageChanged;
  final String? selectedCompte;
  final void Function(String)? onSelectCompte;
  final dynamic comptesResponse;
  final bool isKEuros;

  const GlobalAccountDataTable({
    super.key,
    required this.comptes,
    required this.montantsParAnnee,
    required this.annees,
    required this.total,
    required this.currentPage,
    this.pageSize = 50,
    this.onPageChanged,
    this.selectedCompte,
    this.onSelectCompte,
    this.comptesResponse,
    this.isKEuros = false,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, dynamic>> upgradedMontantsParAnnee = {};
    montantsParAnnee.forEach((k, v) {
      upgradedMontantsParAnnee[k] = {};
      v.forEach((an, val) {
        if (val is Map) {
          if (val.containsKey('montant')) {
            upgradedMontantsParAnnee[k]![an] = {
              'montant': val['montant'] ?? 0.0,
              'debit': val['debit'] ?? val['montant'] ?? 0.0,
              'credit': val['credit'] ?? 0.0,
            };
          } else {
            upgradedMontantsParAnnee[k]![an] = {
              'montant': val[an] ?? 0.0,
              'debit': val[an] ?? 0.0,
              'credit': 0.0,
            };
          }
        } else if (val is num) {
          upgradedMontantsParAnnee[k]![an] = {
            'montant': val.toDouble(),
            'debit': val.toDouble(),
            'credit': 0.0,
          };
        } else {
          upgradedMontantsParAnnee[k]![an] = {
            'montant': 0.0,
            'debit': 0.0,
            'credit': 0.0,
          };
        }
      });
    });

    final hasComptes = comptes.isNotEmpty;
    final totalPages = (comptes.length / pageSize).ceil();
    final safeCurrentPage =
        totalPages > 0 ? currentPage.clamp(1, totalPages) : 1;
    final startIndex = (safeCurrentPage - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, comptes.length);
    final displayedComptes =
        hasComptes ? comptes.sublist(startIndex, endIndex) : [];

    return Column(
      children: [
        // Tableau qui prend tout l'espace disponible
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity, // Prend toute la largeur disponible
              child: DataTable(
                showCheckboxColumn: false,
                columnSpacing: 0, // Réduire l'espacement entre colonnes
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 32,
                columns: [
                  DataColumn(
                    label: Container(
                      width: 100,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Compte', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 200,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Libellé',
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.left),
                    ),
                  ),
                  ...annees.map((an) => DataColumn(
                        label: Container(
                          width: 120,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerRight,
                          child: Text(an,
                              style: const TextStyle(fontSize: 13),
                              textAlign: TextAlign.right),
                        ),
                      )),
                ],
                rows: hasComptes
                    ? displayedComptes.map((compte) {
                        final codeCompte = compte.codeCompte?.toString() ?? '';
                        final libelle = compte.libelleCompte?.toString() ?? '';
                        final key = '$codeCompte|$libelle';
                        final isSelected = selectedCompte == codeCompte;
                        final montants = upgradedMontantsParAnnee[key] ?? {};

                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: onSelectCompte != null
                              ? (_) {
                                  // Si la ligne est déjà sélectionnée, on la désélectionne
                                  if (isSelected) {
                                    onSelectCompte!(''); // Passer une chaîne vide pour désélectionner
                                  } else {
                                    onSelectCompte!(codeCompte); // Sinon, sélectionner la ligne
                                  }
                                }
                              : null,
                          color: WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
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
                                width: 100,
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                child: Text(
                                  codeCompte,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      color: Colors.black), // Texte en noir
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 200,
                                padding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        libelle,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w900
                                                : FontWeight.normal,
                                            color:
                                                Colors.black), // Texte en noir
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return AlertDialog(
                                              title: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text('Infos : $codeCompte',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15)),
                                                  const SizedBox(width: 12),
                                                  Text('- Libellé : $libelle',
                                                      style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              content: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 12),
                                                    // Tableau structuré pour un meilleur alignement
                                                    DataTable(
                                                      columnSpacing: 20,
                                                      headingRowHeight: 40,
                                                      dataRowMinHeight: 40,
                                                      dataRowMaxHeight: 40,
                                                      columns: [
                                                        // En-tête avec les années
                                                        ...annees
                                                            .map(
                                                                (an) =>
                                                                    DataColumn(
                                                                      label:
                                                                          Container(
                                                                        width:
                                                                            120,
                                                                        child:
                                                                            Text(
                                                                          an,
                                                                          style: TextStyle(
                                                                              fontSize: 13,
                                                                              fontWeight: FontWeight.bold),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        ),
                                                                      ),
                                                                    ))
                                                            .toList(),
                                                      ],
                                                      rows: [
                                                        // Ligne des montants totaux
                                                        DataRow(
                                                          cells:
                                                              annees.map((an) {
                                                            final anneeData =
                                                                montants[an];
                                                            double montant =
                                                                0.0;
                                                            if (anneeData !=
                                                                    null &&
                                                                anneeData is Map<
                                                                    String,
                                                                    dynamic>) {
                                                              final map =
                                                                  anneeData;
                                                              final montantVal =
                                                                  map['montant'];
                                                              montant = (montantVal is num)
                                                                  ? montantVal
                                                                      .toDouble()
                                                                  : double.tryParse(
                                                                          montantVal?.toString() ??
                                                                              '') ??
                                                                      0.0;
                                                            } else if (anneeData
                                                                is double) {
                                                              montant =
                                                                  anneeData;
                                                            }
                                                            return DataCell(
                                                              Container(
                                                                width: 120,
                                                                child: Text(
                                                                  Currency.format(
                                                                      montant,
                                                                      isKEuros:
                                                                          isKEuros),
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                        // Ligne des crédits et débits
                                                        DataRow(
                                                          cells:
                                                              annees.map((an) {
                                                            final anneeData =
                                                                montants[an];
                                                            double debit = 0.0;
                                                            double credit = 0.0;
                                                            if (anneeData !=
                                                                    null &&
                                                                anneeData is Map<
                                                                    String,
                                                                    dynamic>) {
                                                              final map =
                                                                  anneeData;
                                                              final debitVal =
                                                                  map['debit'];
                                                              final creditVal =
                                                                  map['credit'];
                                                              debit = (debitVal
                                                                      is num)
                                                                  ? debitVal
                                                                      .toDouble()
                                                                  : double.tryParse(
                                                                          debitVal?.toString() ??
                                                                              '') ??
                                                                      0.0;
                                                              credit = (creditVal
                                                                      is num)
                                                                  ? creditVal
                                                                      .toDouble()
                                                                  : double.tryParse(
                                                                          creditVal?.toString() ??
                                                                              '') ??
                                                                      0.0;
                                                            }
                                                            return DataCell(
                                                              Container(
                                                                width: 120,
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Text(
                                                                      'C: ${Currency.format(credit, isKEuros: isKEuros)}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              Colors.green[700]),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                    SizedBox(
                                                                        height:
                                                                            2),
                                                                    Text(
                                                                      'D: ${Currency.format(debit, isKEuros: isKEuros)}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              Colors.red[700]),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Text("Fermer"),
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(Icons.info_outline,
                                          size: 18, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...annees.map((an) {
                              final montant = montants[an]?['montant'] ?? 0.0;
                              return DataCell(
                                Container(
                                  width: 120,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    Currency.format(montant,
                                        isKEuros: isKEuros),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w500,
                                      color: montant < 0
                                          ? Colors.red
                                          : montant > 0
                                              ? Colors.green
                                              : Colors
                                                  .black, // Couleurs vert/rouge
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList()
                    : [
                        DataRow(
                          cells: [
                            DataCell(Text('')),
                            DataCell(Text('')),
                            ...annees.map((_) => DataCell(Text(''))),
                          ],
                        ),
                      ],
              ),
            ),
          ),
        ),

        // Contrôles de pagination
        if (hasComptes && totalPages > 1)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: safeCurrentPage > 1
                      ? () => onPageChanged?.call(safeCurrentPage - 1)
                      : null,
                  icon: Icon(Icons.chevron_left),
                ),
                Text('Page $safeCurrentPage sur $totalPages'),
                IconButton(
                  onPressed: safeCurrentPage < totalPages
                      ? () => onPageChanged?.call(safeCurrentPage + 1)
                      : null,
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
