import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_service.dart';
import 'package:provider/provider.dart';
import 'package:mobaitec_decision_making/services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/services/theme/theme_provider.dart';
import 'package:mobaitec_decision_making/services/theme/swipe_provider.dart';
import 'package:mobaitec_decision_making/services/cache/navision_service_cache.dart';
import 'package:mobaitec_decision_making/services/cache/odoo_service_cache.dart';
import 'package:mobaitec_decision_making/models/NavisionSIGModel.dart';
import 'package:mobaitec_decision_making/models/OdooSIGModel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _userName;
  List<String>? _userGroups;
  String? _accessToken;
  bool? _swipeEnabled;

  void _showThemeChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changement de thème'),
        content: Text('Le changement de thème global nécessite un provider ou une logique dédiée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginKeycloak() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final keycloakService = KeycloakService();
    try {
      final token = await keycloakService.login(
        username: _emailController.text,
        password: _passwordController.text,
      );
      final userInfo = await keycloakService.getUserInfo(token);
      Provider.of<KeycloakProvider>(context, listen: false).setAuth(
        accessToken: token,
        userName: userInfo.name,
        userGroups: userInfo.groups,
        userRoles: userInfo.roles,
      );
      setState(() {
        _userName = userInfo.name;
        _userGroups = userInfo.groups;
        _accessToken = token;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion réussie !')),
      );
    } catch (e) {
      setState(() {
        _error = 'Échec de la connexion :  {e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logoutKeycloak() async {
    final keycloakProvider = Provider.of<KeycloakProvider>(context, listen: false);
    final token = keycloakProvider.accessToken ?? _accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        await KeycloakService().logout(token);
      } catch (e) {
        // Optionnel : afficher une erreur ou un message
      }
    }
    keycloakProvider.clearAuth();
    setState(() {
      _userName = null;
      _userGroups = null;
      _accessToken = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keycloakProvider = Provider.of<KeycloakProvider>(context);
    final isConnected = keycloakProvider.isConnected;
    final userName = keycloakProvider.userName ?? _userName;
    final userGroups = keycloakProvider.userGroups ?? _userGroups;
    final userRoles = keycloakProvider.userRoles ?? [];
    final isAdmin = keycloakProvider.isAdmin;
    final isClient = keycloakProvider.isClient;
    final hasMDMFi = keycloakProvider.hasMDMFi;
    if (isConnected && userName != null) {
      // Écran après connexion
      final themeProvider = Provider.of<ThemeProvider>(context);
      final swipeProvider = Provider.of<SwipeProvider>(context);
      bool isDarkMode = themeProvider.isDarkMode;
      bool swipeEnabled = swipeProvider.swipeEnabled;
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo société dynamique ou icône par défaut
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white, // Arrière-plan blanc rond
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Color(0xFFE0E0E0) // Blanc cassé en mode sombre
                          : Colors.transparent, // Transparent en mode clair
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user, size: 56, color: Colors.green),
                  ),
                ),
                SizedBox(height: 16),
                Text('Bienvenue, $userName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ajoutez ici la logique de mise à jour des données
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mise à jour des données en cours...')),
                    );
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Mise à jour des données'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00A9CA),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    if (isMobile) {
                      // Version mobile : tout en colonne
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Préférences
                          _PreferencesCard(
                            userName: userName,
                            email: _emailController.text,
                            isDarkMode: isDarkMode,
                            onThemeChanged: themeProvider.setDarkMode,
                            swipeEnabled: swipeEnabled,
                            onSwipeChanged: swipeProvider.setSwipeEnabled,
                          ),
                          SizedBox(height: 20),
                          // Rôles et Sociétés combinés
                          _RolesAndCompaniesCard(
                            isClient: isClient, 
                            isAdmin: isAdmin, 
                            hasMDMFi: hasMDMFi,
                            userGroups: userGroups,
                          ),
                        ],
                      );
                    } else {
                      // Version desktop : Row avec Préférences à gauche, Rôles+Groupes à droite
                      return IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Préférences à gauche
                            _PreferencesCard(
                              userName: userName,
                              email: _emailController.text,
                              isDarkMode: isDarkMode,
                              onThemeChanged: themeProvider.setDarkMode,
                              swipeEnabled: swipeEnabled,
                              onSwipeChanged: swipeProvider.setSwipeEnabled,
                            ),
                            SizedBox(width: 32),
                            // Colonne Rôles + Groupes à droite
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _RolesAndCompaniesCard(
                                  isClient: isClient, 
                                  isAdmin: isAdmin, 
                                  hasMDMFi: hasMDMFi,
                                  userGroups: userGroups,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 32),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Connexion sécurisée', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Exemple d'export des données du cache Navision et Odoo
                    final navisionCache = NavisionServiceCache();
                    final odooCache = OdooServiceCache();
                    // Remplace 'societe' par la valeur réelle à exporter
                    final societe = 'demo';
                    final navisionData = await navisionCache.loadIndicateursMensuel(societe);
                    final odooData = await odooCache.loadIndicateursMensuel(societe);
                    // Affiche les données dans un SnackBar (ou adapte selon besoin)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navision: ' + (navisionData?.toJson().toString() ?? 'Aucune donnée') + '\nOdoo: \n' + (odooData?.toJson().toString() ?? 'Aucune donnée'))),
                    );
                  },
                  icon: Icon(Icons.download),
                  label: Text('Exporter données cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _logoutKeycloak,
                  icon: Icon(Icons.logout),
                  label: Text('Se déconnecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF1A1A1A)
                : Color(0xFFF5F7FA),
            Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF2D2D2D)
                : Color(0xFFE8EDF2),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 450),
            margin: EdgeInsets.all(24),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Mobaitec en haut
                  Container(
                    width: 80,
                    height: 80,
                    margin: EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Color(0xFFE0E0E0) 
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/mobaitec-logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.security,
                            size: 40,
                            color: Color(0xFF00A9CA), // Couleur #00a9ca
                          );
                        },
                      ),
                    ),
                  ),
                  
                  Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Connectez-vous pour accéder à vos données SIG',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Champ Email amélioré
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2A2A2A)
                          : Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF404040)
                            : Color(0xFFE1E8ED),
                      ),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Color(0xFF00A9CA), // Couleur #00a9ca
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value == null || value.isEmpty ? 'Email requis' : null,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Champ Mot de passe amélioré
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color(0xFF2A2A2A)
                          : Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF404040)
                            : Color(0xFFE1E8ED),
                      ),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF00A9CA), // Couleur #00a9ca
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty ? 'Mot de passe requis' : null,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Message d'erreur stylé
                  if (_error != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Bouton de connexion amélioré
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _loading
                          ? null
                          : LinearGradient(
                              colors: [Color(0xFF00A9CA), Color(0xFF0095B3)], // Couleur #00a9ca et variante
                            ),
                      color: _loading ? Colors.grey[400] : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _loginKeycloak();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Connexion...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Se connecter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Footer avec info sécurité
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Connexion sécurisée avec Keycloak',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
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

// Ajout des widgets réutilisables pour la nouvelle structure
class _PreferencesCard extends StatelessWidget {
  final String userName;
  final String email;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final bool swipeEnabled;
  final ValueChanged<bool> onSwipeChanged;
  const _PreferencesCard({
    required this.userName,
    required this.email,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.swipeEnabled,
    required this.onSwipeChanged,
  });
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 340,
      height: 300, // Hauteur fixe pour égaliser les cards
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Préférences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Test : Stocker des données dans le cache Navision et Odoo
                    final navisionCache = NavisionServiceCache();
                    final odooCache = OdooServiceCache();
                    final societe = 'demo';
                    // Création d'un objet NavisionIndicateursMensuelResponse
                    final navisionTestData = NavisionIndicateursMensuelResponse(
                      annee: DateTime.now().year,
                      mois: {
                        '07': [
                          NavisionIndicateurMensuel(
                            indicateur: 'CA',
                            libelle: 'Chiffre d’Affaires',
                            valeur: 12345.0,
                            associe: [],
                            formuleText: 'CA = ...',
                            formuleNumeric: '12345',
                            initiales: 'CA',
                          ),
                          NavisionIndicateurMensuel(
                            indicateur: 'RES',
                            libelle: 'Résultat',
                            valeur: 6789.0,
                            associe: [],
                            formuleText: 'RES = ...',
                            formuleNumeric: '6789',
                            initiales: 'RES',
                          ),
                        ],
                      },
                    );
                    // Création d'un objet OdooIndicateursMensuelResponse
                    final odooTestData = OdooIndicateursMensuelResponse(
                      annee: DateTime.now().year,
                      mois: {
                        '07': [
                          OdooIndicateurMensuel(
                            indicateur: 'CA',
                            libelle: 'Chiffre d’Affaires',
                            valeur: 54321.0,
                            associe: [],
                            formuleText: 'CA = ...',
                            formuleNumeric: '54321',
                            initiales: 'CA',
                          ),
                          OdooIndicateurMensuel(
                            indicateur: 'RES',
                            libelle: 'Résultat',
                            valeur: 9876.0,
                            associe: [],
                            formuleText: 'RES = ...',
                            formuleNumeric: '9876',
                            initiales: 'RES',
                          ),
                        ],
                      },
                    );
                    await navisionCache.saveIndicateursMensuel(societe, navisionTestData);
                    await odooCache.saveIndicateursMensuel(societe, odooTestData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Données de test stockées dans le cache !')),
                    );
                  },
                  icon: Icon(Icons.save),
                  label: Text('Stocker données test dans cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
          Row(
            children: [
              Icon(Icons.person, color: isDarkMode ? Colors.white70 : Colors.blueGrey),
              SizedBox(width: 8),
              Text(userName, style: TextStyle(fontSize: 16)),
            ],
          ),
          SizedBox(height: 8),
          if (email.isNotEmpty)
            Row(
              children: [
                Icon(Icons.email, color: isDarkMode ? Colors.white70 : Colors.blueGrey),
                SizedBox(width: 8),
                Text(email, style: TextStyle(fontSize: 16)),
              ],
            ),
          SizedBox(height: 16),
          SwitchListTile(
            title: Text(isDarkMode ? 'Mode Nuit' : 'Mode Jour'),
            value: isDarkMode,
            onChanged: onThemeChanged,
            secondary: Icon(isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
          ),
          SwitchListTile(
            title: Text('Défilement par glissement'),
            value: swipeEnabled,
            onChanged: onSwipeChanged,
            secondary: Icon(Icons.swipe),
          ),
        ],
      ),
    );
  }
}

