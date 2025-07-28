// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/components/filter_selector.dart';

// class AxeDateSelector extends StatefulWidget {
//   final int startYear;
//   final int startMonth;
//   final Function(int year, int month) onStartDateChange;

//   final int endYear;
//   final int endMonth;
//   final Function(int year, int month) onEndDateChange;
  
//   // Optional callback for axe changes
//   final Function(int axe)? onAxeChanged;

//   final List<int>? availableYears;

//   const AxeDateSelector({
//     super.key,
//     required this.startYear,
//     required this.startMonth,
//     required this.onStartDateChange,
//     required this.endYear,
//     required this.endMonth,
//     required this.onEndDateChange,
//     this.onAxeChanged,
//     this.availableYears,
//   });

//   @override
//   State<AxeDateSelector> createState() => _AxeDateSelectorState();
// }

// class _AxeDateSelectorState extends State<AxeDateSelector> {
//   int selectedAxe = 1;
  
//   // Function to notify parent about axe selection
//   void _onAxeChanged(int? axe) {
//     if (axe != null) {
//       setState(() {
//         selectedAxe = axe;
//       });
//       // Notify parent if callback is provided
//       if (widget.onAxeChanged != null) {
//         widget.onAxeChanged!(axe);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Wrap(
//         spacing: 16,
//         runSpacing: 16,
//         children: [
//           // Période de début - utilise les valeurs du widget
//           _buildDateSelector(
//             "Période de début",
//             widget.startYear,
//             widget.startMonth,
//             widget.onStartDateChange,
//           ),
          
//           // Période de fin - utilise les valeurs du widget
//           _buildDateSelector(
//             "Période de fin",
//             widget.endYear,
//             widget.endMonth,
//             widget.onEndDateChange,
//           ),
          
//           // Sélecteur d'axe
//           FilterSelector<int>(
//             label: 'Axe',
//             value: selectedAxe,
//             width: 150,
//             onChanged: _onAxeChanged,
//             items: const [
//               DropdownMenuItem(
//                 value: 1,
//                 child: Text('Axe 1'),
//               ),
//               DropdownMenuItem(
//                 value: 2,
//                 child: Text('Axe 2'),
//               ),
//               DropdownMenuItem(
//                 value: 3,
//                 child: Text('Axe 3'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDateSelector(String label, int year, int month, Function(int year, int month) onDateChange) {
//     return Container(
//       width: 220,
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.bold, 
//               fontSize: 13, 
//               color: Colors.blueGrey.shade800
//             ),
//           ),
//           SizedBox(height: 8),
//           DateSelector(
//             key: ValueKey('${label}_${year}_$month'),
//             year: year,
//             month: month,
//             onDateChange: onDateChange,
//             availableYears: widget.availableYears,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DateSelector extends StatelessWidget {
//   final int year;
//   final int month;
//   final Function(int year, int month) onDateChange;
//   final List<int>? availableYears;

//   const DateSelector({
//     super.key,
//     required this.year,
//     required this.month,
//     required this.onDateChange,
//     this.availableYears,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey.shade300),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Année (dynamique)
//           DropdownButton<int>(
//             value: year,
//             underline: SizedBox(),
//             icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
//             style: TextStyle(
//               color: Colors.blueGrey.shade700,
//               fontWeight: FontWeight.w500,
//               fontSize: 14,
//             ),
//             onChanged: (value) {
//               onDateChange(value!, month);
//             },
//             items: (availableYears ?? List.generate(DateTime.now().year - 2022 + 1, (i) => 2022 + i)).map((yearValue) {
//               return DropdownMenuItem(
//                 value: yearValue,
//                 child: Text('$yearValue'),
//               );
//             }).toList(),
//           ),
          
//           // Mois
//           DropdownButton<int>(
//             value: month,
//             underline: SizedBox(),
//             icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
//             style: TextStyle(
//               color: Colors.blueGrey.shade700,
//               fontWeight: FontWeight.w500,
//               fontSize: 14,
//             ),
//             onChanged: (value) {
//               onDateChange(year, value!);
//             },
//             items: List.generate(12, (index) {
//               final monthValue = index + 1;
//               return DropdownMenuItem(
//                 value: monthValue,
//                 child: Text(getMonthName(monthValue)),
//               );
//             }),
//           ),
//         ],
//       ),
//     );
//   }
  
//   String getMonthName(int month) {
//     final monthNames = [
//       'Jan', 'Fév', 'Mars', 'Avr', 
//       'Mai', 'Juin', 'Juil', 'Août',
//       'Sept', 'Oct', 'Nov', 'Déc'
//     ];
//     return monthNames[month - 1];
//   }
// }
