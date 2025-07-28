import 'dart:math';

int randInt(int min, int max) {
  return min + Random().nextInt(max - min);
}

double randDoubleCurrency(int min, int max) {
  return min + Random().nextInt(max - min) + Random().nextInt(100) / 100;
}

// ramene un nombre entre 0 et 1 en fonction de si il est plus ou moins proche de max
int Function(int) betweenRange(int maxValue, int minRange, int maxRange) {
  return (int n) => (n / maxValue).clamp(minRange, maxRange).toInt();
}

// fonction qui prend un nombre n et l'arrondi au multiple de x superieure à n le plus proche

int roundToMultipleSup(int n, int x) {
  return (n / x).ceil() * x;
}

// fonction qui prend un nombre n et l'arrondi au multiple de x inferieur à n le plus proche
int roundToMultipleInf(int n, int x) {
  return (n / x).floor() * x;
}
