import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/table_header.dart';
import 'package:mobaitec_decision_making/models/SIGModel.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/utils/shimmer_utils.dart';
import 'package:mobaitec_decision_making/services/data/unified_sig_service.dart';
import 'package:mobaitec_decision_making/components/adaptive_table_container.dart';

class GraphSigDetail extends StatefulWidget {
  @override
  State<GraphSigDetail> createState() => _GraphSigDetailState();
}

class _GraphSigDetailState extends State<GraphSigDetail> {
  String selectedPeriode = 'Année civile';
  int? selectedTrimestre;
  String? selectedIndicateur;
  String? _lastSociete;
  bool isLoading = false;
  String chartType = 'line'; // 'line' ou 'pie'
  String? selectedSousIndicateurForPie; // Pour le pie chart
  bool showKeuros = false; // Affichage K€uros
  dynamic indicateursResponse;
  dynamic sousIndicsResponse;
  List<String> selectedSousIndicateurs = [];
  // Couleurs pour les différents sous-indicateurs
  final List<Color> sousIndicateurColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
  ];

  String _formatNumberWithSpaces(num value) {
    String s = value.abs().toStringAsFixed(0);
    String withSpaces =
        s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ' ');
    return withSpaces;
  }

  String _formatValue(num value) {
    if (showKeuros) {
      return '${_formatNumberWithSpaces((value / 1000).round())} K€';
    } else {
      return '${_formatNumberWithSpaces(value)} €';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keycloakProvider =
        Provider.of<KeycloakProvider>(context); // RETIRER listen: false
    final societe = keycloakProvider.selectedCompany;

    if (societe != null && societe != _lastSociete) {
      print(
          '[GraphSigDetail] Changement de société détecté: $_lastSociete -> $societe');
      _lastSociete = societe;

      // Réinitialiser les données et l'état
      setState(() {
        indicateursResponse = null;
        sousIndicsResponse = null;
        selectedIndicateur = null;
        selectedSousIndicateurForPie = null;
      });

      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_lastSociete == null) return;

    print(
        '[GraphSigDetail] Début du chargement des données pour $_lastSociete');

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      print(
          '[GraphSigDetail] Chargement des données depuis les données locales');

      indicateursResponse = await UnifiedSIGService.fetchIndicateursGlobal(
        societe: _lastSociete!,
        periode: _getPeriodeParam(),
        trimestre: selectedTrimestre,
      );
      print(
          '[GraphSigDetail] Indicateurs chargés: ${(indicateursResponse?['indicateurs'] as Map<String, dynamic>?)?.length ?? 0} années');

      sousIndicsResponse = await UnifiedSIGService.fetchSousIndicateursGlobal(
        societe: _lastSociete!,
        periode: _getPeriodeParam(),
        trimestre: selectedTrimestre,
      );
      print('[GraphSigDetail] Sous-indicateurs chargés');

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('[GraphSigDetail] Erreur lors du chargement: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getPeriodeParam() {
    switch (selectedPeriode) {
      case 'Année civile':
        return 'annee';
      case 'Trimestre':
        return 'trimestre';
      default:
        return 'annee';
    }
  }

  Widget _buildPeriodeButtons() {
    final periodes = ['Année civile', 'Trimestre'];
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: isSelected ? 2 : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedPeriode = periode;
                        if (periode != 'Trimestre') {
                          selectedTrimestre = null;
                        }
                        _loadData();
                      });
                    },
                    child: Text(periode,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
              SizedBox(width: 8),
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
              if (selectedPeriode == 'Trimestre') ...[
                SizedBox(width: 16),
                DropdownButton<int>(
                  value: selectedTrimestre,
                  hint: Text('Sélectionner trimestre'),
                  items: [1, 2, 3, 4].map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text('T$t'),
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
            ],
          ),
          // Message d'information pour les trimestres
          if (selectedPeriode == 'Trimestre') ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.green.shade700, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✅ Données trimestrielles calculées à partir des données mensuelles.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicateurSelector() {
    final indicateurs = _getIndicateurNames();
    final libelles = _getIndicateurLibelles();
    if (indicateurs.isEmpty) return SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Indicateur: ', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: selectedIndicateur,
              hint: Text('Sélectionner un indicateur'),
              isExpanded: true,
              items: indicateurs.map((indicateur) {
                final libelle = libelles[indicateur] ?? indicateur;
                return DropdownMenuItem(
                  value: indicateur,
                  child: Text('$indicateur - $libelle',
                      style: TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedIndicateur = value;
                  if (chartType == 'pie' &&
                      selectedSousIndicateurForPie == null) {
                    final sousIndicateurs = _getSousIndicateurNames();
                    if (sousIndicateurs.isNotEmpty) {
                      selectedSousIndicateurForPie = sousIndicateurs.first;
                    }
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getOrderedAnnees() {
    if (sousIndicsResponse == null) return [];
    final sousIndicateursData =
        sousIndicsResponse!['sousIndicateurs'] as Map<String, dynamic>?;
    if (sousIndicateursData == null) return [];

    final anneesList =
        sousIndicateursData.keys.map((a) => int.parse(a)).toList()..sort();
    return anneesList.map((a) => a.toString()).toList();
  }

  List<String> _getIndicateurNames() {
    if (indicateursResponse == null) return [];
    final Set<String> indicateurs = {};
    final indicateursData =
        indicateursResponse!['indicateurs'] as Map<String, dynamic>?;
    if (indicateursData == null) return [];

    for (final anneeIndicateurs in indicateursData.values) {
      final indicateursList = anneeIndicateurs as List<dynamic>?;
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

  Map<String, String> _getIndicateurLibelles() {
    if (indicateursResponse == null) return {};
    final Map<String, String> libelles = {};
    final indicateursData =
        indicateursResponse!['indicateurs'] as Map<String, dynamic>?;
    if (indicateursData == null) return {};

    for (final anneeIndicateurs in indicateursData.values) {
      final indicateursList = anneeIndicateurs as List<dynamic>?;
      if (indicateursList != null) {
        for (final ind in indicateursList) {
          final indicateur = ind['indicateur'] as String?;
          final libelle = ind['libelle'] as String?;
          if (indicateur != null && libelle != null) {
            libelles[indicateur] = libelle;
          }
        }
      }
    }
    return libelles;
  }

  List<String> _getSousIndicateurNames() {
    if (sousIndicsResponse == null || selectedIndicateur == null) return [];
    final Set<String> sousIndicateurs = {};
    final sousIndicateursData =
        sousIndicsResponse!['sousIndicateurs'] as Map<String, dynamic>?;
    if (sousIndicateursData == null) return [];

    for (final anneeSousIndicateurs in sousIndicateursData.values) {
      final anneeData = anneeSousIndicateurs as Map<String, dynamic>?;
      if (anneeData != null) {
        final sousIndicsForIndicateur =
            anneeData[selectedIndicateur!] as List<dynamic>? ?? [];
        for (final sousInd in sousIndicsForIndicateur) {
          final sousIndicateur = sousInd['sousIndicateur'] as String?;
          if (sousIndicateur != null) {
            sousIndicateurs.add(sousIndicateur);
          }
        }
      }
    }
    return sousIndicateurs.toList()..sort();
  }

  Map<String, String> _getSousIndicateurLibelles() {
    if (sousIndicsResponse == null || selectedIndicateur == null) return {};
    final Map<String, String> libelles = {};
    final sousIndicateursData =
        sousIndicsResponse!['sousIndicateurs'] as Map<String, dynamic>?;
    if (sousIndicateursData == null) return {};

    for (final anneeSousIndicateurs in sousIndicateursData.values) {
      final anneeData = anneeSousIndicateurs as Map<String, dynamic>?;
      if (anneeData != null) {
        final sousIndicsForIndicateur =
            anneeData[selectedIndicateur!] as List<dynamic>? ?? [];
        for (final sousInd in sousIndicsForIndicateur) {
          final sousIndicateur = sousInd['sousIndicateur'] as String?;
          final libelle = sousInd['libelle'] as String?;
          if (sousIndicateur != null && libelle != null) {
            libelles[sousIndicateur] = libelle;
          }
        }
      }
    }
    return libelles;
  }

  Map<String, Map<String, double>> _getSousIndicateurData() {
    final Map<String, Map<String, double>> data = {};
    if (sousIndicsResponse == null || selectedIndicateur == null) return data;

    final sousIndicateursData =
        sousIndicsResponse!['sousIndicateurs'] as Map<String, dynamic>?;
    if (sousIndicateursData == null) return data;

    for (final anneeEntry in sousIndicateursData.entries) {
      final annee = anneeEntry.key;
      final anneeData = anneeEntry.value as Map<String, dynamic>?;
      if (anneeData != null) {
        final sousIndicateursForIndicateur =
            anneeData[selectedIndicateur!] as List<dynamic>? ?? [];

        for (final sousInd in sousIndicateursForIndicateur) {
          final sousIndicateur = sousInd['sousIndicateur'] as String?;
          final montant = (sousInd['montant'] as num?)?.toDouble() ?? 0.0;
          if (sousIndicateur != null) {
            data.putIfAbsent(sousIndicateur, () => {});
            data[sousIndicateur]![annee] = montant;
          }
        }
      }
    }
    return data;
  }

  List<LineChartBarData> _getLineChartBarData() {
    final sousIndicateurData = _getSousIndicateurData();
    final annees = _getOrderedAnnees();
    final sousIndicateurs = selectedSousIndicateurs.isNotEmpty
        ? selectedSousIndicateurs
        : _getSousIndicateurNames();
    List<LineChartBarData> lines = [];
    for (int i = 0; i < sousIndicateurs.length; i++) {
      final sousIndicateur = sousIndicateurs[i];
      final montantsParAnnee = sousIndicateurData[sousIndicateur] ?? {};
      List<FlSpot> spots = [];
      for (int j = 0; j < annees.length; j++) {
        final anneeKey = annees[j];
        final montant = montantsParAnnee[anneeKey] ?? 0;
        final yValue = showKeuros ? montant / 1000 : montant;
        spots.add(FlSpot(j.toDouble(), yValue));
      }
      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: sousIndicateurColors[i % sousIndicateurColors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 4,
              color: sousIndicateurColors[i % sousIndicateurColors.length],
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
            return Text(_formatValue(value), style: TextStyle(fontSize: 10));
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
    final sousIndicateurData = _getSousIndicateurData();
    double min = 0;
    for (final montantsParAnnee in sousIndicateurData.values) {
      for (final montant in montantsParAnnee.values) {
        if (montant < min) min = montant;
      }
    }
    return min * 1.1; // Ajouter 10% de marge
  }

  double _getMaxY() {
    final sousIndicateurData = _getSousIndicateurData();
    double max = 0;
    for (final montantsParAnnee in sousIndicateurData.values) {
      for (final montant in montantsParAnnee.values) {
        if (montant > max) max = montant;
      }
    }
    return max * 1.1; // Ajouter 10% de marge
  }

  Widget _buildLegend() {
    final sousIndicateurs = _getSousIndicateurNames();
    final libelles = _getSousIndicateurLibelles();
    if (sousIndicateurs.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: sousIndicateurs.asMap().entries.map((entry) {
          final index = entry.key;
          final sousIndicateur = entry.value;
          final libelle = libelles[sousIndicateur] ?? sousIndicateur;
          final color =
              sousIndicateurColors[index % sousIndicateurColors.length];
          final isSelected = selectedSousIndicateurs.isEmpty ||
              selectedSousIndicateurs.contains(sousIndicateur);
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                if (selectedSousIndicateurs.isEmpty) {
                  // Si tout est affiché, on ne garde que celui cliqué
                  selectedSousIndicateurs = [sousIndicateur];
                } else if (isSelected) {
                  selectedSousIndicateurs.remove(sousIndicateur);
                  // Si plus rien n'est sélectionné, on réaffiche tout
                  if (selectedSousIndicateurs.isEmpty) {
                    selectedSousIndicateurs = [];
                  }
                } else {
                  selectedSousIndicateurs.add(sousIndicateur);
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
                  Text(libelle, style: TextStyle(fontWeight: FontWeight.w500)),
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
    if (annees.isEmpty || selectedSousIndicateurForPie == null) return [];

    final sousIndicateurData = _getSousIndicateurData();
    final montantsParAnnee =
        sousIndicateurData[selectedSousIndicateurForPie!] ?? {};

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
            color: sousIndicateurColors[i % sousIndicateurColors.length],
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
                    color:
                        sousIndicateurColors[i % sousIndicateurColors.length]),
              ),
              child: Text(
                anneeKey,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: sousIndicateurColors[i % sousIndicateurColors.length],
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
    if (annees.isEmpty || selectedSousIndicateurForPie == null)
      return SizedBox();

    final sousIndicateurData = _getSousIndicateurData();
    final montantsParAnnee =
        sousIndicateurData[selectedSousIndicateurForPie!] ?? {};

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: annees.asMap().entries.map((entry) {
          final index = entry.key;
          final anneeKey = entry.value;
          final montant = montantsParAnnee[anneeKey] ?? 0;
          final color =
              sousIndicateurColors[index % sousIndicateurColors.length];

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
                '$anneeKey: ${_formatValue(montant)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    final libelles = _getSousIndicateurLibelles();
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
                if (chartType == 'pie' &&
                    selectedSousIndicateurForPie == null) {
                  final sousIndicateurs = _getSousIndicateurNames();
                  if (sousIndicateurs.isNotEmpty) {
                    selectedSousIndicateurForPie = sousIndicateurs.first;
                  }
                }
              });
            },
          ),
          if (chartType == 'pie') ...[
            SizedBox(width: 16),
            Text('Sous-indicateur: ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedSousIndicateurForPie,
              items: _getSousIndicateurNames().map((sousIndicateur) {
                final libelle = libelles[sousIndicateur] ?? sousIndicateur;
                return DropdownMenuItem(
                  value: sousIndicateur,
                  child: Text('$sousIndicateur - $libelle',
                      style: TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSousIndicateurForPie = value;
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
    if (sections.isEmpty || selectedSousIndicateurForPie == null) {
      return Center(
        child: Text(
          'Aucune donnée disponible pour ce sous-indicateur',
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
    if (sousIndicsResponse == null ||
        selectedIndicateur == null ||
        _getSousIndicateurNames().isEmpty) {
      return Center(
        child: Text(
          selectedIndicateur == null
              ? 'Veuillez sélectionner un indicateur'
              : 'Aucune donnée disponible pour cet indicateur',
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
        // Boutons de sélection de période
        _buildPeriodeButtons(),

        // Section du graphique
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TableHeader(title: 'Graphique des Sous-Indicateurs SIG'),

                // Sélecteur d'indicateur
                if (!isLoading && _getIndicateurNames().isNotEmpty)
                  _buildIndicateurSelector(),

                // Sélecteur de type de graphique
                if (!isLoading &&
                    selectedIndicateur != null &&
                    _getSousIndicateurNames().isNotEmpty)
                  _buildChartTypeSelector(),

                // Légende appropriée selon le type de graphique
                if (!isLoading &&
                    selectedIndicateur != null &&
                    _getSousIndicateurNames().isNotEmpty)
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
