import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelAccountDataTable extends StatefulWidget {
  final List<NavisionCompteMensuel> comptes;
  final List<String> mois;
  final int? selectedRowIndex;
  final void Function(int)? onRowSelect;
  final Map<String, Map<String, double>> montantsParMois;
  final int total;
  final int currentPage;
  final int pageSize;
  final Function(int page)? onPageChanged;

  MensuelAccountDataTable({
    super.key,
    required this.comptes,
    required this.mois,
    required this.montantsParMois,
    this.selectedRowIndex,
    this.onRowSelect,
    this.total = 0,
    this.currentPage = 0,
    this.pageSize = 50,
    this.onPageChanged,
  });

  @override
  State<MensuelAccountDataTable> createState() => _MensuelAccountDataTableState();
}

class _MensuelAccountDataTableState extends State<MensuelAccountDataTable> {
  @override
  Widget build(BuildContext context) {
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
            child: Text('N° compte', style: TextStyle(fontSize: 13)),
          ),
          numeric: false,
        ),
        DataColumn(
          label: Container(
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text('Libellé', style: TextStyle(fontSize: 13)),
          ),
        ),
        ...widget.mois.map((mois) => DataColumn(
              label: Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: Text(
                  mois,
                  style: TextStyle(fontSize: 13),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
      ],
      rows: widget.comptes.asMap().entries.map((entry) {
        final i = entry.key;
        final compte = entry.value;
        final isSelected = widget.selectedRowIndex == i;
        return DataRow(
          selected: isSelected,
          color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            if (isSelected) return isDarkMode ? Color(0xFF404040) : Colors.grey.shade300;
            if (states.contains(MaterialState.hovered)) return isDarkMode ? Color(0xFF2C2C2C) : Colors.grey.shade200;
            return null;
          }),
          onSelectChanged: widget.onRowSelect != null ? (_) => widget.onRowSelect!(i) : null,
          cells: [
            DataCell(
              Container(
                width: 110,
                alignment: Alignment.centerLeft,
                child: Text(
                  compte.codeCompte,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Color(0xFFE0E0E0) : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 150,
                alignment: Alignment.centerLeft,
                child: Text(
                  compte.libelleCompte,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Color(0xFFE0E0E0) : Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...widget.mois.map((mois) {
              final montant = widget.montantsParMois[compte.codeCompte]?[mois] ?? 0.0;
              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  child: Text(
                    montant.format(),
                    style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Color(0xFFE0E0E0) : Colors.black),
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
