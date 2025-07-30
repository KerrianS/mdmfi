import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';
import 'package:mobaitec_decision_making/services/indicateur/navision_service_sig.dart';
import 'package:mobaitec_decision_making/services/indicateur/odoo_service_sig.dart';
import 'package:mobaitec_decision_making/screens/dashboard/mensuel/mensuel_account_datatable.dart';
import 'package:mobaitec_decision_making/screens/dashboard/mensuel/mensuel_indicateur_datatable.dart';
import 'package:mobaitec_decision_making/screens/dashboard/mensuel/mensuel_sub_indicateur_datatable.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';

class Mensuel extends StatefulWidget {
  static String lastSelectedAnnee = (DateTime.now().year - 1).toString();
  @override
  State<Mensuel> createState() => _MensuelState();
}

class _MensuelState extends State<Mensuel> {
  bool showFormulas = false; // Affichage des formules SIG
  String searchText = '';
  String selectedAnnee = Mensuel.lastSelectedAnnee;
  String? selectedIndicateur;
  String? selectedSousIndicateur;
  String? _lastSociete;
  List<String> allAnnees = [];
  bool isLoading = false;

  dynamic indicateursResponse;
  dynamic sousIndicsResponse;
  dynamic comptesPage;
  int comptesOffset = 0;
  int comptesLimit = 50;
  int comptesTotal = 0;
  int currentPage = 0;

  Set<String> expandedSousIndicateurs =
      {}; // Gardé pour compatibilité mais non utilisé
  Map<String, dynamic> comptesResponses = {};
  Map<String, bool> isLoadingComptes = {};
  // _isInitialized supprimé, on utilise le Provider pour écouter les changements
  bool isKEuros = false; // Variable pour gérer l'affichage en KEuros

  // Helper pour obtenir les formules textuelles par mois pour l'indicateur sélectionné
  Map<String, String> getFormuleTextParMois() {
    final Map<String, String> formules = {};
    if (indicateursResponse == null || selectedIndicateur == null)
      return formules;

    print(
        '[DEBUG] getFormuleTextParMois - indicateursResponse.mois.keys: ${indicateursResponse.mois.keys}');
    print(
        '[DEBUG] getFormuleTextParMois - selectedIndicateur: $selectedIndicateur');

    for (final moisEntry in indicateursResponse.mois.entries) {
      final mois = moisEntry.key;
      final indicateursList = moisEntry.value;
      print(
          '[DEBUG] getFormuleTextParMois - Processing mois: $mois with ${indicateursList.length} indicateurs');

      for (final ind in indicateursList) {
        print(
            '[DEBUG] getFormuleTextParMois - Checking indicateur: ${ind.indicateur} with formuleText: ${ind.formuleText}');
        if (ind.indicateur == selectedIndicateur &&
            ind.formuleText.isNotEmpty) {
          formules[mois] = ind.formuleText;
          print(
              '[DEBUG] getFormuleTextParMois - Found formule for mois $mois: ${ind.formuleText}');
          break;
        }
      }
    }

    print('[DEBUG] getFormuleTextParMois - Final formules: $formules');
    return formules;
  }

