import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/screens/dashboard/axe/axe.dart';
import 'package:mobaitec_decision_making/screens/dashboard/global/global.dart';
import 'package:mobaitec_decision_making/screens/dashboard/mensuel/mensuel.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_mensuel/graph_mensuel.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_sig/graph_sig.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_sig_detail/graph_sig_detail.dart';
import 'package:mobaitec_decision_making/screens/dashboard/settings/settings.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';

enum Pages {
  parametres,
  global,
  axe,
  mensuel,
  graphMensuel,
  graphSig,
  graphSigDet,
  simulation
}

extension PagesLabel on Pages {
  String get label {
    switch (this) {
      case Pages.parametres:
        return 'Paramètres';
      case Pages.global:
        return 'Global';
      case Pages.axe:
        return 'Axe';
      case Pages.mensuel:
        return 'Mensuel';
      case Pages.graphMensuel:
        return 'Graph mensuel';
      case Pages.graphSig:
        return 'Graph SIG';
      case Pages.graphSigDet:
        return 'Graph SIG Dét';
      case Pages.simulation:
        return 'Simulation';
    }
  }
}

extension PagesIcon on Pages {
  IconData get icon {
    switch (this) {
      case Pages.parametres:
        return Icons.settings;
      case Pages.global:
        return Icons.public;
      case Pages.axe:
        return Icons.stacked_line_chart_rounded;
      case Pages.mensuel:
        return Icons.calendar_month;
      case Pages.graphMensuel:
        return Icons.show_chart;
      case Pages.graphSig:
        return Icons.bar_chart;
      case Pages.graphSigDet:
        return Icons.analytics;
      case Pages.simulation:
        return Icons.play_arrow;
    }
  }

  IconData get iconOutline {
    switch (this) {
      case Pages.parametres:
        return Icons.settings_outlined;
      case Pages.global:
        return Icons.public_outlined;
      case Pages.axe:
        return Icons.stacked_line_chart_outlined;
      case Pages.mensuel:
        return Icons.calendar_month_outlined;
      case Pages.graphMensuel:
        return Icons.show_chart_outlined;
      case Pages.graphSig:
        return Icons.bar_chart_outlined;
      case Pages.graphSigDet:
        return Icons.analytics_outlined;
      case Pages.simulation:
        return Icons.play_arrow_outlined;
    }
  }
}

extension NavigationDestinationsWidget on Pages {
  Widget get widget {
    switch (this) {
      case Pages.parametres:
        return SettingsScreen();
      case Pages.global:
        return Global();
      case Pages.axe:
        return Center(child: Text('Axe - En développement'));
      case Pages.mensuel:
        return Mensuel();
      case Pages.graphMensuel:
        return GraphMensuel();
      case Pages.graphSig:
        return GraphSig();
      case Pages.graphSigDet:
        return GraphSigDetail();
      case Pages.simulation:
        return Center(child: Text('Simulation - En développement'));
    }
  }
}

extension NavigationDestinationsTitles on Pages {
  String get title {
    switch (this) {
      case Pages.parametres:
        return 'Paramètres';
      case Pages.global:
        return 'Indicateurs Globaux';
      case Pages.axe:
        return 'Axes';
      case Pages.mensuel:
        return 'Indicateurs Mensuels';
      case Pages.graphMensuel:
        return 'Graphiques Mensuels';
      case Pages.graphSig:
        return 'Graphiques SIG';
      case Pages.graphSigDet:
        return 'Graphiques SIG Détaillés';
      case Pages.simulation:
        return 'Simulation';
    }
  }
}

class NavBar extends StatefulWidget {
  final Function changeWidget;
  final int selectedIndex;
  final bool isConnected;

  const NavBar({
    super.key,
    required this.changeWidget,
    required this.selectedIndex,
    this.isConnected = false,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    final List<Pages> normalPages =
        Pages.values.where((page) => page != Pages.parametres).toList();
    final settingsPage = Pages.parametres;

    return Container(
      color: Colors.grey.shade800,
      height: 70,
      child: Row(
        children: [
          if (!widget.isConnected)
            Expanded(
              child: HoverButton(
                page: settingsPage,
                isSelected:
                    widget.selectedIndex == Pages.values.indexOf(settingsPage),
                onTap: () {
                  widget.changeWidget(Pages.values.indexOf(settingsPage));
                },
              ),
            ),

          // Pages normales
          ...normalPages.map((page) {
            final index = Pages.values.indexOf(page);
            final isSelected = widget.selectedIndex == index;

            return Expanded(
              child: HoverButton(
                page: page,
                isSelected: isSelected,
                onTap: () {
                  widget.changeWidget(index);
                },
              ),
            );
          }).toList(),

          // Si connecté, paramètres à droite avec même largeur
          if (widget.isConnected)
            Expanded(
              child: HoverButton(
                page: settingsPage,
                isSelected:
                    widget.selectedIndex == Pages.values.indexOf(settingsPage),
                onTap: () {
                  widget.changeWidget(Pages.values.indexOf(settingsPage));
                },
              ),
            ),
        ],
      ),
    );
  }
}

class HoverButton extends StatefulWidget {
  final Pages page;
  final bool isSelected;
  final VoidCallback onTap;

  const HoverButton({
    Key? key,
    required this.page,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? Color(0xFF00A9CA).withOpacity(0.2)
        : isHovered
            ? Colors.grey.withOpacity(0.1)
            : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: double.infinity,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isSelected
                        ? widget.page.icon
                        : widget.page.iconOutline,
                    color: widget.isSelected
                        ? McaColors.bleu.color
                        : McaColors.gris.color,
                    size: widget.isSelected ? 30 : 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.page.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isSelected
                          ? McaColors.bleu.color
                          : Colors.grey,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
