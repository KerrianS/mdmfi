import 'package:flutter/material.dart';
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

  const MensuelSubIndicateurDataTable({
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

  // Fonction pour vérifier si un sous-indicateur est associé à la formule
  bool isSousIndicateurAssocie(String sousInd, String? libelle) {
    if (formuleTextParMois.isEmpty) return false;

    for (final formuleText in formuleTextParMois.values) {
      if (formuleText.contains(sousInd) ||
          (libelle != null && formuleText.contains(libelle))) {
        return true;
      }
    }
    return false;
  }

  // Fonction pour déterminer le signe d'un sous-indicateur
  String getSigneSousIndicateur(String sousInd, String? libelle) {
    if (formuleTextParMois.isEmpty) return '+'; // Par défaut positif

    final libelleToSearch = libelle ?? sousInd;

    // Debug: afficher la formule pour comprendre le format
    print('[DEBUG] Recherche pour: $libelleToSearch');
    print('[DEBUG] Formules disponibles: $formuleTextParMois');

    // Chercher le signe dans toutes les formules disponibles
    for (final formuleText in formuleTextParMois.values) {
      if (formuleText.isNotEmpty) {
        print('[DEBUG] Vérification formule: $formuleText');

        // Chercher avec le libellé
        if (formuleText.contains('-$libelleToSearch')) {
          print('[DEBUG] Signe négatif détecté pour $libelleToSearch');
          return '-';
        } else if (formuleText.contains('+$libelleToSearch')) {
          print('[DEBUG] Signe positif détecté pour $libelleToSearch');
          return '+';
        }

        // Chercher avec le code du sous-indicateur
        if (formuleText.contains('-$sousInd')) {
          print('[DEBUG] Signe négatif détecté pour $sousInd');
          return '-';
        } else if (formuleText.contains('+$sousInd')) {
          print('[DEBUG] Signe positif détecté pour $sousInd');
          return '+';
        }

        // Chercher avec des espaces autour du signe
        if (formuleText.contains(' - $libelleToSearch') ||
            formuleText.contains(' - $sousInd')) {
          print(
              '[DEBUG] Signe négatif détecté (avec espaces) pour $libelleToSearch');
          return '-';
        } else if (formuleText.contains(' + $libelleToSearch') ||
            formuleText.contains(' + $sousInd')) {
          print(
              '[DEBUG] Signe positif détecté (avec espaces) pour $libelleToSearch');
          return '+';
        }
      }
    }

    print('[DEBUG] Aucun signe détecté pour $libelleToSearch, défaut: +');
    return '+'; // Par défaut positif si aucun signe détecté
  }

  @override
  Widget build(BuildContext context) {
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
            child:
                const Text('Sous-indicateur', style: TextStyle(fontSize: 13)),
          ),
        ),
        DataColumn(
          label: Container(
            width: 150,
            alignment: Alignment.centerLeft,
            child: const Text('Libellé', style: TextStyle(fontSize: 13)),
          ),
        ),
        ...mois.map((m) => DataColumn(
              label: Container(
                width: 100,
                alignment: Alignment.centerRight,
                child: Text(m, style: const TextStyle(fontSize: 13)),
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
          final mois = sousIndicsResponse!['mois'] as Map<String, dynamic>?;
          if (mois != null) {
            for (final moisEntry in mois.entries) {
              final indicateurs = moisEntry.value as Map<String, dynamic>?;
              if (indicateurs != null) {
                for (final indicateurEntry in indicateurs.entries) {
                  final sousIndicateursList =
                      indicateurEntry.value as List<dynamic>? ?? [];
                  for (final sousIndicateur in sousIndicateursList) {
                    final sousIndicateurName =
                        sousIndicateur['sousIndicateur'] as String?;
                    if (sousIndicateurName == sousInd) {
                      initiales = sousIndicateur['initiales'] as String?;
                      libelle = sousIndicateur['libelle'] as String?;
                      break;
                    }
                  }
                  if (initiales != null || libelle != null) break;
                }
              }
              if (initiales != null || libelle != null) break;
            }
          }
        }
        final isSelected = sousInd == selectedSousIndicateur;

        // Vérifier si le sous-indicateur est associé à la formule
        final isAssocie = isSousIndicateurAssocie(sousInd, libelle);

        // Déterminer le signe (+/-) pour les sous-indicateurs associés
        final signe = isAssocie ? getSigneSousIndicateur(sousInd, libelle) : '';

        return DataRow(
          selected: isSelected,
          onSelectChanged: (_) => onSelectSousIndicateur(sousInd),
          color: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (isAssocie) {
              return Colors.yellow.shade200;
            }
            if (isSelected) {
              return Colors.grey.shade300;
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.grey.withOpacity(0.1);
            }
            return null;
          }),
          cells: [
            DataCell(
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  initiales ?? sousInd,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFE0E0E0)
                        : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Container(
                width: 155,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        libelle ?? sousInd,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isAssocie)
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
                            size: 13,
                          ),
                        ),
                      ),
                    if (sousIndicsResponse != null)
                      Builder(
                        builder: (context) {
                          String? formule;
                          final mois = sousIndicsResponse!['mois']
                              as Map<String, dynamic>?;
                          if (mois != null) {
                            for (final moisEntry in mois.entries) {
                              final indicateurs =
                                  moisEntry.value as Map<String, dynamic>?;
                              if (indicateurs != null) {
                                for (final indicateurEntry
                                    in indicateurs.entries) {
                                  final sousIndicateursList =
                                      indicateurEntry.value as List<dynamic>? ??
                                          [];
                                  for (final sousIndicateur
                                      in sousIndicateursList) {
                                    final sousIndicateurName =
                                        sousIndicateur['sousIndicateur']
                                            as String?;
                                    if (sousIndicateurName == sousInd) {
                                      formule =
                                          sousIndicateur['formule'] as String?;
                                      break;
                                    }
                                  }
                                  if (formule != null) break;
                                }
                              }
                              if (formule != null) break;
                            }
                          }
                          if (formule != null && formule.isNotEmpty)
                            return const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.info_outline,
                                  size: 18, color: Colors.blue),
                            );
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
            ...mois.map((m) {
              return DataCell(
                Container(
                  width: 100,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    montants[m] != null
                        ? Currency.format(montants[m]!, isKEuros: isKEuros)
                        : '0,00 €',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE0E0E0)
                          : Colors.black,
                    ),
                    textAlign: TextAlign.right,
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
