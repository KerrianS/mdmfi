import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';
import 'package:mobaitec_decision_making/utils/montants_par_annee_builder.dart';

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
    required this.pageSize,
    this.onPageChanged,
    this.selectedCompte,
    this.onSelectCompte,
    this.comptesResponse,
    this.isKEuros = false,
  }) : montantsParAnnee = montantsParAnnee;

  factory GlobalAccountDataTable.fromPayload({
    required List<dynamic> comptes,
    required Map<String, dynamic> payload,
    required List<String> annees,
    required int total,
    required int currentPage,
    required int pageSize,
    void Function(int)? onPageChanged,
    String? selectedCompte,
    void Function(String)? onSelectCompte,
    dynamic comptesResponse,
    bool isKEuros = false,
  }) {
    final montantsParAnnee = buildMontantsParAnnee(payload);
    return GlobalAccountDataTable(
      comptes: comptes,
      montantsParAnnee: montantsParAnnee,
      annees: annees,
      total: total,
      currentPage: currentPage,
      pageSize: pageSize,
      onPageChanged: onPageChanged,
      selectedCompte: selectedCompte,
      onSelectCompte: onSelectCompte,
      comptesResponse: comptesResponse,
      isKEuros: isKEuros,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] comptes.length = \'${comptes.length}\'' + (comptes.isNotEmpty ? ', premier: \'${comptes.first}\'' : ''));

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
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTable(
                showCheckboxColumn: false,
                columnSpacing: 12,
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 32,
                columns: [
                  DataColumn(
                    label: Container(
                      width: 120,
                      child: Text('Compte', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      width: 220,
                      child: Text('Libellé', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  ...annees.map((an) => DataColumn(
                        label: Text(an, style: TextStyle(fontSize: 13)),
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
                          onSelectChanged: onSelectCompte != null ? (_) => onSelectCompte!(codeCompte) : null,
                          color: MaterialStateProperty.all(
                            isSelected ? Colors.grey.shade300 : null,
                          ),
                          cells: [
                            DataCell(
                              Container(
                                width: 120,
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  codeCompte,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                width: 220,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        libelle,
                                        style: TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.info_outline, size: 20, color: Color(0xFF00A9CA)),
                                      tooltip: "Détails du compte",
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) {
                                            return AlertDialog(
                                              title: Text('Détails du compte $codeCompte'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Formule : Débit - crédit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                  SizedBox(height: 8),
                                                  ...annees.map((an) {
                                                    final anneeData = montants[an];
                                                    double montant = 0.0;
                                                    double debit = 0.0;
                                                    double credit = 0.0;
                                                    if (anneeData != null && anneeData is Map<String, dynamic>) {
                                                      final map = anneeData;
                                                      final montantVal = map['montant'];
                                                      final debitVal = map['debit'];
                                                      final creditVal = map['credit'];
                                                      montant = (montantVal is num)
                                                          ? montantVal.toDouble()
                                                          : double.tryParse(montantVal?.toString() ?? '') ?? 0.0;
                                                      debit = (debitVal is num)
                                                          ? debitVal.toDouble()
                                                          : double.tryParse(debitVal?.toString() ?? '') ?? 0.0;
                                                      credit = (creditVal is num)
                                                          ? creditVal.toDouble()
                                                          : double.tryParse(creditVal?.toString() ?? '') ?? 0.0;
                                                    } else if (anneeData is double) {
                                                      montant = anneeData;
                                                    }
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      child: Text(
                                                        '$an : ${Currency.format(debit, isKEuros: isKEuros)} - ${Currency.format(credit, isKEuros: isKEuros)} = ${Currency.format(montant, isKEuros: isKEuros)}',
                                                        style: TextStyle(fontSize: 13),
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text("Fermer"),
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...annees.map((an) {
                              final anneeData = montants[an];
                              double montant = 0.0;
                              if (anneeData is Map && anneeData.containsKey('montant')) {
                                final val = anneeData['montant'];
                                montant = (val is num) ? val.toDouble() : double.tryParse(val?.toString() ?? '') ?? 0.0;
                              } else if (anneeData is num) {
                                montant = anneeData.toDouble();
                              }
                              return DataCell(
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    Currency.format(montant, isKEuros: isKEuros),
                                    style: TextStyle(fontSize: 12),
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
                              child: Text('Aucun compte à afficher', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          ...List.generate(1 + annees.length, (index) => const DataCell(Text(''))),
                        ])
                      ],
              ),
              SizedBox(height: 12),
              if (total > pageSize)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: currentPage > 0 && onPageChanged != null
                          ? () => onPageChanged!(currentPage - 1)
                          : null,
                    ),
                    Text('Page ${currentPage + 1} / ${((total - 1) ~/ pageSize) + 1}', style: TextStyle(fontSize: 13)),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: (currentPage + 1) * pageSize < total && onPageChanged != null
                          ? () => onPageChanged!(currentPage + 1)
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
