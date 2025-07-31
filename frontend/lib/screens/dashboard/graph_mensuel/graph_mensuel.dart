import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/table_header.dart';
import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';
import 'package:mobaitec_decision_making/services/data/unified_sig_service.dart';
import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';
import 'package:mobaitec_decision_making/services/data/local_data_service.dart';

class GraphMensuel extends StatefulWidget {
  @override
  State<GraphMensuel> createState() => _GraphMensuelState();
}

class _GraphMensuelState extends State<GraphMensuel> {
  String _formatNumberWithSpaces(num value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String selectedAnnee = (DateTime.now().year - 1).toString();
  // Liste des indicateurs sélectionnés à afficher
  List<String> selectedIndicateurs = [];
  String? _lastSociete;
  List<String> allAnnees = [];
  bool isLoading = false;
  bool isKEuros = false; // Affichage en K€uros
  String chartType = 'line'; // 'line' ou 'pie'
  String? selectedIndicateurForPie; // Pour le pie chart

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ne faire le check qu'une seule fois par build
    if (!_isInitialized) {
      _isInitialized = true;
      final keycloakProvider =
          Provider.of<KeycloakProvider>(context, listen: true);
      final societe = keycloakProvider.selectedCompany;

      if (societe != null && societe != _lastSociete) {
        print(
            '[GraphMensuel] Changement de société détecté: $_lastSociete -> $societe');
        _lastSociete = societe;

        // Réinitialiser directement sans setState
        indicateursResponse = null;
        selectedIndicateurForPie = null;

        // Planifier le chargement pour le prochain frame
        Future.microtask(() {
          if (mounted) {
            _loadAnnees();
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

  Future<void> _loadAnnees() async {
    final keycloakProvider =
        Provider.of<KeycloakProvider>(context, listen: false);
    final societe = keycloakProvider.selectedCompany;
    
    if (societe == null) {
      print('[GraphMensuel] Aucune société sélectionnée');
      return;
    }
    
    print('[GraphMensuel] Début du chargement pour $societe');
    keycloakProvider.setDataReloading(true);

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      // Utiliser LocalDataService pour obtenir les années disponibles
      final availableYears = LocalDataService.getAvailableYears(societe);
      allAnnees = availableYears.map((year) => year.toString()).toList();
      
      print('[GraphMensuel] Années disponibles pour $societe: $allAnnees');

      if (!mounted) return;
      setState(() {
        selectedAnnee = allAnnees.isNotEmpty ? allAnnees.first : '';
        isLoading = false;
      });
      _loadData();
    } catch (e) {
      print('[GraphMensuel] Erreur lors du chargement des années: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      keycloakProvider.setDataReloading(false);
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
      print('[GraphMensuel] Chargement des données depuis les données locales');

      indicateursResponse = await UnifiedSIGService.fetchIndicateursMensuel(
          societe: _lastSociete!, annee: anneeInt);
      print(
          '[GraphMensuel] Indicateurs chargés: ${(indicateursResponse?['mois'] as Map<String, dynamic>?)?.length ?? 0} mois');
      // Initialiser la sélection à tous les indicateurs si vide
      if (indicateursResponse != null && selectedIndicateurs.isEmpty) {
        final allIndics = <String>{};
        final moisData = indicateursResponse!['mois'] as Map<String, dynamic>?;
        if (moisData != null) {
          for (final mois in moisData.keys) {
            final indicateursList = moisData[mois] as List<dynamic>?;
            if (indicateursList != null) {
              for (final ind in indicateursList) {
                final indicateur = ind['indicateur'] as String?;
                if (indicateur != null) {
                  allIndics.add(indicateur);
                }
              }
            }
          }
        }
        selectedIndicateurs = allIndics.toList();
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('[GraphMensuel] Erreur lors du chargement: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAnneeButtons() {
    if (allAnnees.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
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
                      _loadData();
                    });
                  },
                  child: Text(annee,
                      style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isKEuros ? Color(0xFF65887a) : Color(0xFF00A9CA),
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
          ],
        ),
      ),
    );
  }

  List<String> _getOrderedMois() {
    if (indicateursResponse == null) return [];
    final mois = indicateursResponse!['mois'] as Map<String, dynamic>?;
    if (mois == null) return [];

    final moisList = mois.keys.map((m) => int.parse(m)).toList()..sort();
    return moisList.map((m) => m.toString()).toList();
  }

  List<String> _getIndicateurNames() {
    if (indicateursResponse == null) return [];
    final Set<String> indicateurs = {};
    final mois = indicateursResponse!['mois'] as Map<String, dynamic>?;
    if (mois == null) return [];

    for (final moisIndicateurs in mois.values) {
      final indicateursList = moisIndicateurs as List<dynamic>?;
      if (indicateursList != null) {
        for (final ind in indicateursList) {
          final indicateur = ind['indicateur'] as String?;
          if (indicateur != null) {
            indicateurs.add(indicateur);
          }
        }
      }
    }
    return indicateurs.toList()..sort();
  }

  Map<String, Map<String, double>> _getIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (indicateursResponse == null) return data;

    final mois = indicateursResponse!['mois'] as Map<String, dynamic>?;
    if (mois == null) return data;

    for (final moisEntry in mois.entries) {
      final moisKey = moisEntry.key;
      final indicateurs = moisEntry.value as List<dynamic>?;

      if (indicateurs != null) {
        for (final ind in indicateurs) {
          final indicateur = ind['indicateur'] as String?;
          final valeur = ind['valeur'] as double?;
          if (indicateur != null && valeur != null) {
            data.putIfAbsent(indicateur, () => {});
            data[indicateur]![moisKey] = valeur;
          }
        }
      }
    }
    return data;
  }

  List<LineChartBarData> _getLineChartBarData() {
    final indicateurData = _getIndicateurData();
    final mois = _getOrderedMois();
    final indicateurs = selectedIndicateurs;
    List<LineChartBarData> lines = [];
    for (int i = 0; i < indicateurs.length; i++) {
      final indicateur = indicateurs[i];
      final montantsParMois = indicateurData[indicateur] ?? {};
      List<FlSpot> spots = [];
      for (int j = 0; j < mois.length; j++) {
        final moisKey = mois[j];
        final montant = montantsParMois[moisKey] ?? 0;
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
    final mois = _getOrderedMois();

    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 80,
          getTitlesWidget: (value, meta) {
            if (isKEuros) {
              return Text('${(value / 1000).toStringAsFixed(1)} K€',
                  style: TextStyle(fontSize: 10));
            } else {
              return Text('${_formatNumberWithSpaces(value)} €',
                  style: TextStyle(fontSize: 10));
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
            if (index >= 0 && index < mois.length) {
              final moisKey = mois[index];
              return Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  moisKey,
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
    for (final montantsParMois in indicateurData.values) {
      for (final montant in montantsParMois.values) {
        if (montant < min) min = montant;
      }
    }
    return min * 1.1; // Ajouter 10% de marge
  }

  double _getMaxY() {
    final indicateurData = _getIndicateurData();
    double max = 0;
    for (final montantsParMois in indicateurData.values) {
      for (final montant in montantsParMois.values) {
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
    final mois = _getOrderedMois();
    if (mois.isEmpty || selectedIndicateurForPie == null) return [];

    final indicateurData = _getIndicateurData();
    final montantsParMois = indicateurData[selectedIndicateurForPie!] ?? {};

    double total =
        montantsParMois.values.fold(0, (sum, val) => sum + val.abs());
    if (total == 0) return [];

    List<PieChartSectionData> sections = [];
    for (int i = 0; i < mois.length; i++) {
      final moisKey = mois[i];
      final montant = montantsParMois[moisKey] ?? 0;
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
                'M${moisKey}',
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
    final mois = _getOrderedMois();
    if (mois.isEmpty || selectedIndicateurForPie == null) return SizedBox();

    final indicateurData = _getIndicateurData();
    final montantsParMois = indicateurData[selectedIndicateurForPie!] ?? {};

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: mois.asMap().entries.map((entry) {
          final index = entry.key;
          final moisKey = entry.value;
          final montant = montantsParMois[moisKey] ?? 0;
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
                'Mois $moisKey: ${montant.toStringAsFixed(0)}€',
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
          'Aucune donnée disponible pour cette année',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    final mois = _getOrderedMois();
    if (mois.isEmpty) {
      return Center(
        child: Text(
          'Aucun mois disponible',
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
            maxX: (mois.length - 1).toDouble(),
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
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final value = spot.y;
                    String formatted;
                    if (isKEuros) {
                      formatted = '${(value / 1000).toStringAsFixed(1)} K€';
                    } else {
                      formatted = '${_formatNumberWithSpaces(value)} €';
                    }
                    return LineTooltipItem(
                      formatted,
                      TextStyle(
                        color: spot.bar.color ?? Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
        // Boutons de sélection d'année
        _buildAnneeButtons(),

        // Section du graphique
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TableHeader(title: 'Graphique Mensuel des Indicateurs SIG'),

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
