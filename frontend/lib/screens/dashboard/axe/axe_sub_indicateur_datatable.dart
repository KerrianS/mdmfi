// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';

// class AxeSubIndicateurDataTable extends StatelessWidget {
//   final List<NavisionSIGCompte> comptes;

//   AxeSubIndicateurDataTable({super.key, required this.comptes});

//   @override
//   Widget build(BuildContext context) {
//     // Regrouper par sous-classe (sss_classe)
//     final Map<String, List<NavisionSIGCompte>> comptesParSousClasse = {};
//     for (var compte in comptes) {
//       comptesParSousClasse.putIfAbsent(compte.sss_classe ?? '', () => []).add(compte);
//     }
//     return DataTable(
//       columns: [
//         DataColumn(label: Text('Sous-classe')),
//         DataColumn(label: Text('Total Montant')),
//         DataColumn(label: Text('Total Débit')),
//         DataColumn(label: Text('Total Crédit')),
//       ],
//       rows: comptesParSousClasse.entries.map((entry) {
//         final sclasse = entry.key;
//         final comptes = entry.value;
//         final totalMontant = comptes.fold(0.0, (sum, c) => sum + c.montant);
//         final totalDebit = comptes.fold(0.0, (sum, c) => sum + c.debit);
//         final totalCredit = comptes.fold(0.0, (sum, c) => sum + c.credit);
//         return DataRow(
//           cells: [
//             DataCell(Text(sclasse)),
//             DataCell(Text(totalMontant.toStringAsFixed(2))),
//             DataCell(Text(totalDebit.toStringAsFixed(2))),
//             DataCell(Text(totalCredit.toStringAsFixed(2))),
//           ],
//         );
//       }).toList(),
//     );
//   }
// }