  // Helper pour obtenir la liste des sous-indicateurs associés à l'indicateur sélectionné
  List<String> getSousIndicateursAssocies() {
    // Retourner une liste vide car nous supprimons la fonctionnalité associe
    return [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keycloakProvider =
        Provider.of<KeycloakProvider>(context, listen: true);
    final societe = keycloakProvider.selectedCompany;
    if (societe != null && societe != _lastSociete) {
      print(
          '[Mensuel] Changement de société détecté: $_lastSociete -> $societe');
      _lastSociete = societe;
      indicateursResponse = null;
      sousIndicsResponse = null;
      comptesPage = null;
      comptesResponses.clear();
      isLoadingComptes.clear();
      expandedSousIndicateurs.clear();
      selectedIndicateur = null;
      selectedSousIndicateur = null;
      Future.microtask(() {
        if (mounted) {
          _loadAnnees(societe);
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAnnees(String societe) async {
    print('[Mensuel] Début du chargement pour $societe');

    setState(() {
      isLoading = true;
    });

    try {
      // Générer les années de l'année actuelle jusqu'à 2020
      final currentYear = DateTime.now().year;
      allAnnees = [];
      for (int year = currentYear; year >= 2020; year--) {
        allAnnees.add(year.toString());
      }

      if (!mounted) return;
      setState(() {
        selectedAnnee =
            allAnnees.first; // Sélectionner l'année actuelle par défaut
        isLoading = false;
      });
      _loadData();
    } catch (e) {
      print('[Mensuel] Erreur lors du chargement des années: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_lastSociete == null) return;
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final anneeInt = int.parse(selectedAnnee);
      print(
          '[Mensuel] Chargement des données pour $_lastSociete, année: $anneeInt');
      final isOdoo =
          Provider.of<KeycloakProvider>(context, listen: false).isOdooSelected;
      if (isOdoo) {
        indicateursResponse = await OdooSIGService()
            .fetchIndicateursMensuel(societe: _lastSociete!, annee: anneeInt);
        sousIndicsResponse = await OdooSIGService().fetchSousIndicateursMensuel(
            societe: _lastSociete!, annee: anneeInt);
      } else {
        indicateursResponse = await NavisionSIGService()
            .fetchIndicateursMensuel(societe: _lastSociete!, annee: anneeInt);
        sousIndicsResponse = await NavisionSIGService()
            .fetchSousIndicateursMensuel(
                societe: _lastSociete!, annee: anneeInt);
      }

      // Debug: Afficher la structure des données reçues
      print(
          '[Mensuel] indicateursResponse reçu: ${indicateursResponse != null}');
      if (indicateursResponse != null) {
        print(
            '[Mensuel] Structure indicateursResponse: ${indicateursResponse.toString()}');
        print('[Mensuel] Nombre de mois: ${indicateursResponse.mois.length}');
        for (final entry in indicateursResponse.mois.entries) {
          print(
              '[Mensuel] Mois ${entry.key}: ${entry.value.length} indicateurs');
          if (entry.value.isNotEmpty) {
            print(
                '[Mensuel] Premier indicateur: ${entry.value.first.toString()}');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('[Mensuel] Erreur lors du chargement: $e');
      print('[Mensuel] Stack trace: ${StackTrace.current}');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadComptes() async {
    if (_lastSociete == null || selectedSousIndicateur == null) return;
    if (!mounted) return;
    setState(() {
      isLoadingComptes[selectedSousIndicateur!] = true;
    });
    try {
      final isOdoo =
          Provider.of<KeycloakProvider>(context, listen: false).isOdooSelected;
      final comptesPage = isOdoo
          ? await OdooSIGService().fetchComptesMensuel(
              societe: _lastSociete!,
              annee: int.parse(selectedAnnee),
              mois: 1,
              sousIndicateur: selectedSousIndicateur!,
              limit: comptesLimit,
              offset: comptesOffset,
            )
          : await NavisionSIGService().fetchComptesMensuel(
              societe: _lastSociete!,
              annee: int.parse(selectedAnnee),
              mois: 1,
              sousIndicateur: selectedSousIndicateur!,
              limit: comptesLimit,
              offset: comptesOffset,
            );
      if (!mounted) return;
      setState(() {
        comptesResponses[selectedSousIndicateur!] = comptesPage;
        isLoadingComptes[selectedSousIndicateur!] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingComptes[selectedSousIndicateur!] = false;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      currentPage = page;
      comptesOffset = page * comptesLimit;
    });
    _loadComptes();
  }

  Widget _buildFormulesSIG() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF00A9CA).withOpacity(0.08),
          border: Border.all(color: Color(0xFF00A9CA).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
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
            SizedBox(height: 10),
            _buildFormulaItem('MC (Marge commerciale)',
                'Ventes de marchandises - Coût d\'achat des marchandises vendues'),
            _buildFormulaItem('VA (Valeur ajoutée)',
                'Production de l\'exercice + Marge commerciale - Consommations de l\'exercice'),
            _buildFormulaItem('EBE (Excédent brut d\'exploitation)',
                'VA + Subventions d\'exploitation - Impôts et taxes - Charges de personnel'),
            _buildFormulaItem('RE (Résultat d\'exploitation)',
                'EBE + Autres produits - Autres charges'),
            _buildFormulaItem('R (Résultat)', 'Produits - Charges'),
          ],
        ),
      ),
    );
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
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAnneeButtons() {
    if (allAnnees.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 0),
      child: Row(
        children: [
          // Boutons d'années
          ...allAnnees.map((annee) {
            final isSelected = selectedAnnee == annee;
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
                  setState(() {
                    selectedAnnee = annee;
                    Mensuel.lastSelectedAnnee = selectedAnnee;
                    _loadData();
                    selectedIndicateur = null;
                    selectedSousIndicateur = null;
                    expandedSousIndicateurs.clear();
                    comptesResponses.clear();
                  });
                },
                child: Text(annee,
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
          // Bouton info jaune (yellow.shade200)
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
                        Icon(Icons.info, color: Colors.yellow.shade700),
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
          // Bouton Détails des formules tout à droite
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A9CA),
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

  // --- MAPPING POUR LES DATATABLES CUSTOM ---
  Map<String, Map<String, double>> getIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    print(
        '[Mensuel] getIndicateurData() - indicateursResponse: ${indicateursResponse != null}');
    if (indicateursResponse == null) return data;

    try {
      for (final moisEntry in indicateursResponse!.mois.entries) {
        final mois = moisEntry.key;
        final indicateurs = moisEntry.value;
        final moisFormatted = '$selectedAnnee${mois.padLeft(2, '0')}';
        print(
            '[Mensuel] getIndicateurData() - Processing mois: $mois ($moisFormatted) with ${indicateurs.length} indicateurs');

        for (final ind in indicateurs) {
          try {
            data.putIfAbsent(ind.indicateur, () => {});
            data[ind.indicateur]![moisFormatted] = ind.valeur;
            print(
                '[Mensuel] getIndicateurData() - Added ${ind.indicateur}: ${ind.valeur} for $moisFormatted');
          } catch (e) {
            print(
                '[Mensuel] getIndicateurData() - Error processing indicateur: $e');
            print(
                '[Mensuel] getIndicateurData() - Indicateur data: ${ind.toString()}');
          }
        }
      }
    } catch (e) {
      print('[Mensuel] getIndicateurData() - Error in main loop: $e');
    }
    print('[Mensuel] getIndicateurData() - Final data keys: ${data.keys}');
    return data;
  }

  Map<String, Map<String, double>> getSousIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (sousIndicsResponse == null || selectedIndicateur == null) return data;

    for (final moisEntry in sousIndicsResponse!.mois.entries) {
      final mois = moisEntry.key;
      final indicateurs = moisEntry.value[selectedIndicateur!] ?? [];
      final moisFormatted = '$selectedAnnee${mois.padLeft(2, '0')}';

      for (final sousInd in indicateurs) {
        data.putIfAbsent(sousInd.sousIndicateur, () => {});
        data[sousInd.sousIndicateur]![moisFormatted] = sousInd.montant;
      }
    }
    return data;
  }

  List<String> getMois() {
    print(
        '[Mensuel] getMois() - indicateursResponse: ${indicateursResponse != null}');
    if (indicateursResponse == null) return <String>[];
    final moisList = indicateursResponse!.mois.keys
        .map((mois) => '$selectedAnnee${mois.padLeft(2, '0')}')
        .toList();
    moisList.sort();
    print('[Mensuel] getMois() - moisList: $moisList');
    return List<String>.from(moisList);
  }

  List<dynamic> getComptesForResp(dynamic resp) {
    if (resp == null) return [];
    if (resp.comptes != null) return resp.comptes;
    return [];
  }

  Map<String, Map<String, double>> getComptesMontantsParMoisForResp(
      List<String> mois, dynamic resp) {
    final Map<String, Map<String, double>> map = {};
    if (resp == null || resp.comptes == null) return map;
    for (final compte in resp.comptes) {
      map.putIfAbsent(compte.codeCompte, () => {});
      final dateEcriture = compte.dateEcriture;
      final moisCompte =
          '${dateEcriture.year}${dateEcriture.month.toString().padLeft(2, '0')}';
      map[compte.codeCompte]![moisCompte] = compte.montant;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final mois = getMois();
    final indicateurData = getIndicateurData();
    final sousIndicateurData = getSousIndicateurData();
    final TextEditingController searchController =
        TextEditingController(text: searchText);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildAnneeButtons(),
        // ...le bouton est maintenant dans _buildAnneeButtons()
        if (showFormulas) _buildFormulesSIG(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sélectionner un indicateur pour voir les détails mensuels',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
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
              'Indicateurs SIG Mensuels (Navision)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFFFF8C00),
              ),
            ),
          ),
        ),
        if (mois.isNotEmpty) ...[
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isLoading
                ? ShimmerUtils.createLoadingList(
                    context: context,
                    itemCount: 5,
                    itemHeight: 32,
                    itemWidth: double.infinity,
                  )
                : AdaptiveTableContainer(
                    child: MensuelIndicateurDataTable(
                      data: indicateurData,
                      mois: mois.cast<String>(),
                      selectedIndicateur: selectedIndicateur,
                      onSelectIndicateur: (ind) {
                        setState(() {
                          selectedIndicateur = ind;
                          selectedSousIndicateur = null;
                        });
                      },
                      indicateursResponse: indicateursResponse,
                      isKEuros: isKEuros,
                    ),
                  ),
          ),
        ],
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
              child: MensuelSubIndicateurDataTable(
                sousIndicateurs: sousIndicateurData,
                mois: mois.cast<String>(),
                selectedSousIndicateur: selectedSousIndicateur,
                onSelectSousIndicateur: (sousInd) {
                  setState(() {
                    selectedSousIndicateur = sousInd;
                    currentPage = 0;
                    comptesOffset = 0;
                    _loadComptes();
                  });
                },
                sousIndicsResponse: sousIndicsResponse,
                indicateursResponse: indicateursResponse,
                selectedIndicateur: selectedIndicateur,
                isKEuros: isKEuros,
                formuleTextParMois: getFormuleTextParMois(),
              ),
            ),
          ),
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
                  children: [
                    Text(
                      'Comptes pour $selectedSousIndicateur',
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
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
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
                      itemHeight: 32,
                      itemWidth: double.infinity,
                    )
                  : AdaptiveTableContainer(
                      child: MensuelAccountDataTable(
                        comptes: getComptesForResp(
                                comptesResponses[selectedSousIndicateur])
                            .where((compte) =>
                                searchText.isEmpty ||
                                compte.codeCompte
                                    .toLowerCase()
                                    .contains(searchText.toLowerCase()) ||
                                compte.libelleCompte
                                    .toLowerCase()
                                    .contains(searchText.toLowerCase()))
                            .toList(),
                        mois: mois.cast<String>(),
                        montantsParMois: getComptesMontantsParMoisForResp(
                            mois.cast<String>(),
                            comptesResponses[selectedSousIndicateur]),
                        selectedRowIndex: null,
                        onRowSelect: null,
                        total:
                            comptesResponses[selectedSousIndicateur]?.total ??
                                0,
                        currentPage: currentPage,
                        pageSize: comptesLimit,
                        onPageChanged: _onPageChanged,
                      ),
                    ),
            ),
          ],
        ],
      ],
    );
  }
}
