import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

enum McaColors {
  rouge(Color(0xFFFF0000)),
  rouge90(Color(0xFFE60000)),
  rouge80(Color(0xFFCC0000)),
  rouge70(Color(0xFFB30000)),
  rouge60(Color(0xFF990000)),

  marron(Color(0xFF8B4513)),
  marron90(Color(0xFF7A3E12)),
  marron80(Color(0xFF693611)),
  marron70(Color(0xFF582F0F)),
  marron60(Color(0xFF47270D)),

  jaune(Color(0xFFFFFF00)),
  jaune90(Color(0xFFE6E600)),
  jaune80(Color(0xFFCCCC00)),
  jaune70(Color(0xFFB3B300)),
  jaune60(Color(0xFF999900)),

  bleu(Color(0xFF0099B3)),
  bleu90(Color(0xFF008AA1)),
  bleu80(Color(0xFF007C8F)),
  bleu70(Color(0xFF006D7D)),
  bleu60(Color(0xFF005E6B)),

  vert(Color(0xFF678264)),
  vert90(Color(0xFF5E755A)),
  vert80(Color(0xFF546950)),
  vert70(Color(0xFF4B5C46)),
  vert60(Color(0xFF41503C)),

  orange(Color(0xFFF19109)),
  orange90(Color(0xFFD98208)),
  orange80(Color(0xFFC17307)),
  orange70(Color(0xFFA96406)),
  orange60(Color(0xFF915504)),

  violet(Color(0xFF800080)),
  violet90(Color(0xFF720072)),
  violet80(Color(0xFF640064)),
  violet70(Color(0xFF560056)),
  violet60(Color(0xFF480048)),

  rose(Color(0xFFFFC0CB)),
  rose90(Color(0xFFE6ACB6)),
  rose80(Color(0xFFCC99A2)),
  rose70(Color(0xFFB3868D)),
  rose60(Color(0xFF997379)),

  turquoise(Color(0xFF40E0D0)),
  turquoise90(Color(0xFF39C6B8)),

  turquoise80(Color(0xFF33ADA0)),
  turquoise70(Color(0xFF2D9488)),
  turquoise60(Color(0xFF267A70)),

  gris(Color(0xFF808080)),
  gris90(Color(0xFF727272)),
  gris80(Color(0xFF646464)),
  gris70(Color(0xFF565656)),
  gris60(Color(0xFF484848)),

  noir(Color(0xFF000000)),
  noir90(Color(0xFF000000)),
  noir80(Color(0xFF000000)),
  noir70(Color(0xFF000000)),
  noir60(Color(0xFF000000));

  final Color color;

  const McaColors(this.color);
}

enum AppColors {
  mcaBleu(Color(0xFF0099B3)),

  mcaBleu50(Color(0xFFE0F7FA)),
  mcaBleu100(Color(0xFFB2EBF2)),
  mcaBleu200(Color(0xFF80DEEA)),
  mcaBleu300(Color(0xFF4DD0E1)),
  mcaBleu400(Color(0xFF26C6DA)),
  mcaBleu500(Color(0xFF0099B3)),
  mcaBleu600(Color(0xFF008BA3)),
  mcaBleu700(Color(0xFF007B93)),
  mcaBleu800(Color(0xFF006B83)),
  mcaBleu900(Color(0xFF004D63)),

  rougeOrange(Color(0xFFFF5733)),
  vertVif(Color(0xFF33FF57)),

  vertPositive(Color(0xFF00FF00)),
  rougeNegative(Color(0xFFFF0000)),

  blueGreyLight(Color(0xFFA0A5A9)),
  blueGreyDark(Color(0xFF3D444B)),

  white(Color(0xFFFFFFFF)),
  black(Color.fromARGB(255, 0, 0, 0));

  final Color color;

  const AppColors(this.color);
}

// Définir un enum pour les couleurs
enum PieChartColors {
  rougeOrange(Color(0xFFFF5733)),
  vertVif(Color(0xFF33FF57)),
  bleuVif(Color(0xFF3357FF)),
  roseVif(Color(0xFFFF33A1)),
  jauneDore(Color(0xFFFFC300)),
  vertPastel(Color(0xFFDAF7A6)),
  bordeaux(Color(0xFF900C3F)),
  pourpreFonce(Color(0xFF581845)),
  rougeFramboise(Color(0xFFC70039)),
  orangeVif(Color(0xFFFF5733)),
  violetFonce(Color(0xFF6A0572)),
  vertMenthe(Color(0xFF00FFAB)),
  sable(Color(0xFFF4A460)),
  brunFonce(Color(0xFF8B4513)),
  bleuAcier(Color(0xFF4682B4)),
  or(Color(0xFFFFD700)),
  vertMer(Color(0xFF20B2AA)),
  tomate(Color(0xFFFF6347)),
  violetMoyen(Color(0xFF9370DB)),
  vertPrintempsMoyen(Color(0xFF00FA9A));

  final Color color;
  const PieChartColors(this.color);
}

// Tableau de couleurs
final List<PieChartColors> pieChartColors = [
  PieChartColors.rougeOrange,
  PieChartColors.vertVif,
  PieChartColors.bleuVif,
  PieChartColors.roseVif,
  PieChartColors.jauneDore,
  PieChartColors.vertPastel,
  PieChartColors.bordeaux,
  PieChartColors.pourpreFonce,
  PieChartColors.rougeFramboise,
  PieChartColors.orangeVif,
  PieChartColors.violetFonce,
  PieChartColors.vertMenthe,
  PieChartColors.sable,
  PieChartColors.brunFonce,
  PieChartColors.bleuAcier,
  PieChartColors.or,
  PieChartColors.vertMer,
  PieChartColors.tomate,
  PieChartColors.violetMoyen,
  PieChartColors.vertPrintempsMoyen,
];

Color colorBasedOnName(String name) {
  final hash = name.hashCode;
  // choisir une couleur dans le tableau de couleurs
  final color = pieChartColors[(hash + 3) % pieChartColors.length].color;
  return color;
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}
