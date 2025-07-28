import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';

DataTable getDefaultDataTable(List<DataColumn> columns, List<DataRow> rows) {
  return DataTable(
    headingRowColor: WidgetStateColor.resolveWith(
        (states) => AppColors.black.color.withOpacity(0.05)),
    border:
        TableBorder.all(color: AppColors.blueGreyLight.color.withOpacity(0.3)),
    columns: columns,
    headingRowHeight: 40,
    dataRowMaxHeight: 30,
    dataRowMinHeight: 30,
    rows: rows,
    showCheckboxColumn: false,
    columnSpacing: 12, // Espacement réduit entre les colonnes
  );
}

// Nouvelle fonction pour créer une table responsive
Widget getResponsiveDataTable(List<DataColumn> columns, List<DataRow> rows, {double? minWidth}) {
  final table = DataTable(
    headingRowColor: WidgetStateColor.resolveWith(
        (states) => AppColors.black.color.withOpacity(0.05)),
    border:
        TableBorder.all(color: AppColors.blueGreyLight.color.withOpacity(0.3)),
    columns: columns,
    headingRowHeight: 40,
    dataRowMaxHeight: 30,
    dataRowMinHeight: 30,
    rows: rows,
    showCheckboxColumn: false,
    columnSpacing: 12,
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      // Calcule la largeur minimale nécessaire pour le tableau
      double calculatedMinWidth = minWidth ?? (180 + (columns.length - 1) * 87); // 180 pour la première colonne + 87 par colonne de données
      
      return SizedBox(
        width: calculatedMinWidth,
        child: table,
      );
    },
  );
}

// Fonction pour créer une table avec adaptation automatique de la largeur
Widget getAdaptiveDataTable(List<DataColumn> columns, List<DataRow> rows) {
  final table = DataTable(
    headingRowColor: WidgetStateColor.resolveWith(
        (states) => AppColors.black.color.withOpacity(0.05)),
    border:
        TableBorder.all(color: AppColors.blueGreyLight.color.withOpacity(0.3)),
    columns: columns,
    headingRowHeight: 40,
    dataRowMaxHeight: 30,
    dataRowMinHeight: 30,
    rows: rows,
    showCheckboxColumn: false,
    columnSpacing: 12,
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      // Calcule la largeur minimale nécessaire pour le tableau
      double calculatedMinWidth = 180 + (columns.length - 1) * 87; // 180 pour la première colonne + 87 par colonne de données
      
      // Adapte la largeur en fonction du nombre de colonnes
      return Container(
        width: calculatedMinWidth,
        child: table,
      );
    },
  );
}
