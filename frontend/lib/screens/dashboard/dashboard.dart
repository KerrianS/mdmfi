import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mobaitec_decision_making/components/header.dart';
import 'package:mobaitec_decision_making/components/navbar.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_service.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/services/theme/swipe_provider.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  Pages currentPage = Pages.parametres; // Par défaut, page settings (parametres) au lancement
  int _pageIndex = Pages.values.indexOf(Pages.parametres);
  final List<Pages> _pages = Pages.values;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print('[Dashboard] initState appelé');
    _pageController = PageController(initialPage: _pageIndex);
    // NE PAS charger la liste des sociétés accessibles tant que l'utilisateur n'est pas connecté !
    // On déplace la logique dans didChangeDependencies pour ne lancer le fetch qu'après connexion.
  }

  void changePage(Pages newPage) {
    setState(() {
      currentPage = newPage;
      _pageIndex = _pages.indexOf(newPage);
    });
    // Animation fluide vers la nouvelle page si le swipe est activé
    final swipeProvider = Provider.of<SwipeProvider>(context, listen: false);
    if (swipeProvider.swipeEnabled && _pageController.hasClients) {
      _pageController.animateToPage(
        _pageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant DashBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronise le PageController avec la page courante à chaque rebuild
    if (_pageController.hasClients && _pageController.page?.round() != _pageIndex) {
      _pageController.jumpToPage(_pageIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keycloakProvider = Provider.of<KeycloakProvider>(context, listen: false);
    // On ne fetch que si connecté et sociétés pas encore chargées
    if (keycloakProvider.isConnected && keycloakProvider.accessibleCompanies.isEmpty) {
      print('[Dashboard] Utilisateur connecté, chargement sociétés...');
      final keycloakService = KeycloakService();
      final token = keycloakProvider.accessToken ?? '';
      final userGroups = keycloakProvider.userGroups ?? [];
      keycloakService.fetchAccessibleCompanies(token, userGroups).then((companies) {
        print('[Dashboard] sociétés récupérées: ' + companies.toString());
        keycloakProvider.setAccessibleCompanies(companies);
        if (companies.isNotEmpty) {
          keycloakProvider.setSelectedCompany(companies.first['name']!);
          print('[Dashboard] société sélectionnée par défaut: ' + companies.first['name']!);
        }
      });
    }
    // Si connecté, forcer la page globale
    if (keycloakProvider.isConnected && currentPage != Pages.global) {
      setState(() {
        currentPage = Pages.global;
        _pageIndex = Pages.values.indexOf(Pages.global);
        _pageController.jumpToPage(_pageIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keycloakProvider = Provider.of<KeycloakProvider>(context);
    final swipeProvider = Provider.of<SwipeProvider>(context);
    // Synchronise le PageController à chaque rebuild si besoin
    if (_pageController.hasClients && _pageController.page?.round() != _pageIndex) {
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
                  onLogout: keycloakProvider.isConnected ? keycloakProvider.clearAuth : null,
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
                                currentPage = _pages[index];
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
