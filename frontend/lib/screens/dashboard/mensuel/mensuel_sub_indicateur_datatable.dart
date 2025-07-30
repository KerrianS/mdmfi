import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/utils/currency.dart';

class MensuelSubIndicateurDataTable extends StatelessWidget {
  final Map<String, Map<String, double>>
      sousIndicateurs; // sousIndicateur -> {mois: montant}
  final List<String>
      mois; // tous les mois à afficher en colonnes (format YYYYMM)
  final String? selectedSousIndicateur;
  final void Function(String) onSelectSousIndicateur;
  final dynamic sousIndicsResponse; // Pour accéder aux libellés et initiales
  final dynamic
      indicateursResponse; // Pour accéder au champ formule_text de l'indicateur sélectionné
  final String?
      selectedIndicateur; // Pour savoir quel indicateur est sélectionné
  final bool isKEuros; // Paramètre pour affichage en KEuros

  final Map<String, String> formuleTextParMois; // Formules textuelles par mois

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
    this.formuleTextParMois = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Les associeLibelles sont maintenant passées en paramètre

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
        // Suppression de la fonctionnalité associe
        final isAssocie = false;

        // Déterminer le signe (+/-) pour les sous-indicateurs associés
        String signe = '';
        String? formuleText;
        // Récupérer la formule textuelle de l'indicateur sélectionné pour le mois courant
        if (formuleTextParMois.isNotEmpty && selectedIndicateur != null) {
          // Essayer de trouver la formule pour le mois correspondant
          String? formuleTextFound;

          // Si on a des mois dans la liste, prendre le dernier mois disponible
          if (mois.isNotEmpty) {
            final dernierMois = mois.last;
            final moisSimple = int.parse(dernierMois.substring(4)).toString();
            formuleTextFound = formuleTextParMois[moisSimple];
          }

          // Si pas trouvé, prendre le premier disponible
          if (formuleTextFound == null || formuleTextFound.isEmpty) {
            for (final moisKey in formuleTextParMois.keys) {
              if (formuleTextParMois[moisKey] != null &&
                  formuleTextParMois[moisKey]!.isNotEmpty) {
                formuleTextFound = formuleTextParMois[moisKey];
                break;
              }
            }
          }
          formuleText = formuleTextFound;
          // DEBUG
          print('[DEBUG] formuleText utilisée: ' + (formuleText ?? ''));
          print('[DEBUG] formuleTextParMois keys: ${formuleTextParMois.keys}');
          print('[DEBUG] formuleTextParMois: $formuleTextParMois');
          if (formuleText != null && formuleText.isNotEmpty) {
            // Cherche le signe pour le libellé dans la formule
            final libelleToSearch = libelle ?? sousInd;
            final plusPattern = RegExp(
                r"\+\s*" + RegExp.escape(libelleToSearch) + r"\s*\(",
                caseSensitive: false);
            final minusPattern = RegExp(
                r"-\s*" + RegExp.escape(libelleToSearch) + r"\s*\(",
                caseSensitive: false);
            if (plusPattern.hasMatch(formuleText)) {
              signe = '+';
            } else if (minusPattern.hasMatch(formuleText)) {
              signe = '-';
            }
          }
        }
        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectSousIndicateur(sousInd),
          color: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
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
                    if (isAssocie && signe.isNotEmpty)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: signe == '+'
                                ? [
                                    Color(0xFF4CAF50),
                                    Color(0xFF45A049)
                                  ] // Vert dégradé
                                : [
                                    Color(0xFFF44336),
                                    Color(0xFFD32F2F)
                                  ], // Rouge dégradé
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (signe == '+'
                                      ? Color(0xFF4CAF50)
                                      : Color(0xFFF44336))
                                  .withOpacity(0.4),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            signe == '+' ? Icons.add : Icons.remove,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    SizedBox(width: 4),
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
                          for (final moisEntry
                              in sousIndicsResponse.mois.entries) {
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
                                          Icon(Icons.info_outline,
                                              color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Formule'),
                                        ],
                                      ),
                                      content: Text(formule!),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(),
                                          child: Text('Fermer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Icon(Icons.info_outline,
                                    size: 18, color: Colors.blue),
                              ),
                            );
                          return SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
            ...mois.map((m) {
              // Déterminer le signe pour ce sous-indicateur dans ce mois
              String? signeMois;
              if (isAssocie && formuleText?.isNotEmpty == true) {
                // Chercher le signe dans la formule pour ce sous-indicateur
                final pattern = RegExp(r'([+-])\s*$sousInd\s*\(');
                final match = pattern.firstMatch(formuleText!);
                if (match != null) {
                  signeMois = match.group(1);
                }
              }

              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (signeMois != null)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: signeMois == '+' ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            signeMois == '+' ? Icons.add : Icons.remove,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          montants[m] != null
                              ? montants[m]!.format(isKEuros: isKEuros)
                              : '0,00 €',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Color(0xFFE0E0E0)
                                    : Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
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
