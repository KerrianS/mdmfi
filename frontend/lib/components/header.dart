import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/navbar.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/services/data/societe_sync_service.dart';

class DashboardHeader extends StatelessWidget {
  final Pages currentPage;
  final VoidCallback? onLogout;
  final bool isKeycloakConnected;
  const DashboardHeader(
      {Key? key,
      required this.currentPage,
      this.onLogout,
      this.isKeycloakConnected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                currentPage.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
              // Sélecteur de société (visible si sociétés disponibles avec données locales)
              Consumer<KeycloakProvider>(
                builder: (context, keycloakProvider, _) {
                  // Filtrer les sociétés qui ont des données locales
                  final societesWithData = keycloakProvider.accessibleCompanies
                      .where((s) =>
                          SocieteSyncService.hasLocalDataForKeycloakSociete(
                              s['name']))
                      .toList();

                  print(
                      '[Header] sociétés avec données locales = ${societesWithData.map((s) => s['name'])}');
                  print(
                      '[Header] société sélectionnée = ${keycloakProvider.selectedCompany ?? 'Aucune'}');

                  if (societesWithData.isEmpty) return SizedBox.shrink();

                  return Row(
                    children: [
                      const Text('Société : ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: keycloakProvider.selectedCompany,
                        items: societesWithData
                            .map((s) => DropdownMenuItem(
                                  value: s['name'],
                                  child: Text(s['name']!),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            keycloakProvider.setSelectedCompany(value);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/mobaitec-logo.png',
                  width: 70,
                  height: 70,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 40,
                    child: VerticalDivider(
                      thickness: .5,
                      color: McaColors.gris.color,
                    ),
                  ),
                ),
                // Affichage du logo dynamique de la société sélectionnée
                Consumer<KeycloakProvider>(
                  builder: (context, keycloakProvider, _) {
                    final selectedCompany = keycloakProvider.selectedCompany;
                    final company =
                        keycloakProvider.accessibleCompanies.firstWhere(
                      (c) => c['name'] == selectedCompany,
                      orElse: () => <String, String>{},
                    );
                    final logoUrl = company['logoURL'];
                    if (logoUrl != null &&
                        logoUrl.isNotEmpty &&
                        logoUrl != 'null') {
                      return Padding(
                        padding: const EdgeInsets.only(left: 0),
                        child: Container(
                          width: 180,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 70,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors
                                      .white, // Arrière-plan blanc rectangle
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color(
                                            0xFFE0E0E0) // Blanc cassé en mode sombre
                                        : Colors
                                            .transparent, // Transparent en mode clair
                                    width: 2,
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  logoUrl,
                                  width: 150,
                                  height: 85,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image_not_supported),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                ),
                if (onLogout != null && isKeycloakConnected) ...[
                  SizedBox(width: 16),
                  IconButton(
                    onPressed: onLogout,
                    icon: Icon(Icons.logout,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 24),
                    tooltip: 'Se déconnecter',
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    splashRadius: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
