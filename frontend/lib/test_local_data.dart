import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/services/data/local_data_service.dart';

class TestLocalData extends StatelessWidget {
  const TestLocalData({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Données Locales'),
      ),
      body: FutureBuilder<void>(
        future: _testLocalData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('Test terminé avec succès !'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _testLocalData() async {
    print('🧪 Début du test des données locales...');

    try {
      // Initialiser le service
      await LocalDataService.initialize();

      // Obtenir les statistiques
      final stats = LocalDataService.getDataStats();
      print('📊 Statistiques: $stats');

      // Tester avec une société
      final societes = LocalDataService.getAvailableSocietes();
      if (societes.isNotEmpty) {
        final testSociete = societes.first;
        print('🧪 Test avec la société: $testSociete');

        // Tester les données comptes
        final comptesData =
            LocalDataService.getComptesMensuel(testSociete, 2022);
        print(
            '📊 Données comptes 2022: ${comptesData != null ? 'OK' : 'NON TROUVÉ'}');

        // Tester les données indicateurs
        final indicateursData =
            LocalDataService.getIndicateursMensuel(testSociete, 2022);
        print(
            '📊 Données indicateurs 2022: ${indicateursData != null ? 'OK' : 'NON TROUVÉ'}');

        // Tester la conversion
        if (comptesData != null) {
          final converted = LocalDataService.convertToComptesMensuelPage(
            comptesData,
            testSociete,
            2022,
            1,
            'VENTES DE MARCHANDISES',
          );
          print('🔄 Conversion comptes: ${converted != null ? 'OK' : 'ÉCHEC'}');
        }

        if (indicateursData != null) {
          final converted =
              LocalDataService.convertToIndicateursMensuelResponse(
            indicateursData,
            testSociete,
            2022,
          );
          print(
              '🔄 Conversion indicateurs: ${converted != null ? 'OK' : 'ÉCHEC'}');
        }
      }

      print('✅ Test terminé avec succès !');
    } catch (e) {
      print('❌ Erreur lors du test: $e');
      rethrow;
    }
  }
}
