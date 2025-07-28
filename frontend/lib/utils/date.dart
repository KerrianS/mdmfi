String getMonthName(int month) {
  switch (month) {
    case 1:
      return 'Janvier';
    case 2:
      return 'Février';
    case 3:
      return 'Mars';
    case 4:
      return 'Avril';
    case 5:
      return 'Mai';
    case 6:
      return 'Juin';
    case 7:
      return 'Juillet';
    case 8:
      return 'Août';
    case 9:
      return 'Septembre';
    case 10:
      return 'Octobre';
    case 11:
      return 'Novembre';
    case 12:
      return 'Décembre';
    default:
      return '';
  }
}

enum Annee {
  n0,
  n1,
  n2,
  n3;

  int get value {
    switch (this) {
      case Annee.n0:
        return DateTime.now().year;
      case Annee.n1:
        return Annee.n0.value - 1;
      case Annee.n2:
        return Annee.n0.value - 2;
      case Annee.n3:
        return Annee.n0.value - 3;
    }
  }
}