class _RolesAndCompaniesCard extends StatelessWidget {
  final bool isClient;
  final bool isAdmin;
  final bool hasMDMFi;
  final List<String>? userGroups;
  
  const _RolesAndCompaniesCard({
    required this.isClient, 
    required this.isAdmin, 
    required this.hasMDMFi,
    this.userGroups,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final keycloakProvider = Provider.of<KeycloakProvider>(context, listen: false);
    
    // Debug : afficher les groupes dans la console
    print('[RolesAndCompaniesCard] userGroups reçus: ${userGroups?.toString()}');
    print('[RolesAndCompaniesCard] accessibleCompanies: ${keycloakProvider.accessibleCompanies.toString()}');
    
    return Container(
      width: 340,
      // height: 300, // Hauteur fixe supprimée
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF2A2A2A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Rôles
            Text('Rôles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isClient)
                  Chip(
                    label: Text('Client', style: TextStyle(color: Colors.white)), 
                    backgroundColor: Color(0xFF00A9CA)
                  ),
                if (isAdmin)
                  Chip(
                    label: Text('Admin', style: TextStyle(color: Colors.white)), 
                    backgroundColor: Colors.red
                  ),
                if (hasMDMFi)
                  Chip(
                    label: Text('MDM-Fi', style: TextStyle(color: Colors.white)), 
                    backgroundColor: isDarkMode ? Color(0xFF2C5C4C) : Colors.teal
                  ),
              ],
            ),
            
            // Section Sociétés (si groupes disponibles)
            if (userGroups != null && userGroups!.isNotEmpty) ...[
              SizedBox(height: 20),
              Divider(color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
              SizedBox(height: 12),
              Text('Groupe(s) utilisateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: userGroups!.map((g) {
                  String displayName = g;
                  if (g.contains('/')) {
                    displayName = g.replaceAll('/', ' → ');
                    if (displayName.startsWith(' → ')) {
                      displayName = displayName.substring(3);
                    }
                  }
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: Chip(
                      label: Text(
                        displayName,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 12,
                        )
                      ),
                      backgroundColor: isDarkMode ? Color(0xFF404040) : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Section Sociétés accessibles (depuis le provider)
            if (keycloakProvider.accessibleCompanies.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('Société(s) accessibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: keycloakProvider.accessibleCompanies.map((company) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 2),
                    child: Chip(
                      label: Text(
                        company['name'] ?? '',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                      backgroundColor: isDarkMode ? Color(0xFF404040) : Colors.grey[300],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
