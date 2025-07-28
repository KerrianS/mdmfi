import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/table_header.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/services/indicateur/navision_service_sig.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';

class GraphSig extends StatefulWidget {
  @override
  State<GraphSig> createState() => _GraphSigState();
}


class _GraphSigState extends State<GraphSig> {
  // Liste des indicateurs sélectionnés à afficher
  List<String> selectedIndicateurs = [];
  String selectedPeriode = 'annee';
  int? selectedTrimestre;
  String? _lastSociete;
  bool isLoading = false;
  String chartType = 'line'; // 'line' ou 'pie'
  String? selectedIndicateurForPie; // Pour le pie chart
  bool showKeuros = false; // Ajout du toggle K€uros

  NavisionIndicateursGlobalResponse? indicateursResponse;

  // Couleurs pour les différents indicateurs
  final List<Color> indicateurColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
  bool _isInitialized = false; // Flag pour éviter les réinitialisations multiples

  // Helper pour formatage avec séparateur de milliers
  String formatEuro(num value) {
    String s = value.abs().toStringAsFixed(0);
    String withSpaces = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ' ');
    return '${withSpaces}€';
  }

  String formatKeuro(num value) {
    String s = (value.abs() / 1000).toStringAsFixed(1);
    // Remplacer .0 par rien si pas de décimale utile
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return '${s}K€';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Ne faire le check qu'une seule fois par build
    if (!_isInitialized) {
      _isInitialized = true;
      final keycloakProvider = Provider.of<KeycloakProvider>(context, listen: false);
      final societe = keycloakProvider.selectedCompany;
      
      if (societe != null && societe != _lastSociete) {
        print('[GraphSig] Changement de société détecté: $_lastSociete -> $societe');
        _lastSociete = societe;
        
        // Réinitialiser directement sans setState
        indicateursResponse = null;
        selectedIndicateurForPie = null;
        selectedIndicateurs = [];
        
        // Planifier le chargement pour le prochain frame
        Future.microtask(() {
          if (mounted) {
            _loadData();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_lastSociete == null) return;
    
    print('[GraphSig] Début du chargement des données pour $_lastSociete');
    
    if (!mounted) return;
    setState(() { isLoading = true; });
    try {
      print('[GraphSig] Chargement des données pour $_lastSociete, période: $selectedPeriode');
      
      indicateursResponse = await NavisionSIGService().fetchIndicateursGlobal(
        societe: _lastSociete!, 
        periode: selectedPeriode,
        trimestre: selectedTrimestre,
      );
      print('[GraphSig] Indicateurs chargés: ${indicateursResponse?.indicateurs.length} années');
      // Initialiser la sélection à tous les indicateurs si vide
      if (indicateursResponse != null && selectedIndicateurs.isEmpty) {
        final allIndics = <String>{};
        for (final annee in indicateursResponse!.indicateurs.keys) {
          final indicateursList = indicateursResponse!.indicateurs[annee] as List<NavisionIndicateurGlobal>;
          for (final ind in indicateursList) {
            allIndics.add(ind.indicateur);
          }
        }
        selectedIndicateurs = allIndics.toList();
      }
      if (!mounted) return;
      setState(() { isLoading = false; });
    } catch (e) {
      print('[GraphSig] Erreur lors du chargement: $e');
      if (!mounted) return;
      setState(() { isLoading = false; });
    }
  }

  Widget _buildPeriodeButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection période + bouton K€uros
          Row(
            children: [
              Text('Période: ', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'annee',
                    label: Text('Année'),
                    icon: Icon(Icons.calendar_today, size: 16),
                  ),
                  ButtonSegment(
                    value: 'trimestre',
                    label: Text('Trimestre'),
                    icon: Icon(Icons.calendar_month, size: 16),
                  ),
                ],
                selected: {selectedPeriode},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    selectedPeriode = selection.first;
                    if (selectedPeriode == 'trimestre' && selectedTrimestre == null) {
                      selectedTrimestre = 1;
                    }
                    _loadData();
                  });
                },
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: showKeuros ? Color(0xFF65887a) : Color(0xFF00A9CA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: showKeuros ? 1 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                onPressed: () {
                  setState(() {
                    showKeuros = !showKeuros;
                  });
                },
                icon: Icon(Icons.euro, size: 16),
                label: Text(showKeuros ? 'Euros' : 'KEuros'),
              ),
            ],
          ),
          // Sélection trimestre si période=trimestre
          if (selectedPeriode == 'trimestre') ...[
            SizedBox(height: 8),
            Row(
              children: [
                Text('Trimestre: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                DropdownButton<int>(
                  value: selectedTrimestre,
                  items: [1, 2, 3, 4].map((trimestre) {
                    return DropdownMenuItem(
                      value: trimestre,
                      child: Text('T$trimestre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTrimestre = value;
                      _loadData();
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getOrderedAnnees() {
    if (indicateursResponse == null) return [];
    final anneesList = indicateursResponse!.indicateurs.keys.map((a) => int.parse(a)).toList()..sort();
    return anneesList.map((a) => a.toString()).toList();
  }

  List<String> _getIndicateurNames() {
    if (indicateursResponse == null) return [];
    final Set<String> indicateurs = {};
    for (final anneeIndicateurs in indicateursResponse!.indicateurs.values) {
      for (final ind in anneeIndicateurs) {
        indicateurs.add(ind.indicateur);
      }
    }
    return indicateurs.toList()..sort();
  }

  Map<String, Map<String, double>> _getIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (indicateursResponse == null) return data;
    
    for (final anneeEntry in indicateursResponse!.indicateurs.entries) {
      final annee = anneeEntry.key;
      final indicateurs = anneeEntry.value;
      
      for (final ind in indicateurs) {
        data.putIfAbsent(ind.indicateur, () => {});
        data[ind.indicateur]![annee] = ind.valeur;
      }
    }
    return data;
  }

  List<LineChartBarData> _getLineChartBarData() {
    final indicateurData = _getIndicateurData();
    final annees = _getOrderedAnnees();
    final indicateurs = selectedIndicateurs;
    
    List<LineChartBarData> lines = [];
    
    for (int i = 0; i < indicateurs.length; i++) {
      final indicateur = indicateurs[i];
      final montantsParAnnee = indicateurData[indicateur] ?? {};
      
      List<FlSpot> spots = [];
      for (int j = 0; j < annees.length; j++) {
        final anneeKey = annees[j];
        final montant = montantsParAnnee[anneeKey] ?? 0;
        spots.add(FlSpot(j.toDouble(), montant));
      }
      
      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: indicateurColors[i % indicateurColors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
              FlDotCirclePainter(
                radius: 4,
                color: indicateurColors[i % indicateurColors.length],
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }
    
    return lines;
  }

  FlTitlesData _getTitlesData() {
    final annees = _getOrderedAnnees();
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 80,
          getTitlesWidget: (value, meta) {
            if (showKeuros) {
              return Text(formatKeuro(value), style: TextStyle(fontSize: 10));
            } else {
              return Text(formatEuro(value), style: TextStyle(fontSize: 10));
            }
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < annees.length) {
              final anneeKey = annees[index];
              return Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  anneeKey,
                  style: TextStyle(fontSize: 10),
                ),
              );
            }
            return Text('');
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getMinY() {
    final indicateurData = _getIndicateurData();
    double min = 0;
    for (final montantsParAnnee in indicateurData.values) {
      for (final montant in montantsParAnnee.values) {
        if (montant < min) min = montant;
      }
    }
    return min * 1.1; // Ajouter 10% de marge
  }

  double _getMaxY() {
    final indicateurData = _getIndicateurData();
    double max = 0;
    for (final montantsParAnnee in indicateurData.values) {
      for (final montant in montantsParAnnee.values) {
        if (montant > max) max = montant;
      }
    }
    return max * 1.1; // Ajouter 10% de marge
  }

  Widget _buildLegend() {
    final indicateurs = _getIndicateurNames();
    if (indicateurs.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: indicateurs.asMap().entries.map((entry) {
          final index = entry.key;
          final indicateur = entry.value;
          final color = indicateurColors[index % indicateurColors.length];
          final isSelected = selectedIndicateurs.contains(indicateur);
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedIndicateurs.remove(indicateur);
                } else {
                  selectedIndicateurs.add(indicateur);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(isSelected ? 0.7 : 0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    margin: EdgeInsets.only(right: 8, top: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(indicateur, style: TextStyle(fontWeight: FontWeight.w500)),
                  if (isSelected) ...[
                    SizedBox(width: 8),
                    Icon(Icons.check, color: color, size: 18),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Nouvelles méthodes pour le pie chart
  List<PieChartSectionData> _getPieChartSections() {
    final annees = _getOrderedAnnees();
    if (annees.isEmpty || selectedIndicateurForPie == null) return [];

    final indicateurData = _getIndicateurData();
    final montantsParAnnee = indicateurData[selectedIndicateurForPie!] ?? {};
    
    double total = montantsParAnnee.values.fold(0, (sum, val) => sum + val.abs());
    if (total == 0) return [];

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < annees.length; i++) {
      final anneeKey = annees[i];
      final montant = montantsParAnnee[anneeKey] ?? 0;
      if (montant != 0) {
        final percentage = (montant.abs() / total) * 100;
        sections.add(
          PieChartSectionData(
            color: indicateurColors[i % indicateurColors.length],
            value: montant.abs(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: indicateurColors[i % indicateurColors.length]),
              ),
              child: Text(
                anneeKey,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: indicateurColors[i % indicateurColors.length],
                ),
              ),
            ),
            badgePositionPercentageOffset: 1.3,
          ),
        );
      }
    }
    return sections;
  }

  Widget _buildPieLegend() {
    final annees = _getOrderedAnnees();
    if (annees.isEmpty || selectedIndicateurForPie == null) return SizedBox();

    final indicateurData = _getIndicateurData();
    final montantsParAnnee = indicateurData[selectedIndicateurForPie!] ?? {};

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: annees.asMap().entries.map((entry) {
          final index = entry.key;
          final anneeKey = entry.value;
          final montant = montantsParAnnee[anneeKey] ?? 0;
          final color = indicateurColors[index % indicateurColors.length];
          
          if (montant == 0) return SizedBox();
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'Année $anneeKey: ${montant.toStringAsFixed(0)}€',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Type de graphique: ', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'line',
                label: Text('Courbes'),
                icon: Icon(Icons.show_chart, size: 16),
              ),
              ButtonSegment(
                value: 'pie',
                label: Text('Camembert'),
                icon: Icon(Icons.pie_chart, size: 16),
              ),
            ],
            selected: {chartType},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                chartType = selection.first;
                if (chartType == 'pie' && selectedIndicateurForPie == null) {
                  final indicateurs = _getIndicateurNames();
                  if (indicateurs.isNotEmpty) {
                    selectedIndicateurForPie = indicateurs.first;
                  }
                }
              });
            },
          ),
          if (chartType == 'pie') ...[
            SizedBox(width: 16),
            Text('Indicateur: ', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedIndicateurForPie,
              items: _getIndicateurNames().map((indicateur) {
                return DropdownMenuItem(
                  value: indicateur,
                  child: Text(indicateur, style: TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedIndicateurForPie = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final sections = _getPieChartSections();
    if (sections.isEmpty || selectedIndicateurForPie == null) {
      return Center(
        child: Text(
          'Aucune donnée disponible pour cet indicateur',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
          startDegreeOffset: -90,
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (indicateursResponse == null || _getIndicateurNames().isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée disponible pour cette période',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    final annees = _getOrderedAnnees();
    if (annees.isEmpty) {
      return Center(
        child: Text(
          'Aucune année disponible',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    // Retourner le graphique selon le type sélectionné
    if (chartType == 'pie') {
      return _buildPieChart();
    } else {
      return Padding(
        padding: EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (annees.length - 1).toDouble(),
            minY: _getMinY(),
            maxY: _getMaxY(),
            lineBarsData: _getLineChartBarData(),
            titlesData: _getTitlesData(),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: true,
              horizontalInterval: (_getMaxY() - _getMinY()) / 5,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
            ),
            clipData: FlClipData.all(),
            // Ajout du tooltip pour affichage K€uros/€
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final indicateur = selectedIndicateurs[spot.barIndex];
                    final color = indicateurColors[spot.barIndex % indicateurColors.length];
                    final value = spot.y;
                    String formatted = showKeuros ? formatKeuro(value) : formatEuro(value);
                    return LineTooltipItem(
                      '$indicateur\n$formatted',
                      TextStyle(color: color, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sélecteurs de période
        _buildPeriodeButtons(),
        
        // Section du graphique
        Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TableHeader(title: 'Graphique Global des Indicateurs SIG'),
                  
                  // Sélecteur de type de graphique
                  if (!isLoading && _getIndicateurNames().isNotEmpty) 
                    _buildChartTypeSelector(),
                  
                  // Légende appropriée selon le type de graphique
                  if (!isLoading && _getIndicateurNames().isNotEmpty)
                    chartType == 'pie' ? _buildPieLegend() : _buildLegend(),
                  
                  // Graphique
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isLoading
                          ? ShimmerUtils.createLoadingContainer(
                              context: context,
                              height: double.infinity,
                              width: double.infinity,
                              margin: EdgeInsets.zero,
                              borderRadius: BorderRadius.circular(4),
                            )
                          : _buildChart(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:mobaitec_decision_making/components/table_header.dart';
// import 'package:mobaitec_decision_making/models/account_detail_month.dart';
// import 'package:mobaitec_decision_making/models/detail_month.dart';
// import 'package:mobaitec_decision_making/models/indicator/account_groupe.dart';
// import 'package:mobaitec_decision_making/models/indicator/indicator.dart';
// import 'package:mobaitec_decision_making/models/indicator/indicator_sign.dart';
// import 'package:mobaitec_decision_making/models/indicator/sub_indicator.dart';
// import 'package:mobaitec_decision_making/screens/dashboard/axe/axe_date_selector.dart';
// import 'package:mobaitec_decision_making/services/account_detail_service.dart';
// import 'package:mobaitec_decision_making/services/cache/cache_indicateur_service.dart';
// import 'package:mobaitec_decision_making/utils/colors.dart';
// import 'package:mobaitec_decision_making/utils/numbers.dart';

// final testSig = <Object, DetailMonth>{};

// class GraphSig extends StatefulWidget {
//   @override
//   State<GraphSig> createState() => _GraphSigState();
// }

// class _GraphSigState extends State<GraphSig> {
//   Indicator? selectedIndicator;
//   SubIndicator? selectedSubIndicator;

//   int startYear = 2022;
//   int startMonth = 1;
//   int endYear = 2022;
//   int endMonth = 12;

//   List<Indicator> indicators = [];

//   @override
//   void initState() {
//     super.initState();
//     // Initialiser les indicateurs SIG
//     List<Indicator> serviceIndicators = CacheIndicateurService().getIndicateurs().cast<Indicator>();
//     indicators = serviceIndicators.isNotEmpty ? serviceIndicators : _createSigTestIndicators();
//   }

//   // Créer des indicateurs SIG de test
//   List<Indicator> _createSigTestIndicators() {
//     return [
//       Indicator(
//         name: 'Production vendue',
//         sousIndicateurs: [
//           SubIndicator(
//             name: 'Ventes de marchandises',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Production vendue de biens',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Production vendue de services',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//         ],
//       ),
//       Indicator(
//         name: 'Production stockée',
//         sousIndicateurs: [
//           SubIndicator(
//             name: 'Variation stocks produits finis',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Variation stocks en-cours',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//         ],
//       ),
//       Indicator(
//         name: 'Consommations intermédiaires',
//         sousIndicateurs: [
//           SubIndicator(
//             name: 'Achats de marchandises',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Achats matières premières',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Services extérieurs',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Autres services extérieurs',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//         ],
//       ),
//       Indicator(
//         name: 'Valeur ajoutée',
//         sousIndicateurs: [
//           SubIndicator(
//             name: 'Valeur ajoutée brute',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Amortissements',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Valeur ajoutée nette',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//         ],
//       ),
//       Indicator(
//         name: 'Excédent brut d\'exploitation',
//         sousIndicateurs: [
//           SubIndicator(
//             name: 'Charges de personnel',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Impôts et taxes',
//             sign: IndicatorSigns.negative,
//             accountGroupes: [],
//           ),
//           SubIndicator(
//             name: 'Subventions d\'exploitation',
//             sign: IndicatorSigns.positive,
//             accountGroupes: [],
//           ),
//         ],
//       ),
//     ];
//   }

//   void _selectIndicator(Indicator indicator) {
//     setState(() {
//       selectedIndicator = indicator;
//       selectedSubIndicator = null;
//     });
//   }

//   void _selectSubIndicator(SubIndicator subIndicator) {
//     setState(() {
//       selectedSubIndicator = subIndicator;
//     });
//   }

//   void _onStartDateChange(int year, int month) {
//     setState(() {
//       startYear = year;
//       startMonth = month;
//     });
//   }

//   void _onEndDateChange(int year, int month) {
//     setState(() {
//       endYear = year;
//       endMonth = month;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Section de sélection de période
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: AxeDateSelector(
//                         startYear: startYear,
//                         startMonth: startMonth,
//                         onStartDateChange: _onStartDateChange,
//                         endYear: endYear,
//                         endMonth: endMonth,
//                         onEndDateChange: _onEndDateChange,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Section de sélection des indicateurs SIG
//           Padding(
//             padding: EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 // Sélection d'indicateur SIG
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Indicateurs SIG',
//                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                       SizedBox(height: 8),
//                       Container(
//                         height: 150,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: ListView.builder(
//                           itemCount: indicators.length,
//                           itemBuilder: (context, index) {
//                             final indicator = indicators[index];
//                             return ListTile(
//                               dense: true,
//                               title: Text(
//                                 indicator.name,
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                               selected: selectedIndicator == indicator,
//                               selectedTileColor: AppColors.mcaBleu200.color.withOpacity(0.2),
//                               onTap: () => _selectIndicator(indicator),
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 // Sélection de sous-indicateur
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Détails SIG',
//                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                       SizedBox(height: 8),
//                       Container(
//                         height: 150,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         child: selectedIndicator == null
//                             ? Center(
//                                 child: Text(
//                                   'Sélectionnez un indicateur SIG',
//                                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                                 ),
//                               )
//                             : ListView.builder(
//                                 itemCount: selectedIndicator!.sousIndicateurs.length,
//                                 itemBuilder: (context, index) {
//                                   final subIndicator = selectedIndicator!.sousIndicateurs[index];
//                                   return ListTile(
//                                     dense: true,
//                                     title: Text(
//                                       subIndicator.name,
//                                       style: TextStyle(fontSize: 12),
//                                     ),
//                                     selected: selectedSubIndicator == subIndicator,
//                                     selectedTileColor: AppColors.mcaBleu200.color.withOpacity(0.2),
//                                     onTap: () => _selectSubIndicator(subIndicator),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Section du graphique SIG
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.all(8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   TableHeader(title: 'Graphique SIG (Système d\'Information de Gestion)'),
//                   // Légende
//                   if (selectedIndicator != null) _buildLegend(),
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color: AppColors.blueGreyLight.color.withOpacity(0.3)
//                         ),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: _buildChart(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChart() {
//     if (selectedIndicator == null) {
//       return Center(
//         child: Text(
//           'Sélectionnez un indicateur SIG pour afficher le graphique',
//           style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//         ),
//       );
//     }

//     return Padding(
//       padding: EdgeInsets.all(16),
//       child: LineChart(
//         LineChartData(
//           minX: _getMinX(),
//           maxX: _getMaxX(),
//           minY: _getMinY(),
//           maxY: _getMaxY(),
//           lineBarsData: _getLineChartBarData(),
//           titlesData: _getTitlesData(),
//           borderData: FlBorderData(
//             show: true,
//             border: Border.all(color: Colors.grey.shade400, width: 1),
//           ),
//           gridData: FlGridData(
//             show: true,
//             drawHorizontalLine: true,
//             drawVerticalLine: true,
//             horizontalInterval: (_getMaxY() - _getMinY()) / 5,
//             getDrawingHorizontalLine: (value) => FlLine(
//               color: Colors.grey.shade300,
//               strokeWidth: 1,
//             ),
//             getDrawingVerticalLine: (value) => FlLine(
//               color: Colors.grey.shade300,
//               strokeWidth: 1,
//             ),
//           ),
//           clipData: FlClipData.all(),
//         ),
//       ),
//     );
//   }

//   Widget _buildLegend() {
//     List<DetailMonth> details = _getDetailsForChart();
//     if (details.isEmpty) return SizedBox();

//     List<Color> colors = [
//       AppColors.mcaBleu.color,
//       AppColors.vertVif.color,
//       AppColors.rougeOrange.color,
//       PieChartColors.rougeFramboise.color,
//       PieChartColors.pourpreFonce.color,
//       PieChartColors.jauneDore.color,
//     ];

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Wrap(
//         spacing: 16,
//         runSpacing: 8,
//         children: details.asMap().entries.map((entry) {
//           int index = entry.key;
//           DetailMonth detail = entry.value;
//           return Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 16,
//                 height: 3,
//                 decoration: BoxDecoration(
//                   color: colors[index % colors.length],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(width: 6),
//               Text(
//                 detail.name,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.grey.shade700,
//                 ),
//               ),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   double _getMinX() {
//     return 1;
//   }

//   double _getMaxX() {
//     double totalMonths = 0;
//     for (var year = startYear; year <= endYear; year++) {
//       int startMonthValue = (year == startYear) ? startMonth : 1;
//       int endMonthValue = (year == endYear) ? endMonth : 12;
//       totalMonths += (endMonthValue - startMonthValue + 1);
//     }
//     return totalMonths;
//   }

//   double _getMinY() {
//     List<DetailMonth> details = _getDetailsForChart();
//     if (details.isEmpty) return 0;

//     double min = double.infinity;
//     for (var detail in details) {
//       for (var year = startYear; year <= endYear; year++) {
//         int startMonthValue = (year == startYear) ? startMonth : 1;
//         int endMonthValue = (year == endYear) ? endMonth : 12;
        
//         for (var month = startMonthValue; month <= endMonthValue; month++) {
//           double value = _getValueForYearMonth(detail, year, month);
//           if (value < min) min = value;
//         }
//       }
//     }
//     return (min * 0.9);
//   }

//   double _getMaxY() {
//     List<DetailMonth> details = _getDetailsForChart();
//     if (details.isEmpty) return 100000;

//     double max = double.negativeInfinity;
//     for (var detail in details) {
//       for (var year = startYear; year <= endYear; year++) {
//         int startMonthValue = (year == startYear) ? startMonth : 1;
//         int endMonthValue = (year == endYear) ? endMonth : 12;
        
//         for (var month = startMonthValue; month <= endMonthValue; month++) {
//           double value = _getValueForYearMonth(detail, year, month);
//           if (value > max) max = value;
//         }
//       }
//     }
//     return (max * 1.1);
//   }

//   List<DetailMonth> _getDetailsForChart() {
//     List<DetailMonth> details = [];
    
//     if (selectedSubIndicator != null) {
//       // Afficher seulement les données du sous-indicateur sélectionné
//       details.add(getSigSubIndicatorDetailMonth(selectedSubIndicator!));
//     } else if (selectedIndicator != null) {
//       // Afficher les données de l'indicateur sélectionné
//       details.add(getSigIndicatorDetailMonth(selectedIndicator!));
      
//       // Afficher aussi les 3 premiers sous-indicateurs pour comparaison
//       for (int i = 0; i < selectedIndicator!.sousIndicateurs.length && i < 3; i++) {
//         details.add(getSigSubIndicatorDetailMonth(selectedIndicator!.sousIndicateurs[i]));
//       }
//     }
    
//     return details;
//   }

//   double _getValueForYearMonth(DetailMonth detail, int year, int month) {
//     if (year == 2022 && month <= 12) {
//       return detail.yearN0?[month-1] ?? 0;
//     } else if (year == 2021 && month <= 12) {
//       return detail.yearN1?[month-1] ?? 0;
//     } else if (year == 2020 && month <= 12) {
//       return detail.yearN2?[month-1] ?? 0;
//     } else if (year == 2019 && month <= 12) {
//       return detail.yearN3?[month-1] ?? 0;
//     }
//     return 0;
//   }

//   List<LineChartBarData> _getLineChartBarData() {
//     List<DetailMonth> details = _getDetailsForChart();
//     if (details.isEmpty) return [];

//     List<LineChartBarData> lineBars = [];
//     List<Color> colors = [
//       AppColors.mcaBleu.color,
//       AppColors.vertVif.color,
//       AppColors.rougeOrange.color,
//       PieChartColors.rougeFramboise.color,
//       PieChartColors.pourpreFonce.color,
//       PieChartColors.jauneDore.color,
//     ];

//     for (int i = 0; i < details.length; i++) {
//       DetailMonth detail = details[i];
//       List<FlSpot> spots = [];
//       double xIndex = 1;

//       for (var year = startYear; year <= endYear; year++) {
//         int startMonthValue = (year == startYear) ? startMonth : 1;
//         int endMonthValue = (year == endYear) ? endMonth : 12;
        
//         for (var month = startMonthValue; month <= endMonthValue; month++) {
//           double value = _getValueForYearMonth(detail, year, month);
//           spots.add(FlSpot(xIndex, value));
//           xIndex++;
//         }
//       }

//       lineBars.add(
//         LineChartBarData(
//           spots: spots,
//           isCurved: true,
//           color: colors[i % colors.length],
//           barWidth: 3,
//           dotData: FlDotData(
//             show: true,
//             getDotPainter: (spot, percent, barData, index) {
//               return FlDotCirclePainter(
//                 radius: 4,
//                 color: colors[i % colors.length],
//                 strokeWidth: 2,
//                 strokeColor: Colors.white,
//               );
//             },
//           ),
//           belowBarData: BarAreaData(
//             show: false,
//           ),
//         ),
//       );
//     }

//     return lineBars;
//   }

//   FlTitlesData _getTitlesData() {
//     return FlTitlesData(
//       leftTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 80,
//           interval: (_getMaxY() - _getMinY()) / 6,
//           getTitlesWidget: (value, meta) {
//             // Format en milliers (K) pour plus de lisibilité
//             if (value >= 1000) {
//               return Text(
//                 '${(value / 1000).toStringAsFixed(0)}K',
//                 style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
//               );
//             }
//             return Text(
//               value.toInt().toString(),
//               style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
//             );
//           },
//         ),
//       ),
//       bottomTitles: AxisTitles(
//         sideTitles: SideTitles(
//           showTitles: true,
//           reservedSize: 50,
//           interval: 1,
//           getTitlesWidget: (value, meta) {
//             int monthIndex = value.toInt();
//             if (monthIndex < 1) return SizedBox();

//             // Calculer l'année et le mois à partir de l'index
//             double currentIndex = 1;
//             for (var year = startYear; year <= endYear; year++) {
//               int startMonthValue = (year == startYear) ? startMonth : 1;
//               int endMonthValue = (year == endYear) ? endMonth : 12;
              
//               for (var month = startMonthValue; month <= endMonthValue; month++) {
//                 if (currentIndex == monthIndex) {
//                   // Afficher au format "202201" mais seulement tous les 2 mois pour éviter l'encombrement
//                   if (monthIndex % 2 == 1 || monthIndex == _getMaxX().toInt()) {
//                     String monthStr = month.toString().padLeft(2, '0');
//                     return Transform.rotate(
//                       angle: -0.5,
//                       child: Text(
//                         '$year$monthStr',
//                         style: TextStyle(fontSize: 8, color: Colors.grey.shade700),
//                       ),
//                     );
//                   }
//                   return SizedBox();
//                 }
//                 currentIndex++;
//               }
//             }

//             return SizedBox();
//           },
//         ),
//       ),
//       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//     );
//   }
// }

// // Fonctions helper pour récupérer les données SIG
// DetailMonth getSigIndicatorDetailMonth(Indicator indicator) {
//   if (testSig.containsKey(indicator)) {
//     return testSig[indicator]!;
//   }
//   final detail = DetailMonth(
//     name: indicator.name,
//     yearN0: [],
//     yearN1: [],
//     yearN2: [],
//     yearN3: [],
//   );

//   // Données SIG 2022 - Patterns spécifiques selon le type d'indicateur
//   List<double> base2022;
//   if (indicator.name.contains('Production')) {
//     // Production: croissance soutenue
//     base2022 = [
//       250000, 260000, 275000, 290000, 305000, 320000,
//       335000, 350000, 365000, 380000, 395000, 410000
//     ];
//   } else if (indicator.name.contains('Consommations')) {
//     // Consommations: croissance modérée
//     base2022 = [
//       180000, 185000, 190000, 195000, 200000, 205000,
//       210000, 215000, 220000, 225000, 230000, 235000
//     ];
//   } else if (indicator.name.contains('Valeur ajoutée')) {
//     // Valeur ajoutée: différence production - consommations
//     base2022 = [
//       70000, 75000, 85000, 95000, 105000, 115000,
//       125000, 135000, 145000, 155000, 165000, 175000
//     ];
//   } else {
//     // Autres indicateurs SIG
//     base2022 = [
//       45000, 50000, 55000, 60000, 65000, 70000,
//       75000, 80000, 85000, 90000, 95000, 100000
//     ];
//   }

//   detail.yearN0?.addAll(base2022.map((value) => value + randDoubleCurrency(-15000, 15000)));

//   // Données 2021 - Légèrement inférieures
//   detail.yearN1?.addAll(base2022.map((value) => (value * 0.92) + randDoubleCurrency(-12000, 12000)));

//   // Données 2020 - Impact COVID
//   detail.yearN2?.addAll(base2022.map((value) => (value * 0.85) + randDoubleCurrency(-10000, 10000)));

//   // Données 2019 - Base de référence
//   detail.yearN3?.addAll(base2022.map((value) => (value * 0.88) + randDoubleCurrency(-8000, 8000)));

//   testSig[indicator] = detail;
//   return detail;
// }

// DetailMonth getSigSubIndicatorDetailMonth(SubIndicator subIndicator) {
//   if (testSig.containsKey(subIndicator)) {
//     return testSig[subIndicator]!;
//   }
//   final detail = DetailMonth(
//     name: subIndicator.name,
//     yearN0: [],
//     yearN1: [],
//     yearN2: [],
//     yearN3: [],
//   );

//   // Générer des patterns SIG différents selon le sous-indicateur
//   int hashCode = subIndicator.name.hashCode;
//   double multiplier = 0.4 + (hashCode % 6) * 0.1; // Entre 0.4 et 0.9
  
//   // Données 2022 - Pattern SIG selon le type
//   List<double> pattern2022;
//   if (subIndicator.name.contains('Ventes') || subIndicator.name.contains('Production vendue')) {
//     // Pattern de ventes: saisonnalité marquée
//     pattern2022 = [
//       80000, 70000, 85000, 90000, 95000, 88000,
//       110000, 105000, 115000, 120000, 125000, 130000
//     ];
//   } else if (subIndicator.name.contains('Achats') || subIndicator.name.contains('Charges')) {
//     // Pattern d'achats/charges: plus stable
//     pattern2022 = [
//       60000, 62000, 64000, 66000, 68000, 70000,
//       72000, 74000, 76000, 78000, 80000, 82000
//     ];
//   } else if (subIndicator.name.contains('Variation')) {
//     // Pattern de variation: très volatile
//     pattern2022 = [
//       5000, -2000, 8000, 3000, -1000, 6000,
//       -3000, 4000, 7000, 2000, -4000, 9000
//     ];
//   } else {
//     // Pattern général
//     pattern2022 = [
//       50000, 52000, 55000, 58000, 60000, 63000,
//       65000, 68000, 70000, 73000, 75000, 78000
//     ];
//   }
  
//   detail.yearN0?.addAll(pattern2022.map((value) => (value * multiplier) + randDoubleCurrency(-3000, 3000)));

//   // Appliquer les mêmes patterns pour les autres années avec des multiplicateurs différents
//   detail.yearN1?.addAll(pattern2022.map((value) => (value * multiplier * 0.93) + randDoubleCurrency(-2500, 2500)));
//   detail.yearN2?.addAll(pattern2022.map((value) => (value * multiplier * 0.86) + randDoubleCurrency(-2000, 2000)));
//   detail.yearN3?.addAll(pattern2022.map((value) => (value * multiplier * 0.89) + randDoubleCurrency(-1500, 1500)));

//   testSig[subIndicator] = detail;
//   return detail;
// }

// List<DetailMonth> getSigAccountGroupeDetailMonth(AccountGroupe accountGroupe) {
//   List<AccountDetailMonth> accountDetailMonth = AccountDetailService()
//       .getAccountDetailMonth(accountGroupe.value, accountGroupe.type);

//   return accountDetailMonth
//       .map((a) => DetailMonth(
//           name: a.num,
//           yearN0: a.yearN0,
//           yearN1: a.yearN1,
//           yearN2: a.yearN2,
//           yearN3: a.yearN3))
//       .toList();
// }
