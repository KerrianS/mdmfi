# Documentation Interne - Application MDM-FI

## Table des matières
1. [Vue d'ensemble](#vue-densemble)
2. [Architecture Frontend](#architecture-frontend)
3. [Structure des données](#structure-des-données)
4. [Services et Providers](#services-et-providers)
5. [Composants UI](#composants-ui)
6. [Écrans et Navigation](#écrans-et-navigation)
7. [Backend - WS Relay](#backend---ws-relay)
8. [Configuration et Déploiement](#configuration-et-déploiement)

---

## Vue d'ensemble

L'application **MDM-FI** (Mobaitec Decision Making - Financial Intelligence) est une application Flutter desktop conçue pour l'analyse financière et la prise de décision. Elle permet de visualiser et analyser les indicateurs SIG (Solde Intérieur de Gestion) de différentes sociétés.

### Fonctionnalités principales
- **Authentification** via Keycloak
- **Visualisation des données** comptables et indicateurs
- **Mode local** avec données Hive et JSON préchargées
- **Interface adaptative** avec thème clair/sombre
- **Navigation par onglets** entre différentes vues
- **Graphiques interactifs** pour l'analyse

---

## Architecture Frontend

### Structure du projet
```
frontend/lib/
├── main.dart                 # Point d'entrée de l'application
├── components/               # Composants réutilisables
├── models/                   # Modèles de données
├── screens/                  # Écrans de l'application
├── services/                 # Services métier
├── utils/                    # Utilitaires
└── viewmodels/              # ViewModels pour la logique métier
```

### Point d'entrée (`main.dart`)

L'application utilise une architecture basée sur **Provider** pour la gestion d'état :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Hive pour le cache
  await Hive.openBox('navision_cache');
  await Hive.openBox('odoo_cache');
  
  // Initialisation du service de données locales
  await LocalDataService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KeycloakProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SwipeProvider()),
        ChangeNotifierProvider(create: (_) => DataModeProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Thèmes et Styles

L'application supporte deux thèmes :
- **Thème clair** : Couleurs MCA (bleu corporate)
- **Thème sombre** : Palette de gris adaptée

```dart
// Configuration du thème sombre
darkTheme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF2C2C2C),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
  ),
  // ... autres configurations
)
```

---

## Structure des données

### Modèles principaux (`models/SIGModel.dart`)

#### SIGCompteMensuel
```dart
class SIGCompteMensuel {
  final String codeCompte;
  final String libelleCompte;
  final double montant;
  final double debit;
  final double credit;
  final DateTime dateEcriture;
  final String document;
  final String utilisateur;
}
```

#### SIGIndicateurMensuel
```dart
class SIGIndicateurMensuel {
  final String indicateur;
  final String libelle;
  final String initiales;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;
}
```

#### SIGSousIndicateurMensuel
```dart
class SIGSousIndicateurMensuel {
  final String sousIndicateur;
  final String libelle;
  final String initiales;
  final double valeur;
  final String formuleText;
  final String formuleNumeric;
}
```

### Organisation des données locales

Les données sont organisées par société et par type :
```
lib/data/
├── rsp-bgs/
│   ├── comptes_global_annee.json
│   ├── comptes_mensuel_2022.json
│   ├── indicateurs_global_annee.json
│   └── ...
├── rsp-neg/
├── rsp-sb/
└── aitecservice/
```

---

## Services et Providers

### 1. LocalDataService (`services/data/local_data_service.dart`)

Service principal pour la gestion des données locales :

```dart
class LocalDataService {
  static final Map<String, Map<String, dynamic>> _cache = {};
  static List<String> _availableSocietes = [];
  
  // Initialisation du service
  static Future<void> initialize() async {
    _availableSocietes = await _discoverSocietes();
    for (String societe in _availableSocietes) {
      await _loadAllDataForSociete(societe);
    }
  }
  
  // Récupération des données
  static Map<String, dynamic>? getData(String societe, String dataType) {
    return _cache[societe]?[dataType];
  }
}
```

### 2. KeycloakService (`services/keycloak/keycloak_service.dart`)

Gestion de l'authentification et des autorisations :

```dart
class KeycloakService {
  static const String baseUrl = 'https://api.client.aitecservice.com/api/keycloak';
  
  // Connexion utilisateur
  Future<String> login({required String username, required String password}) async {
    // Logique de connexion
  }
  
  // Récupération des sociétés accessibles
  Future<List<Map<String, String>>> fetchAccessibleCompanies(String token, List<String> userGroups) async {
    // Logique de récupération des sociétés
  }
}
```

### 3. KeycloakProvider (`services/keycloak/keycloak_provider.dart`)

Provider pour la gestion de l'état d'authentification :

```dart
class KeycloakProvider extends ChangeNotifier {
  bool _isConnected = false;
  String? _accessToken;
  List<String> _userGroups = [];
  List<Map<String, String>> _accessibleCompanies = [];
  String? _selectedCompany;
  
  // Getters et setters
  // Méthodes de gestion de l'état
}
```

### 4. ThemeProvider (`services/theme/theme_provider.dart`)

Gestion du thème de l'application :

```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
```

---

## Composants UI

### 1. DashboardHeader (`components/header.dart`)

En-tête principal avec :
- Logo de l'application
- Informations de connexion
- Bouton de déconnexion
- Sélecteur de société

### 2. NavBar (`components/navbar.dart`)

Barre de navigation avec onglets :
- Paramètres
- Global
- Axe
- Mensuel
- Graphiques

### 3. TableContainer (`components/table.dart`)

Composant de tableau adaptatif avec :
- Pagination
- Tri
- Filtrage
- Export

### 4. Composants de données

#### GlobalIndicateurDataTable
Affichage des indicateurs globaux avec :
- Calculs automatiques
- Mise en forme conditionnelle
- Boutons d'action

#### MensuelIndicateurDataTable
Affichage des indicateurs mensuels avec :
- Sélecteur de période
- Graphiques intégrés
- Comparaisons

---

## Écrans et Navigation

### 1. Dashboard (`screens/dashboard/dashboard.dart`)

Écran principal avec :
- Navigation par onglets
- Gestion des pages
- Intégration des composants

```dart
class DashBoard extends StatefulWidget {
  final List<PageItem> _pages = [
    PageItem(Pages.parametres, SettingsScreen()),
    PageItem(Pages.global, Global()),
    PageItem(Pages.mensuel, Mensuel()),
    PageItem(Pages.graphMensuel, GraphMensuel()),
    PageItem(Pages.graphSig, GraphSig()),
    PageItem(Pages.graphSigDet, GraphSigDetail()),
  ];
}
```

### 2. Écrans spécialisés

#### Global (`screens/dashboard/global/global.dart`)
- Vue d'ensemble des indicateurs
- Tableaux de données
- Boutons d'action (KEuros, Aide)

#### Mensuel (`screens/dashboard/mensuel/mensuel.dart`)
- Données mensuelles
- Sélecteurs de période
- Graphiques temporels

#### Graphiques (`screens/dashboard/graph_*/`)
- Visualisations interactives
- Graphiques en secteurs
- Graphiques linéaires

### 3. Navigation

L'application utilise un système de navigation par onglets avec :
- `PageController` pour les transitions
- `PageView` pour le swipe
- Gestion d'état avec `Provider`

---

## Backend - WS Relay

### Architecture du backend

Le backend utilise **FastAPI** avec un système de **WebSocket Relay** pour les notifications temps réel.

### 1. Serveur principal (`backend/server.py`)

```python
app = FastAPI(
    title="MDM-FI API - Analyse SIG avec WebSocket Relay",
    description="API d'analyse des indicateurs SIG pour Odoo et Navision avec notifications temps réel.",
    version="1.1.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 2. WebSocket Relay (`backend/routes/file_routes.py`)

#### Gestion des connexions WebSocket
```python
# Stockage des connexions actives
active_connections: List[WebSocket] = []

async def notify_clients(message: dict):
    """Notifie tous les clients WebSocket connectés"""
    if active_connections:
        await asyncio.gather(
            *[connection.send_text(json.dumps(message)) for connection in active_connections]
        )
```

#### Endpoint WebSocket
```python
@file_router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    active_connections.append(websocket)
    
    try:
        # Message de bienvenue
        await websocket.send_text(json.dumps({
            "type": "connection",
            "message": "Connecté au WebSocket Relay",
            "timestamp": datetime.now().isoformat()
        }))
        
        # Boucle de maintien de connexion
        while True:
            data = await websocket.receive_text()
            logger.info(f"Message reçu du client: {data}")
            
    except WebSocketDisconnect:
        active_connections.remove(websocket)
```

### 3. Gestion des fichiers

#### Endpoints REST
- `GET /api/files/societes` - Liste des sociétés
- `GET /api/files/societe/{societe}/files` - Fichiers d'une société
- `POST /api/files/upload/{societe}` - Upload de fichiers
- `DELETE /api/files/delete/{societe}/{filename}` - Suppression
- `GET /api/files/status` - Statut de synchronisation

#### Synchronisation temps réel
```python
@file_router.post("/sync/{societe}")
async def sync_societe_files(societe: str):
    """Synchronise les fichiers d'une société"""
    try:
        # Logique de synchronisation
        await notify_clients({
            "type": "sync_complete",
            "societe": societe,
            "timestamp": datetime.now().isoformat()
        })
        return {"status": "success", "message": "Synchronisation terminée"}
    except Exception as e:
        logger.error(f"Erreur de synchronisation: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

### 4. Modèles de données backend

```python
class FileInfo(BaseModel):
    filename: str
    societe: str
    type_data: str
    annee: str
    size: int
    last_modified: str
    checksum: str

class SyncStatus(BaseModel):
    societe: str
    status: str
    message: str
    timestamp: str
```

---

## Configuration et Déploiement

### Dépendances Frontend (`pubspec.yaml`)

```yaml
dependencies:
  desktop_window: ^0.4.0
  fl_chart: ^0.68.0
  hive_flutter: ^1.1.0
  intl: ^0.19.0
  provider: ^6.0.5
  shimmer: ^3.0.0
  # ... autres dépendances
```

### Dépendances Backend (`requirements.txt`)

```
fastapi
uvicorn
websockets
python-multipart
```

### Variables d'environnement

#### Frontend
- `KEYCLOAK_BASE_URL` : URL du serveur Keycloak
- `API_BASE_URL` : URL de l'API backend

#### Backend
- `BASE_FILES_DIR` : Répertoire des fichiers JSON
- `CORS_ORIGINS` : Origines autorisées pour CORS

### Scripts de déploiement

#### Frontend
```bash
# Compilation pour desktop
flutter build windows
flutter build macos
flutter build linux
```

#### Backend
```bash
# Démarrage du serveur
uvicorn server:app --host 0.0.0.0 --port 8000 --reload
```

---

## Points d'attention

### 1. Gestion des données
- Les données sont chargées localement au démarrage
- Cache Hive pour les performances
- Synchronisation optionnelle avec le backend

### 2. Authentification
- Intégration Keycloak complète
- Gestion des tokens et refresh
- Autorisations basées sur les groupes utilisateur

### 3. Performance
- Chargement asynchrone des données
- Composants optimisés avec `const`
- Gestion mémoire avec `dispose()`

### 4. Sécurité
- Validation des données côté client et serveur
- Gestion sécurisée des tokens
- CORS configuré pour la production

---

## Maintenance et Évolution

### Ajout de nouvelles fonctionnalités
1. Créer les modèles de données dans `models/`
2. Implémenter les services dans `services/`
3. Créer les composants UI dans `components/`
4. Ajouter les écrans dans `screens/`
5. Mettre à jour la navigation

### Debugging
- Logs détaillés dans la console
- Gestion d'erreurs avec try/catch
- Validation des données d'entrée

### Tests
- Tests unitaires pour les services
- Tests d'intégration pour les composants
- Tests de performance pour les gros volumes

---

## Tâches restantes

### 🚧 **Points à finaliser**

#### 1. **WS Relay**
- [ ] Finaliser l'implémentation WebSocket Relay côté frontend
- [ ] Tester les connexions temps réel
- [ ] Implémenter la gestion des déconnexions/reconnexions
- [ ] Optimiser les performances des notifications

#### 2. **Scripts en production**
- [ ] Vérifier et tester les scripts de déploiement en production
- [ ] Valider les variables d'environnement
- [ ] Tester les builds pour Windows/MacOS/Linux
- [ ] Documenter les procédures de déploiement

#### 3. **DataTableAccount - Données des comptes**
- [ ] Corriger l'affichage des données dans les tableaux DataTableAccount
- [ ] Vérifier la cohérence des données comptables
- [ ] Optimiser les performances d'affichage
- [ ] Tester avec différents volumes de données

### 📋 **Priorités**
1. **Haute priorité** : Régler les données des comptes (DataTableAccount)
2. **Moyenne priorité** : Finaliser WS Relay
3. **Basse priorité** : Vérifier les scripts en production

---

*Documentation générée le : $(date)*
*Version de l'application : 1.1.0* 