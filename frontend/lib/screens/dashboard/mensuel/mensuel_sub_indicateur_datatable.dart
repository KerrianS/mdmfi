import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelSubIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>> sousIndicateurs; // sousIndicateur -> {mois: montant}
  final List<String> mois; // tous les mois à afficher en colonnes (format YYYYMM)
  final String? selectedSousIndicateur;
  final void Function(String) onSelectSousIndicateur;
  final dynamic sousIndicsResponse; // Pour accéder aux libellés et initiales
  final dynamic indicateursResponse; // Pour accéder au champ associe de l'indicateur sélectionné
  final String? selectedIndicateur; // Pour savoir quel indicateur est sélectionné
  final bool isKEuros; // Paramètre pour affichage en KEuros

  MensuelSubIndicateurDataTable({
    super.key,
    required this.sousIndicateurs,
    required this.mois,
    required this.selectedSousIndicateur,
    required this.onSelectSousIndicateur,
    this.sousIndicsResponse,
    this.indicateursResponse,
    this.selectedIndicateur,
    this.isKEuros = false,
  });

  @override
  Widget build(BuildContext context) {
    // Récupérer la liste des libellés associés à l'indicateur sélectionné (via le champ associe de l'indicateur sélectionné)
    List<String> associeLibelles = [];
    if (indicateursResponse != null && selectedIndicateur != null) {
      for (final moisEntry in indicateursResponse.mois.entries) {
        final indicateursList = moisEntry.value;
        final indObj = indicateursList.firstWhere(
          (i) => i.indicateur == selectedIndicateur,
          orElse: () => NavisionIndicateurMensuel(
            indicateur: '',
            libelle: '',
            initiales: '',
            valeur: 0.0,
            associe: [],
          ),
        );
        if (indObj.associe.isNotEmpty) {
          associeLibelles = indObj.associe;
          break;
        }
      }
    }

    return DataTable(
      showCheckboxColumn: false,
      columnSpacing: 16,
      headingRowHeight: 32,
      dataRowMinHeight: 28,
      dataRowMaxHeight: 32,
      columns: [
        DataColumn(
          label: Container(
            width: 100,
            alignment: Alignment.centerLeft,
            child: Text('Sous-indicateur', style: TextStyle(fontSize: 13)),
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
      rows: sousIndicateurs.entries.map((entry) {
        final sousInd = entry.key;
        final montants = entry.value;
        // Récupérer les initiales et le libellé
        String? initiales;
        String? libelle;
        if (sousIndicsResponse != null) {
          for (final moisEntry in sousIndicsResponse.mois.entries) {
            final sousIndicateursList = moisEntry.value.values
                .where((v) => v is List)
                .expand((list) => list as List)
                .where((s) => s.sousIndicateur == sousInd)
                .toList();
            if (sousIndicateursList.isNotEmpty) {
              initiales = sousIndicateursList.first.initiales;
              libelle = sousIndicateursList.first.libelle;
              break;
            }
          }
        }
        final isSelected = sousInd == selectedSousIndicateur;
        // Jaune si le libellé du sous-indicateur est dans la liste associe de l'indicateur sélectionné
        final isAssocie = associeLibelles.contains(libelle ?? sousInd);
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectSousIndicateur(sousInd),
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
                width: 100,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  initiales ?? sousInd,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFFE0E0E0)
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 155,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        libelle ?? sousInd,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (sousIndicsResponse != null)
                      Builder(
                        builder: (context) {
                          String? formule;
                          for (final moisEntry in sousIndicsResponse.mois.entries) {
                            final sousIndicateursList = moisEntry.value.values
                                .where((v) => v is List)
                                .expand((list) => list as List)
                                .where((s) => s.sousIndicateur == sousInd)
                                .toList();
                            if (sousIndicateursList.isNotEmpty) {
                              formule = sousIndicateursList.first.formule;
                              break;
                            }
                          }
                          if (formule != null && formule.isNotEmpty)
                            return Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Formule'),
                                        ],
                                      ),
                                      content: Text(formule!),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: Text('Fermer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Icon(Icons.info_outline, size: 18, color: Colors.blue),
                              ),
                            );
                          return SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
            ...mois.map((m) => DataCell(
              Container(
                width: 100,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  montants[m] != null
                      ? montants[m]!.format(isKEuros: isKEuros)
                      : '0,00 €',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFFE0E0E0)
                        : Colors.black,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            )),
          ],
        );
      }).toList(),
    );
  }
}
