import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/screens/dashboard/dashboard.dart';
import 'package:mobaitec_decision_making/utils/app_routes.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:provider/provider.dart';
import 'services/keycloak/keycloak_provider.dart';
import 'package:mobaitec_decision_making/services/theme/theme_provider.dart';
import 'package:mobaitec_decision_making/services/theme/swipe_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Hive.initFlutter();
  // var box = await Hive.openBox('navision_cache');
  // print('Hive path: [32m${box.path}[0m');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KeycloakProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SwipeProvider())
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> setMinSize() async {
    await DesktopWindow.setMinWindowSize(const Size(1000, 750));
  }

  @override
  Widget build(BuildContext context) {
    setMinSize();
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Aitec MDM Fi',
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primarySwatch: MaterialColor(
          0xFF0099B3,
          <int, Color>{
            50: AppColors.mcaBleu50.color,
            100: AppColors.mcaBleu100.color,
            200: AppColors.mcaBleu200.color,
            300: AppColors.mcaBleu300.color,
            400: AppColors.mcaBleu400.color,
            500: AppColors.mcaBleu500.color,
            600: AppColors.mcaBleu600.color,
            700: AppColors.mcaBleu700.color,
            800: AppColors.mcaBleu800.color,
            900: AppColors.mcaBleu900.color,
          },
        ),
        segmentedButtonTheme: themeProvider.isDarkMode 
            ? _getSegementedButtonThemeDark() 
            : _getSegementedButtonTheme(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Color(0xFF2C2C2C), // Gris pas trop foncé pour le fond des écrans
        canvasColor: Color(0xFF2C2C2C), // Fond canvas gris
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), // Gris très foncé pour navbar
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        dataTableTheme: DataTableThemeData(
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E), // Gris très foncé comme navbar pour les tableaux
          ),
          headingRowColor: MaterialStateProperty.all(Color(0xFF1E1E1E)),
          dataRowColor: MaterialStateProperty.all(Color(0xFF1E1E1E)),
          dataTextStyle: TextStyle(color: Color(0xFFE0E0E0)), // Blanc cassé pour les valeurs
          headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Blanc pur pour les en-têtes
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Color(0xFF1E1E1E), // Gris foncé pour les ListTile
        ),
        expansionTileTheme: ExpansionTileThemeData(
          backgroundColor: Color(0xFF1E1E1E), // Fond des ExpansionTile
          collapsedBackgroundColor: Color(0xFF1E1E1E), // Fond quand fermé
          textColor: Color(0xFFE0E0E0), // Couleur du texte
          collapsedTextColor: Color(0xFFE0E0E0), // Couleur du texte quand fermé
          iconColor: Color(0xFFE0E0E0), // Couleur de l'icône
          collapsedIconColor: Color(0xFFE0E0E0), // Couleur de l'icône quand fermé
        ),
        dividerColor: Color(0xFF404040), // Couleur des dividers
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF404040), // Gris moyen pour les boutons
            foregroundColor: Colors.white,
          ),
        ),
        segmentedButtonTheme: _getSegementedButtonThemeDark(),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)), // Blanc cassé pour le texte principal
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)), // Blanc cassé
          bodySmall: TextStyle(color: Color(0xFFCCCCCC)), // Blanc plus terne pour les détails
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Blanc pur pour les titres
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Color(0xFFE0E0E0)), // Pour les labels de tableaux
          labelMedium: TextStyle(color: Color(0xFFCCCCCC)),
          labelSmall: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF404040),
          secondary: Color(0xFF505050),
          surface: Color(0xFF1E1E1E), // Gris très foncé pour les surfaces (cartes, tableaux)
          background: Color(0xFF2C2C2C), // Gris pas trop foncé pour le fond
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0), // Blanc cassé pour le texte sur les surfaces
          onBackground: Color(0xFFE0E0E0), // Blanc cassé pour le texte sur le fond
          outline: Color(0xFF404040), // Pour les bordures
          surfaceVariant: Color(0xFF2C2C2C), // Variante de surface
          onSurfaceVariant: Color(0xFFCCCCCC), // Texte sur variante de surface
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.dashboard, // Set initial route
      routes: {
        AppRoutes.dashboard: (context) => const DashBoard(),
        // AppRoutes.settings: (context) => Settings(),
        // HomeScreen route
      },
    );
  }

  SegmentedButtonThemeData _getSegementedButtonTheme() {
    return SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
          selectedBackgroundColor: McaColors.bleu.color,
          backgroundColor: AppColors.white.color,
          foregroundColor: AppColors.black.color,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: McaColors.gris.color, width: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          )),
    );
  }

  SegmentedButtonThemeData _getSegementedButtonThemeDark() {
    return SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Color(0xFF404040),
          backgroundColor: Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: Color(0xFF404040), width: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          )),
    );
  }
}
