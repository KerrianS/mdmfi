import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> data; // indicateur -> {mois: montant}
  final List<String> mois; // tous les mois à afficher en colonnes (format YYYYMM)
  final String? selectedIndicateur;
  final void Function(String) onSelectIndicateur;
  final dynamic indicateursResponse; // pour accéder aux libellés
  final bool isKEuros; // Paramètre pour affichage en KEuros

  const MensuelIndicateurDataTable({
    super.key,
    required this.data,
    required this.mois,
    required this.selectedIndicateur,
    required this.onSelectIndicateur,
    this.indicateursResponse,
    this.isKEuros = false,
  });

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via le champ associe de l'indicateur sélectionné)
    List<String> associeLibelles = [];
    if (indicateursResponse != null && selectedIndicateur != null) {
      for (final moisEntry in indicateursResponse.mois.entries) {
        final indicateursList = moisEntry.value;
        dynamic indObj = indicateursList.cast<dynamic>().firstWhere(
          (i) => i.indicateur == selectedIndicateur,
          orElse: () => null,
        );
        if (indObj != null && indObj.associe != null && indObj.associe.isNotEmpty) {
          associeLibelles = List<String>.from(indObj.associe);
          break;
        }
      }
    }

    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 12,
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columns: [
        DataColumn(
          label: Container(
            width: 110,
            alignment: Alignment.centerLeft,
            child: Text('Indicateur', style: TextStyle(fontSize: 13)),
          ),
        ),
        DataColumn(
          label: Container(
            width: 150,
            alignment: Alignment.centerLeft,
            child: Text('Libellé', style: TextStyle(fontSize: 13)),
          ),
        ),
        ...mois.map((m) => DataColumn(
          label: Container(
            width: 100,
            alignment: Alignment.centerRight,
            child: Text(m, style: TextStyle(fontSize: 13)),
          ),
        )),
      ],
      rows: data.entries.map((entry) {
        final ind = entry.key;
        final montants = entry.value;
        String? initiales;
        String? libelle;
        if (indicateursResponse != null) {
          for (final moisEntry in indicateursResponse.mois.entries) {
            final indicateursList = moisEntry.value;
            dynamic indicateurObj = indicateursList.cast<dynamic>().firstWhere(
              (i) => i.indicateur == ind,
              orElse: () => null,
            );
            if (indicateurObj != null && indicateurObj.libelle != null && indicateurObj.libelle.isNotEmpty) {
              initiales = indicateurObj.initiales;
              libelle = indicateurObj.libelle;
              break;
            }
          }
        }
        final isSelected = ind == selectedIndicateur;
        final isAssocie = associeLibelles.contains(ind) || (libelle != null && associeLibelles.contains(libelle));
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectIndicateur(ind),
          color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
            if (isAssocie) {
              return Colors.yellow.shade200;
            }
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
                width: 110,
                alignment: Alignment.centerLeft,
                child: Text(
                  ind,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 150,
                alignment: Alignment.centerLeft,
                child: Text(
                  libelle ?? ind,
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...mois.map((m) => DataCell(
              Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: Text(
                  montants[m]?.format(isKEuros: isKEuros) ?? '0,00 €',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )),
          ],
        );
      }).toList(),
    );
  }
}
