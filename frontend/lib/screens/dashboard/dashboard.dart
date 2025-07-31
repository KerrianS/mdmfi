import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mobaitec_decision_making/components/header.dart';
import 'package:mobaitec_decision_making/components/navbar.dart';
import 'package:mobaitec_decision_making/screens/dashboard/global/global.dart';
import 'package:mobaitec_decision_making/screens/dashboard/mensuel/mensuel.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_sig/graph_sig.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_mensuel/graph_mensuel.dart';
import 'package:mobaitec_decision_making/screens/dashboard/graph_sig_detail/graph_sig_detail.dart';
import 'package:mobaitec_decision_making/screens/dashboard/settings/settings.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_service.dart';
import 'package:mobaitec_decision_making/services/theme/swipe_provider.dart';
import 'package:mobaitec_decision_making/services/data/societe_sync_service.dart';
import 'package:provider/provider.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  late PageController _pageController;
  int _pageIndex = 0;
  Pages currentPage = Pages.parametres;

  final List<PageItem> _pages = [
    PageItem(Pages.parametres, SettingsScreen()),
    PageItem(Pages.global, Global()),
    PageItem(Pages.axe, Center(child: Text('Axe - En développement'))),
    PageItem(Pages.mensuel, Mensuel()),
    PageItem(Pages.graphMensuel, GraphMensuel()),
    PageItem(Pages.graphSig, GraphSig()),
    PageItem(Pages.graphSigDet, GraphSigDetail()),
    PageItem(
        Pages.simulation, Center(child: Text('Simulation - En développement'))),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
    print('[Dashboard] initState appelé');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void changePage(int index) {
    setState(() {
      _pageIndex = index;
      currentPage = _pages[index].page;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(covariant DashBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronise le PageController avec la page courante à chaque rebuild
    if (_pageController.hasClients &&
        _pageController.page?.round() != _pageIndex) {
      _pageController.jumpToPage(_pageIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keycloakProvider =
        Provider.of<KeycloakProvider>(context, listen: false);
    // On ne fetch que si connecté et sociétés pas encore chargées
    if (keycloakProvider.isConnected &&
        keycloakProvider.accessibleCompanies.isEmpty) {
      print('[Dashboard] Utilisateur connecté, chargement sociétés...');
      final keycloakService = KeycloakService();
      final token = keycloakProvider.accessToken ?? '';
      final userGroups = keycloakProvider.userGroups ?? [];
      keycloakService
          .fetchAccessibleCompanies(token, userGroups)
          .then((companies) {
        print('[Dashboard] sociétés récupérées: ' + companies.toString());
        keycloakProvider.setAccessibleCompanies(companies);
        if (companies.isNotEmpty) {
          // Sélectionner une société qui a des données locales
          String? selectedCompany;
          for (final company in companies) {
            final companyName = company['name'];
            if (companyName != null &&
                SocieteSyncService.hasLocalDataForKeycloakSociete(
                    companyName)) {
              selectedCompany = companyName;
              break;
            }
          }

          // Si aucune société avec données locales, prendre la première
          if (selectedCompany == null && companies.isNotEmpty) {
            selectedCompany = companies.first['name']!;
          }

          if (selectedCompany != null) {
            keycloakProvider.setSelectedCompany(selectedCompany);
            print(
                '[Dashboard] société sélectionnée par défaut: $selectedCompany');
          }
        }
      });
    }
    // Suppression de la logique qui force la page globale
    // L'utilisateur peut maintenant rester sur l'écran de son choix
  }

  @override
  Widget build(BuildContext context) {
    final keycloakProvider = Provider.of<KeycloakProvider>(context);
    final swipeProvider = Provider.of<SwipeProvider>(context);
    // Synchronise le PageController à chaque rebuild si besoin
    if (_pageController.hasClients &&
        _pageController.page?.round() != _pageIndex) {
      _pageController.jumpToPage(_pageIndex);
    }
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                DashboardHeader(
                  currentPage: currentPage,
                  onLogout: keycloakProvider.isConnected
                      ? keycloakProvider.clearAuth
                      : null,
                  isKeycloakConnected: keycloakProvider.isConnected,
                ),
                Expanded(
                  child: swipeProvider.swipeEnabled
                      ? ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: PageView(
                            controller: _pageController,
                            scrollDirection: Axis.horizontal,
                            onPageChanged: (index) {
                              setState(() {
                                _pageIndex = index;
                                currentPage = _pages[index].page;
                              });
                            },
                            children: _pages.map((p) => p.widget).toList(),
                          ),
                        )
                      : _pages[_pageIndex].widget,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBar(
        changeWidget: changePage,
        selectedIndex: _pageIndex,
        isConnected: keycloakProvider.isConnected,
      ),
    );
  }
}

class PageItem {
  final Pages page;
  final Widget widget;

  PageItem(this.page, this.widget);
}
