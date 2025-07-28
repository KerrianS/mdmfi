// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/components/table_header.dart';
// import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';
// import 'package:mobaitec_decision_making/models/IndicateurGlobal.dart';
// import 'package:mobaitec_decision_making/screens/dashboard/axe/axe_account_datatable.dart';
// import 'package:mobaitec_decision_making/screens/dashboard/axe/axe_date_selector.dart';
// import 'package:mobaitec_decision_making/screens/dashboard/axe/axe_indicateur_datatable.dart';
// import 'package:mobaitec_decision_making/screens/dashboard/axe/axe_sub_indicateur_datatable.dart';
// import 'package:mobaitec_decision_making/utils/colors.dart';

// class Axe extends StatefulWidget {
//   @override
//   State<Axe> createState() => _AxeState();
// }

// class _AxeState extends State<Axe> {
//   IndicateurGlobal? selectedIndicateur;
//   int selectedAxe = 1;

//   @override
//   void initState() {
//     super.initState();
//     // Optionnel : charger les indicateurs si besoin
//   }

//   void _selectIndicateur(IndicateurGlobal indicateur) {
//     setState(() {
//       selectedIndicateur = indicateur;
//     });
//   }

//   void _onAxeChanged(int axe) {
//     setState(() {
//       selectedAxe = axe;
//       selectedIndicateur = null;
//     });
//   }

//   Widget _buildTableHeader(String title) {
//     return TableHeader(title: title);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final indicateurs = CacheIndicateurService().getIndicateurs();
//     final comptes = selectedIndicateur?.comptes ?? [];
//     return Expanded(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Section d'information
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             child: Text(
//               'Sélectionner une ligne pour obtenir les détails',
//               style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey.shade700),
//             ),
//           ),
//           // Section des tableaux de données
//           Expanded(
//             child: Column(
//               children: [
//                 // Tableau des indicateurs
//                 Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.all(8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         _buildTableHeader('Indicateurs'),
//                         Expanded(
//                           child: AdaptiveTableContainer(
//                             child: AxeIndicateurDataTable(
//                               indicateurs: indicateurs,
//                               selectedIndicateur: selectedIndicateur,
//                               selectIndicateur: _selectIndicateur,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Tableau des sous-indicateurs (sous-classes)
//                 Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.all(8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         _buildTableHeader('Détails'),
//                         Expanded(
//                           child: AdaptiveTableContainer(
//                             child: AxeSubIndicateurDataTable(
//                               comptes: comptes,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Tableau des comptes
//                 Expanded(
//                   child: Padding(
//                     padding: EdgeInsets.all(8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         _buildTableHeader('Détails des comptes'),
//                         Expanded(
//                           child: AdaptiveTableContainer(
//                             child: AxeAccountDataTable(
//                               comptes: comptes,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
