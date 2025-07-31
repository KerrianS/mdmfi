import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:mobaitec_decision_making/services/data/unified_sig_service.dart';
import 'package:mobaitec_decision_making/screens/dashboard/global/global_account_datatable.dart';
import 'package:mobaitec_decision_making/screens/dashboard/global/global_indicateur_datatable.dart';
import 'package:mobaitec_decision_making/screens/dashboard/global/global_sub_indicateur_datatable.dart';
import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';

class Global extends StatefulWidget {
  static String lastSelectedPeriode = 'Année civile';
  @override
  State<Global> createState() => _GlobalState();
}

class _GlobalState extends State<Global> {
  String selectedPeriode = Global.lastSelectedPeriode;
  int? selectedTrimestre;
  String? selectedIndicateur;
  String? selectedSousIndicateur;
  String? _lastSociete;
  String? selectedAnnee;
  bool isLoading = false;
  bool _isInitialized =
      false; // Flag pour éviter les réinitialisations multiples

  dynamic indicateursResponse;
  dynamic sousIndicsResponse;
  dynamic comptesResponse;
  int comptesOffset = 0;
  int comptesLimit = 50;
  int comptesTotal = 0;
  int currentPage = 0;

  Set<String> expandedSousIndicateurs = {};
  Map<String, dynamic> comptesResponses = {};
  Map<String, bool> isLoadingComptes = {};
  bool isKEuros = false;
  bool showFormulas = false;

