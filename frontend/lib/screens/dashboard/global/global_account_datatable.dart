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
    required Map<String, Map<String, dynamic>> montantsParAnnee,
    required this.annees,
    required this.total,
    required this.currentPage,
    this.pageSize = 50,
    this.onPageChanged,
    this.selectedCompte,
    this.onSelectCompte,
    this.comptesResponse,
    this.isKEuros = false,
  }) : montantsParAnnee = montantsParAnnee;

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

    return SingleChildScrollView(
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 16,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 32,
        columns: [
          const DataColumn(
              label: SizedBox(
                  width: 100,
                  child: Text('Compte', style: TextStyle(fontSize: 13)))),
          DataColumn(
            label: Container(
              width: 150,
              alignment: Alignment.centerLeft,
              child: Text('Libellé',
                  style: TextStyle(fontSize: 13), textAlign: TextAlign.left),
            ),
          ),
          ...annees.map((an) => DataColumn(
                label: Container(
                  width: 120,
                  alignment: Alignment.centerRight,
                  child: Text(an,
                      style: TextStyle(fontSize: 13),
                      textAlign: TextAlign.right),
                ),
              )),
        ],
        rows: hasComptes
            ? comptes.map((compte) {
                final codeCompte = compte.codeCompte?.toString() ?? '';
                final libelle = compte.libelleCompte?.toString() ?? '';
                final key = '$codeCompte|$libelle';
                final isSelected = selectedCompte == codeCompte;
                final montants = upgradedMontantsParAnnee[key] ?? {};

                return DataRow(
                  selected: isSelected,
                  onSelectChanged: onSelectCompte != null
                      ? (_) => onSelectCompte!(codeCompte)
                      : null,
                  color: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
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
                          codeCompte,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
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
                            SizedBox(width: 2),
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
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          SizedBox(width: 12),
                                          Text('- Libellé : $libelle',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: 12),
                                            // Tableau structuré pour un meilleur alignement
                                            DataTable(
                                              columnSpacing: 20,
                                              headingRowHeight: 40,
                                              dataRowHeight: 40,
                                              columns: [
                                                // En-tête avec les années
                                                ...annees
                                                    .map((an) => DataColumn(
                                                          label: Container(
                                                            width: 120,
                                                            child: Text(
                                                              an,
                                                              style: TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                        )),
                                              ],
                                              rows: [
                                                // Ligne des montants totaux
                                                DataRow(
                                                  cells: annees.map((an) {
                                                    final anneeData =
                                                        montants[an];
                                                    double montant = 0.0;
                                                    if (anneeData != null &&
                                                        anneeData is Map<String,
                                                            dynamic>) {
                                                      final map = anneeData;
                                                      final montantVal =
                                                          map['montant'];
                                                      montant = (montantVal
                                                              is num)
                                                          ? montantVal
                                                              .toDouble()
                                                          : double.tryParse(
                                                                  montantVal
                                                                          ?.toString() ??
                                                                      '') ??
                                                              0.0;
                                                    } else if (anneeData
                                                        is double) {
                                                      montant = anneeData;
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
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                                // Ligne des crédits et débits
                                                DataRow(
                                                  cells: annees.map((an) {
                                                    final anneeData =
                                                        montants[an];
                                                    double debit = 0.0;
                                                    double credit = 0.0;
                                                    if (anneeData != null &&
                                                        anneeData is Map<String,
                                                            dynamic>) {
                                                      final map = anneeData;
                                                      final debitVal =
                                                          map['debit'];
                                                      final creditVal =
                                                          map['credit'];
                                                      debit = (debitVal is num)
                                                          ? debitVal.toDouble()
                                                          : double.tryParse(
                                                                  debitVal?.toString() ??
                                                                      '') ??
                                                              0.0;
                                                      credit = (creditVal
                                                              is num)
                                                          ? creditVal.toDouble()
                                                          : double.tryParse(
                                                                  creditVal
                                                                          ?.toString() ??
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
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                          .green[
                                                                      700]),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            SizedBox(height: 2),
                                                            Text(
                                                              'D: ${Currency.format(debit, isKEuros: isKEuros)}',
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                          .red[
                                                                      700]),
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
                                              Navigator.of(context).pop(),
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
                      final anneeData = montants[an];
                      double montant = 0.0;
                      if (anneeData is Map &&
                          anneeData.containsKey('montant')) {
                        final val = anneeData['montant'];
                        montant = (val is num)
                            ? val.toDouble()
                            : double.tryParse(val?.toString() ?? '') ?? 0.0;
                      } else if (anneeData is num) {
                        montant = anneeData.toDouble();
                      }
                      return DataCell(
                        Container(
                          width: 120,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            Currency.format(montant, isKEuros: isKEuros),
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList()
            : [
                DataRow(cells: [
                  DataCell(
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aucun compte à afficher',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const DataCell(Text('')),
                  ...List.generate(
                      annees.length, (index) => const DataCell(Text(''))),
                ])
              ],
      ),
    );
  }
}
