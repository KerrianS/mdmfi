import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelAccountDataTable extends StatefulWidget {
  final List<dynamic> comptes;
  final List<String> mois;
  final int? selectedRowIndex;
  final void Function(int)? onRowSelect;
  final Map<String, Map<String, double>> montantsParMois;
  final Map<String, String>? formuleTextParMois; // Ajout pour le surlignage
  final bool isKEuros; // Ajout pour l'affichage en KEuros

  const MensuelAccountDataTable({
    super.key,
    required this.comptes,
    required this.mois,
    required this.montantsParMois,
    this.selectedRowIndex,
    this.onRowSelect,
    this.formuleTextParMois,
    this.isKEuros = false,
  });

  @override
  State<MensuelAccountDataTable> createState() =>
      _MensuelAccountDataTableState();
}

class _MensuelAccountDataTableState extends State<MensuelAccountDataTable> {
  @override
  Widget build(BuildContext context) {
    // Fonction pour vérifier si un compte est associé à l'indicateur sélectionné
    bool isCompteAssocie(String codeCompte, String libelleCompte) {
      if (widget.formuleTextParMois == null) return false;

      for (final formuleText in widget.formuleTextParMois!.values) {
        if (formuleText.contains(codeCompte) ||
            formuleText.contains(libelleCompte)) {
          return true;
        }
      }
      return false;
    }

    return DataTable(
      columnSpacing: 12,
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columns: [
        DataColumn(
          label: Container(
            width: 110,
            alignment: Alignment.centerLeft,
            child: const Text('N° compte', style: TextStyle(fontSize: 13)),
          ),
          numeric: false,
        ),
        DataColumn(
          label: Container(
            width: 150,
            alignment: Alignment.centerLeft,
            child: const Text('Libellé', style: TextStyle(fontSize: 13)),
          ),
        ),
        ...widget.mois.map((mois) => DataColumn(
              label: Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: Text(
                  mois,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
      ],
      rows: widget.comptes.asMap().entries.map((entry) {
        final i = entry.key;
        final compte = entry.value as Map<String, dynamic>;
        final codeCompte = compte['codeCompte'] as String? ?? '';
        final libelleCompte = compte['libelleCompte'] as String? ?? '';
        final isSelected = widget.selectedRowIndex == i;
        final isAssocie = isCompteAssocie(codeCompte, libelleCompte);

        return DataRow(
          selected: isSelected,
          color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            if (isAssocie) {
              return Colors.grey.shade300;
            }
            if (isSelected) return Colors.yellow.shade200;
            if (states.contains(WidgetState.hovered))
              return isDarkMode
                  ? const Color(0xFF2C2C2C)
                  : Colors.grey.shade200;
            return null;
          }),
          onSelectChanged:
              widget.onRowSelect != null ? (_) => widget.onRowSelect!(i) : null,
          cells: [
            DataCell(
              Container(
                width: 110,
                alignment: Alignment.centerLeft,
                child: Text(
                  codeCompte,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE0E0E0)
                        : Colors.black,
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
                        libelleCompte,
                        style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Infos : $codeCompte',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(width: 12),
                                  Text('- Libellé : $libelleCompte',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              content: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    // Tableau structuré pour un meilleur alignement
                                    DataTable(
                                      columnSpacing: 20,
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 40,
                                      dataRowMaxHeight: 40,
                                      columns: [
                                        // En-tête avec les mois
                                        ...widget.mois.map((mois) => DataColumn(
                                              label: Container(
                                                width: 120,
                                                child: Text(
                                                  mois,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            )),
                                      ],
                                      rows: [
                                        // Ligne des montants totaux
                                        DataRow(
                                          cells: widget.mois.map((mois) {
                                            final montant =
                                                widget.montantsParMois[
                                                        codeCompte]?[mois] ??
                                                    0.0;
                                            return DataCell(
                                              Container(
                                                width: 120,
                                                child: Text(
                                                  Currency.format(montant,
                                                      isKEuros:
                                                          widget.isKEuros),
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: montant < 0
                                                          ? Colors.red[700]
                                                          : montant > 0
                                                              ? Colors
                                                                  .green[700]
                                                              : Colors.black),
                                                  textAlign: TextAlign.center,
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Fermer"),
                                )
                              ],
                            );
                          },
                        );
                      },
                      child: const Icon(Icons.info_outline,
                          size: 18, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            ...widget.mois.map((mois) {
              final montant = widget.montantsParMois[codeCompte]?[mois] ?? 0.0;
              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Currency.format(montant, isKEuros: widget.isKEuros),
                    style: TextStyle(
                        fontSize: 13,
                        color: montant < 0
                            ? Colors.red[700]
                            : montant > 0
                                ? Colors.green[700]
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black)),
                    textAlign: TextAlign.right,
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
