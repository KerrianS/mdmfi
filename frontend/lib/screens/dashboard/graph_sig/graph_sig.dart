import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/table_header.dart';
import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';
import 'package:mobaitec_decision_making/services/data/unified_sig_service.dart';
import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';

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

  dynamic indicateursResponse;

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
  bool _isInitialized =
      false; // Flag pour éviter les réinitialisations multiples

  // Helper pour formatage avec séparateur de milliers
  String formatEuro(num value) {
    String s = value.abs().toStringAsFixed(0);
    String withSpaces =
        s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ' ');
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
      final keycloakProvider =
          Provider.of<KeycloakProvider>(context, listen: false);
      final societe = keycloakProvider.selectedCompany;

      if (societe != null && societe != _lastSociete) {
        print(
            '[GraphSig] Changement de société détecté: $_lastSociete -> $societe');
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
    setState(() {
      isLoading = true;
    });
    try {
      print('[GraphSig] Chargement des données depuis les données locales');

      indicateursResponse = await UnifiedSIGService.fetchIndicateursGlobal(
        societe: _lastSociete!,
        periode: selectedPeriode,
        trimestre: selectedTrimestre,
      );
      print(
          '[GraphSig] Indicateurs chargés: ${indicateursResponse?.indicateurs.length} années');
      // Initialiser la sélection à tous les indicateurs si vide
      if (indicateursResponse != null && selectedIndicateurs.isEmpty) {
        final allIndics = <String>{};
        for (final annee in indicateursResponse!.indicateurs.keys) {
          final indicateursList = indicateursResponse!.indicateurs[annee]
              as List<SIGIndicateurGlobal>;
          for (final ind in indicateursList) {
            allIndics.add(ind.indicateur);
          }
        }
        selectedIndicateurs = allIndics.toList();
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('[GraphSig] Erreur lors du chargement: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
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
                    if (selectedPeriode == 'trimestre' &&
                        selectedTrimestre == null) {
                      selectedTrimestre = 1;
                    }
                    _loadData();
                  });
                },
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      showKeuros ? Color(0xFF65887a) : Color(0xFF00A9CA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  elevation: showKeuros ? 1 : 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  textStyle:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
                Text('Trimestre: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
    final anneesList = indicateursResponse!.indicateurs.keys
        .map((a) => int.parse(a))
        .toList()
      ..sort();
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
                color:
                    isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: color.withOpacity(isSelected ? 0.7 : 0.3),
                    width: 1.5),
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
                  Text(indicateur,
                      style: TextStyle(fontWeight: FontWeight.w500)),
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

    double total =
        montantsParAnnee.values.fold(0, (sum, val) => sum + val.abs());
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
                border: Border.all(
                    color: indicateurColors[i % indicateurColors.length]),
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
          Text('Type de graphique: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
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
                    final color = indicateurColors[
                        spot.barIndex % indicateurColors.length];
                    final value = spot.y;
                    String formatted =
                        showKeuros ? formatKeuro(value) : formatEuro(value);
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
