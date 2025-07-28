class OdooSIGCompte {
  final int id;
  final List<dynamic> accountId;
  final double debit;
  final double credit;
  final String date;
  final String codeCompte;
  final String libelleCompte;
  final String classe;
  final String sousClasse;
  final String sssClasse;
  final String indicateur;
  final List<String> sousIndicateur;
  final double montant;
  final int annee;
  final int? trimestre;

  OdooSIGCompte({
    required this.id,
    required this.accountId,
    required this.debit,
    required this.credit,
    required this.date,
    required this.codeCompte,
    required this.libelleCompte,
    required this.classe,
    required this.sousClasse,
    required this.sssClasse,
    required this.indicateur,
    required this.sousIndicateur,
    required this.montant,
    required this.annee,
    this.trimestre,
  });

  factory OdooSIGCompte.fromJson(Map<String, dynamic> json) {
    return OdooSIGCompte(
      id: json['id'],
      accountId: json['account_id'],
      debit: (json['debit'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      date: json['date'],
      codeCompte: json['code_compte'],
      libelleCompte: json['libelle_compte'],
      classe: json['classe'],
      sousClasse: json['sous_classe'],
      sssClasse: json['sss_classe'],
      indicateur: json['indicateur'],
      sousIndicateur: List<String>.from(json['sous_indicateur']),
      montant: (json['montant'] ?? 0).toDouble(),
      annee: json['annee'],
      trimestre: json['trimestre'],
    );
  }
}
