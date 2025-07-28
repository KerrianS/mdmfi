// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';

// class AxeAccountDataTable extends StatelessWidget {
//   final List<NavisionSIGCompte> comptes;
//   final List<String> annees;

//   AxeAccountDataTable({super.key, required this.comptes, required this.annees});

//   @override
//   Widget build(BuildContext context) {
//     return DataTable(
//       columns: [
//         DataColumn(label: Text('N° compte')),
//         DataColumn(label: Text('Libellé du compte')),
//         ...annees.map((an) => DataColumn(label: Text(an))),
//       ],
//       rows: comptes.map((compte) {
//         return DataRow(
//           cells: [
//             DataCell(Text(compte.codeCompte)),
//             DataCell(Text(compte.libelleCompte)),
//             ...annees.map((an) {
//               // On affiche le montant du compte pour l'année an
//               final montant = (compte.annee.toString() == an) ? compte.montant : 0.0;
//               return DataCell(Text(montant.toStringAsFixed(2)));
//             }),
//           ],
//         );
//       }).toList(),
//     );
//   }
// }