  final TextEditingController _globalSearchController = TextEditingController();
  String _globalSearchText = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keycloakProvider =
        Provider.of<KeycloakProvider>(context, listen: false);
    final societe = keycloakProvider.selectedCompany;
    if (societe != null && societe != _lastSociete) {
      print(
          '[Global] Changement de société détecté: $_lastSociete -> $societe');
      _lastSociete = societe;
      indicateursResponse = null;
      sousIndicsResponse = null;
      comptesResponse = null;
      comptesResponses.clear();
      isLoadingComptes.clear();
      expandedSousIndicateurs.clear();
      selectedIndicateur = null;
      selectedSousIndicateur = null;
      selectedAnnee = null;
      // Planifier le chargement pour le prochain frame
      Future.microtask(() {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (_lastSociete == null) return;
    print('[Global] Début du chargement des données pour $_lastSociete');
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      // Utiliser le nouveau service de données locales
      print('[Global] Chargement depuis les données locales');

      indicateursResponse = await UnifiedSIGService.fetchIndicateursGlobal(
        societe: _lastSociete!,
        periode: _getPeriodeParam(),
        trimestre: selectedTrimestre,
      );
      sousIndicsResponse = await UnifiedSIGService.fetchSousIndicateursGlobal(
        societe: _lastSociete!,
        periode: _getPeriodeParam(),
        trimestre: selectedTrimestre,
      );

      if (indicateursResponse!.indicateurs.isNotEmpty) {
        selectedAnnee = indicateursResponse!.indicateurs.keys.first;
      }
      print('[Global] Données chargées avec succès');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('[Global] Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadComptesForSousIndicateur(String sousIndicateur) async {
    if (_lastSociete == null || sousIndicateur.isEmpty) {
      return;
    }
    if (!mounted) return;
    setState(() {
      isLoadingComptes[sousIndicateur] = true;
    });
    try {
      final comptesResp = await UnifiedSIGService.fetchComptesGlobal(
        societe: _lastSociete!,
        sousIndicateur: sousIndicateur,
        periode: _getPeriodeParam(),
        trimestre: selectedTrimestre,
        limit: comptesLimit,
        offset: comptesOffset,
      );
      comptesResponses[sousIndicateur] = comptesResp;
      comptesResponse = comptesResp;
      if (mounted) {
        setState(() {
          isLoadingComptes[sousIndicateur] = false;
        });
      }
    } catch (e) {
      print('[Global] Erreur lors du chargement des comptes: $e');
      if (mounted) {
        setState(() {
          isLoadingComptes[sousIndicateur] = false;
        });
      }
    }
  }

  void _onPageChanged(String sousIndicateur, int page) {
    if (!mounted) return;

    setState(() {
      currentPage = page;
      comptesOffset = page * comptesLimit;
    });

    Future.microtask(() {
      if (mounted) {
        _loadComptesForSousIndicateur(sousIndicateur);
      }
    });
  }

  String _getPeriodeParam() {
    if (selectedPeriode.contains('Trimestre')) return 'trimestre';
    if (selectedPeriode == 'Année civile') return 'annee';
    if (selectedPeriode == 'Exercice') return 'exercice';
    return 'annee';
  }

  Widget _buildFormulaItem(String title, String formula) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF00A9CA),
            ),
          ),
          SizedBox(height: 4),
          Text(
            formula,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeButtons() {
    final periodes = [
      '1er Trimestre',
      '2ème Trimestre',
      '3ème Trimestre',
      '4ème Trimestre',
      'Année civile',
    ];
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 0),
      child: Row(
        children: [
          ...periodes.map((periode) {
            final isSelected = selectedPeriode == periode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? Color(0xFF00A9CA) : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  _isInitialized =
                      false; // Reset pour permettre la réinitialisation
                  setState(() {
                    selectedPeriode = periode;
                    Global.lastSelectedPeriode = selectedPeriode;
                    selectedTrimestre = _getTrimestreNumber();
                    selectedIndicateur = null;
                    selectedSousIndicateur = null;
                  });
                  // Planifier le chargement des données pour après le rebuild
                  Future.microtask(() {
                    if (mounted) {
                      _loadData();
                    }
                  });
                },
                child: Text(periode,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          }).toList(),
          // Bouton Euros/KEuros
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isKEuros ? Color(0xFF65887a) : Color(0xFF00A9CA),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              setState(() {
                isKEuros = !isKEuros;
              });
            },
            icon: Icon(Icons.euro, size: 16),
            label: Text(isKEuros ? 'Euros' : 'KEuros',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          // Bouton info jaune
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade200,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.info, color: Colors.yellow.shade200),
                        SizedBox(width: 8),
                        Text('Information'),
                      ],
                    ),
                    content: Text(
                        'Chaque élément surligné en jaune est relié au calcul de l\'indicateur que vous avez sélectionné !'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Fermer'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.info, color: Colors.black, size: 20),
              label: Text('Info'),
            ),
          ),
          Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A9CA), // Couleur Mobaitec
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              setState(() {
                showFormulas = !showFormulas;
              });
            },
            icon: Icon(Icons.info_outline, size: 16),
            label: Text(
                showFormulas ? 'Masquer les formules' : 'Détails des formules',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  int? _getTrimestreNumber() {
    switch (selectedPeriode) {
      case '1er Trimestre':
        return 1;
      case '2ème Trimestre':
        return 2;
      case '3ème Trimestre':
        return 3;
      case '4ème Trimestre':
        return 4;
      default:
        return null;
    }
  }

  // --- MAPPING POUR LES DATATABLES CUSTOM ---
  Map<String, Map<String, double>> getIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (indicateursResponse == null) return data;
    for (final an in indicateursResponse!.indicateurs.keys) {
      for (final ind in indicateursResponse!.indicateurs[an]!) {
        data.putIfAbsent(ind.indicateur, () => {});
        data[ind.indicateur]![an] = ind.valeur;
      }
    }
    return data;
  }

  // --- WIDGET TABLES ---
  Widget buildIndicateurTable() {
    return AdaptiveTableContainer(
      child: GlobalIndicateurDataTable(
        data: getIndicateurData(),
        annees: getAnnees(),
        selectedIndicateur: selectedIndicateur,
        onSelectIndicateur: (ind) {
          // Suppression de la fonctionnalité associe
          setState(() {
            if (selectedIndicateur == ind) {
              selectedIndicateur = null;
              selectedSousIndicateur = null;
            } else {
              selectedIndicateur = ind;
              selectedSousIndicateur = null;
            }
          });
        },
        sigResult: indicateursResponse,
        isKEuros: isKEuros,
      ),
    );
  }

  Widget buildSousIndicateurTable() {
    // DEBUG : Afficher l'indicateur sélectionné et la structure des indicateurs
    print('[DEBUG-PARENT] selectedIndicateur: $selectedIndicateur');
    if (indicateursResponse != null) {
      for (final an in indicateursResponse!.indicateurs.keys) {
        print(
            '[DEBUG-PARENT] an: $an | indicateurs: ${indicateursResponse!.indicateurs[an]?.map((i) => i.indicateur).toList()}');
      }
    }
    return AdaptiveTableContainer(
      child: GlobalSubIndicateurDataTable(
        data: getSousIndicateurData(),
        annees: getAnnees(),
        selectedSousIndicateur: selectedSousIndicateur,
        selectedIndicateur: selectedIndicateur,
        onSelectSousIndicateur: (sousInd) {
          setState(() {
            if (selectedSousIndicateur == sousInd) {
              selectedSousIndicateur = null;
            } else {
              selectedSousIndicateur = sousInd;
            }
          });
        },
        sousIndicsResponse: sousIndicsResponse,
        isKEuros: isKEuros,
        formuleTextParAnnee: getFormuleTextParAnnee(),
      ),
    );
  }

  // Helper pour obtenir les formules textuelles par année pour l'indicateur sélectionné
  Map<String, String> getFormuleTextParAnnee() {
    final Map<String, String> formules = {};
    if (indicateursResponse == null || selectedIndicateur == null)
      return formules;

    for (final an in indicateursResponse!.indicateurs.keys) {
      final indics = indicateursResponse!.indicateurs[an] ?? [];
      for (final ind in indics) {
        if (ind.indicateur == selectedIndicateur &&
            ind.formuleText.isNotEmpty) {
          formules[an] = ind.formuleText;
          break;
        }
      }
    }

    return formules;
  }

  Map<String, Map<String, double>> getSousIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (sousIndicsResponse == null || selectedIndicateur == null) return data;
    for (final an in sousIndicsResponse!.sousIndicateurs.keys) {
      final sousList =
          sousIndicsResponse!.sousIndicateurs[an]?[selectedIndicateur!] ?? [];
      for (final sous in sousList) {
        data.putIfAbsent(sous.sousIndicateur, () => {});
        data[sous.sousIndicateur]![an] = sous.montant;
      }
    }
    return data;
  }

  // Helper pour obtenir la liste des sous-indicateurs associés à l'indicateur sélectionné
  List<String> getSousIndicateursAssocies() {
    final List<String> associeLibelles = [];
    if (indicateursResponse != null && selectedIndicateur != null) {
      for (final an in indicateursResponse!.indicateurs.keys) {
        final indics = indicateursResponse!.indicateurs[an] ?? [];
        for (final ind in indics) {
          if (ind.indicateur == selectedIndicateur) {
            // Gérer les différents formats de données (Map ou objet)
            String formuleText = '';
            if (ind is Map) {
              formuleText = ind['formule_text'] ?? ind['formuleText'] ?? '';
            } else {
              formuleText = ind.formuleText ?? ind.formule_text ?? '';
            }

            if (formuleText.isNotEmpty) {
              // Extraire les sous-indicateurs depuis formule_text
              final Set<String> sousIndicateursTrouves = {};

              // Pattern pour capturer les sous-indicateurs dans la formule
              final pattern =
                  RegExp(r'([A-Z][A-Z\sÉÈÊËÀÂÄÔÙÛÜÇ]+)\s*\([^)]+\)');
              final matches = pattern.allMatches(formuleText);

              for (final match in matches) {
                final sousIndicateur = match.group(1)?.trim();
                if (sousIndicateur != null && sousIndicateur.isNotEmpty) {
                  sousIndicateursTrouves.add(sousIndicateur);
                }
              }

              associeLibelles.addAll(sousIndicateursTrouves);
              break;
            }
          }
        }
      }
    }
    return associeLibelles;
  }

  List<String> getAnnees() {
    return indicateursResponse?.indicateurs.keys.toList() ?? [];
  }

  List<SIGCompteGlobal> getComptesForAnnee(String annee) {
    if (comptesResponse == null) return [];
    final comptes = comptesResponse!.comptes[annee]?.comptes ?? [];
    print(
        '[DEBUG] Comptes pour année $annee (selectedSousIndicateur: $selectedSousIndicateur):');
    for (var c in comptes) {
      print('  - ${c.codeCompte} | ${c.libelleCompte} | ${c.montant}');
    }
    return comptes
        .map((c) => SIGCompteGlobal(
              codeCompte: c.codeCompte,
              libelleCompte: c.libelleCompte,
              montant: c.montant,
              debit: c.debit,
              credit: c.credit,
              annee: int.tryParse(annee) ?? 0,
            ))
        .toList();
  }

  // --- MAPPING POUR LE DATATABLE DES COMPTES GLOBALS ---
  List<String> getAnneesComptes() {
    if (comptesResponse == null) return [];
    return comptesResponse!.comptes.keys.toList();
  }

  // Retourne la liste des comptes uniques (code+libellé)
  List<SIGCompteGlobal> getComptesGlobalTable(List<String> annees) {
    if (comptesResponse == null) return [];
    final Map<String, String> codeToLibelle = {};
    final Set<String> allCodes = {};
    for (final an in annees) {
      final comptesAnnee = comptesResponse!.comptes[an]?.comptes ?? [];
      for (final c in comptesAnnee) {
        allCodes.add(c.codeCompte);
        codeToLibelle[c.codeCompte] = c.libelleCompte;
      }
    }
    print(
        '[DEBUG] getComptesGlobalTable: ${allCodes.length} comptes trouvés: ${allCodes.toList()}');
    return allCodes
        .map((code) => SIGCompteGlobal(
              codeCompte: code,
              libelleCompte: codeToLibelle[code] ?? '',
              montant: 0,
              debit: 0,
              credit: 0,
              annee: 0,
            ))
        .toList();
  }

  // Mapping codeCompte -> { annee -> montant }
  Map<String, Map<String, double>> getComptesMontantsParAnnee(
      List<String> annees) {
    if (comptesResponse == null) return {};
    final Map<String, Map<String, double>> map = {};
    for (final an in annees) {
      final comptesAnnee = comptesResponse!.comptes[an]?.comptes ?? [];
      for (final c in comptesAnnee) {
        map.putIfAbsent(c.codeCompte, () => {});
        map[c.codeCompte]![an] = c.montant;
      }
    }
    print(
        '[DEBUG] getComptesMontantsParAnnee: ${map.length} comptes, keys: ${map.keys.toList()}');
    return map;
  }

  // Ajoute ces helpers pour utiliser la bonne réponse comptes par sous-indicateur
  List<String> getAnneesComptesFromResp(dynamic resp) {
    return resp.comptes.keys.toList();
  }

  List<SIGCompteGlobal> getComptesGlobalTableForResp(
      List<String> annees, dynamic resp) {
    final Map<String, String> keyToLibelle = {};
    final Set<String> allKeys = {};
    for (final an in annees) {
      final comptesAnnee = resp.comptes[an]?.comptes ?? [];
      for (final c in comptesAnnee) {
        final code = c.codeCompte.toString();
        final libelle = c.libelleCompte.toString();
        if (code.isEmpty || libelle.isEmpty) continue;
        final key = '$code|$libelle';
        allKeys.add(key);
        keyToLibelle[key] = libelle;
      }
    }
    return allKeys.map((key) {
      final parts = key.split('|');
      return SIGCompteGlobal(
        codeCompte: parts[0],
        libelleCompte: parts.sublist(1).join('|'),
        montant: 0,
        debit: 0,
        credit: 0,
        annee: 0,
      );
    }).toList();
  }

  Map<String, Map<String, double>> getComptesMontantsParAnneeForResp(
      List<String> annees, dynamic resp) {
    final Map<String, Map<String, double>> map = {};
    for (final an in annees) {
      final comptesAnnee = resp.comptes[an]?.comptes ?? [];
      for (final c in comptesAnnee) {
        final codeStr = c.codeCompte.toString();
        final libelleStr = c.libelleCompte.toString();
        if (codeStr.isEmpty || libelleStr.isEmpty) {
          print(
              '[DEBUG-FR] codeCompte ou libelleCompte est null pour le compte: $c (année: $an)');
          continue;
        }
        if (codeStr == 'null' ||
            libelleStr == 'null' ||
            codeStr.isEmpty ||
            libelleStr.isEmpty) {
          print(
              '[DEBUG-FR] codeCompte ou libelleCompte vide ou "null" (année: $an): code="$codeStr", libelle="$libelleStr", compte: $c');
          continue;
        }
        final key = '$codeStr|$libelleStr';
        map.putIfAbsent(key, () => {});
        map[key]![an] = c.montant;
      }
    }
    print(
        '[DEBUG-FR] getComptesMontantsParAnneeForResp: map.keys = \'${map.keys}\'');
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final annees = getAnnees();
    // final indicateurData = getIndicateurData();
    final sousIndicateurData = getSousIndicateurData();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildPeriodeButtons(),

        // Affichage des formules SIG si demandé
        if (showFormulas)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF00A9CA).withOpacity(0.07),
                border: Border.all(color: Color(0xFF00A9CA).withOpacity(0.2)),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.functions, color: Color(0xFF00A9CA)),
                      SizedBox(width: 8),
                      Text('Détails des formules SIG',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF00A9CA))),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildFormulaItem('MC (Marge commerciale)',
                      "Ventes de marchandises - Coût d'achat des marchandises vendues"),
                  _buildFormulaItem('VA (Valeur ajoutée)',
                      "Production de l'exercice + Marge commerciale - Consommations de l'exercice"),
                  _buildFormulaItem("EBE (Excédent brut d'exploitation)",
                      "VA + Subventions d'exploitation - Impôts et taxes - Charges de personnel"),
                  _buildFormulaItem('R (Résultat)', 'Produits - Charges'),
                  _buildFormulaItem("RE (Résultat d'exploitation)",
                      "EBE + Autres produits - Autres charges"),
                ],
              ),
            ),
          ),

        // Section d'information
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Sélectionner un indicateur pour voir ses sous-indicateurs, puis sur un sous-indicateur pour voir les comptes',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.grey.shade700),
          ),
        ),

        // Section des tableaux de données
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00).withOpacity(0.1),
              border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Indicateurs SIG',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFFFF8C00),
              ),
            ),
          ),
        ),
        if (annees.isNotEmpty) ...[
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isLoading
                ? ShimmerUtils.createLoadingList(
                    context: context,
                    itemCount: 5,
                    itemHeight: 32,
                  )
                : buildIndicateurTable(),
          ),
        ],

        // Section des sous-indicateurs
        if (selectedIndicateur != null && sousIndicateurData.isNotEmpty) ...[
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF00A9CA).withOpacity(0.1),
                border: Border.all(color: Color(0xFF00A9CA).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Sous-indicateurs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF00A9CA),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AdaptiveTableContainer(
              child: GlobalSubIndicateurDataTable(
                data: sousIndicateurData,
                annees: annees,
                selectedSousIndicateur: selectedSousIndicateur,
                selectedIndicateur: selectedIndicateur,
                onSelectSousIndicateur: (sousInd) {
                  setState(() {
                    selectedSousIndicateur = sousInd;
                  });
                  // Planifier le chargement pour après le rebuild
                  Future.microtask(() {
                    if (mounted) {
                      _loadComptesForSousIndicateur(sousInd);
                    }
                  });
                },
                sousIndicsResponse: sousIndicsResponse,
                isKEuros: isKEuros,
                formuleTextParAnnee: getFormuleTextParAnnee(),
              ),
            ),
          ),
        ],

        // Section des comptes
        if (selectedSousIndicateur != null) ...[
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF65887a).withOpacity(0.1),
                border: Border.all(color: Color(0xFF65887a).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Détails des comptes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF65887a),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 520,
                    height: 36,
                    child: TextField(
                      controller: _globalSearchController,
                      onChanged: (value) {
                        setState(() {
                          _globalSearchText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher N° compte ou libellé',
                        hintStyle: TextStyle(
                            color: Color(0xFF65887a).withOpacity(0.7),
                            fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Color(0xFF65887a), size: 20),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xFF65887a), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xFF65887a), width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: Color(0xFF00A9CA), width: 2),
                        ),
                      ),
                      style: TextStyle(
                          color: Color(0xFF222222),
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isLoadingComptes[selectedSousIndicateur] == true
                ? ShimmerUtils.createLoadingList(
                    context: context,
                    itemCount: 5,
                    itemHeight: 48, // élargir les lignes du shimmer aussi
                  )
                : comptesResponse != null
                    ? AdaptiveTableContainer(
                        child: GlobalAccountDataTable(
                          comptes: getComptesGlobalTableForResp(
                                  getAnneesComptesFromResp(comptesResponse!),
                                  comptesResponse!)
                              .where((compte) =>
                                  _globalSearchText.isEmpty ||
                                  compte.codeCompte.toLowerCase().contains(
                                      _globalSearchText.toLowerCase()) ||
                                  compte.libelleCompte.toLowerCase().contains(
                                      _globalSearchText.toLowerCase()))
                              .toList(),
                          annees: getAnneesComptesFromResp(comptesResponse!),
                          montantsParAnnee: getComptesMontantsParAnneeForResp(
                              getAnneesComptesFromResp(comptesResponse!),
                              comptesResponse!),
                          total: comptesResponse!.comptes.values.isNotEmpty
                              ? comptesResponse!.comptes.values.first.total
                              : 0,
                          currentPage: currentPage,
                          pageSize: comptesLimit,
                          onPageChanged: (page) =>
                              _onPageChanged(selectedSousIndicateur!, page),
                          isKEuros: isKEuros,
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.all(16),
                        child:
                            Text('Aucun compte trouvé pour ce sous-indicateur'),
                      ),
          ),
        ], // <-- fin du if (selectedSousIndicateur != null)
      ], // <-- fin des children du ListView
    ); // <-- fin du build
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }
}
