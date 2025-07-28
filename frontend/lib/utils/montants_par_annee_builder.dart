/// Génère la map montantsParAnnee à partir du payload brut (voir exemple dans la doc)
/// Chaque clé est 'code_compte|libelle_compte', chaque valeur est une map année -> {montant, debit, credit}
Map<String, Map<String, Map<String, num>>> buildMontantsParAnnee(Map<String, dynamic> payload) {
  final Map<String, Map<String, Map<String, num>>> montantsParAnnee = {};
  final comptesParAnnee = payload['comptes'] as Map<String, dynamic>?;
  if (comptesParAnnee == null) return montantsParAnnee;

  comptesParAnnee.forEach((annee, data) {
    final comptes = data['comptes'] as List<dynamic>?;
    if (comptes == null) return;
    for (final compte in comptes) {
      final code = compte['code_compte']?.toString() ?? '';
      final libelle = compte['libelle_compte']?.toString() ?? '';
      final key = '$code|$libelle';
      montantsParAnnee.putIfAbsent(key, () => {});
      montantsParAnnee[key]![annee] = {
        'montant': compte['montant'] ?? 0,
        'debit': compte['debit'] ?? 0,
        'credit': compte['credit'] ?? 0,
      };
    }
  });
  return montantsParAnnee;
}

// Exemple d'utilisation :
// final montantsParAnnee = buildMontantsParAnnee(payload);
// print(montantsParAnnee['23880000|Facture SAS LSBP']['2020']); // {montant: -3268, debit: 3268, credit: 0}
