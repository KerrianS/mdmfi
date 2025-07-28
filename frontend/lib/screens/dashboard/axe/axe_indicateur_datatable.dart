// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';

// class AxeIndicateurDataTable extends StatelessWidget {
//   final List<NavisionSIGCompte> comptes;
//   final void Function(String) selectIndicateur;
//   final String? selectedIndicateur;

//   AxeIndicateurDataTable({
//     super.key,
//     required this.comptes,
//     required this.selectIndicateur,
//     required this.selectedIndicateur,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Regrouper par indicateur
//     final Map<String, List<NavisionSIGCompte>> comptesParIndicateur = {};
//     for (var compte in comptes) {
//       comptesParIndicateur.putIfAbsent(compte.indicateur, () => []).add(compte);
//     }
//     return DataTable(
//       columns: [
//         DataColumn(label: Text('Indicateur')),
//         DataColumn(label: Text('Total Montant')),
//         DataColumn(label: Text('Total Débit')),
//         DataColumn(label: Text('Total Crédit')),
//       ],
//       rows: comptesParIndicateur.entries.map((entry) {
//         final indicateur = entry.key;
//         final comptes = entry.value;
//         final totalMontant = comptes.fold(0.0, (sum, c) => sum + c.montant);
//         final totalDebit = comptes.fold(0.0, (sum, c) => sum + c.debit);
//         final totalCredit = comptes.fold(0.0, (sum, c) => sum + c.credit);
//         final isSelected = selectedIndicateur == indicateur;
//         return DataRow(
//           selected: isSelected,
//           onSelectChanged: (_) => selectIndicateur(indicateur),
//           cells: [
//             DataCell(Text(indicateur)),
//             DataCell(Text(totalMontant.toStringAsFixed(2))),
//             DataCell(Text(totalDebit.toStringAsFixed(2))),
//             DataCell(Text(totalCredit.toStringAsFixed(2))),
//           ],
//         );
//       }).toList(),
//     );
//   }
// }
