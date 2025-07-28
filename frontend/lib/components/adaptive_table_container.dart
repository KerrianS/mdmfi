import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';

/// Widget conteneur adaptatif pour les tableaux qui s'ajuste automatiquement
/// à la largeur en fonction du nombre de colonnes
class AdaptiveTableContainer extends StatelessWidget {
  final Widget child;
  final int? columnCount;
  final double firstColumnWidth;
  final double dataColumnWidth;
  final double? minContainerWidth;
  final bool enableHorizontalScroll;

  const AdaptiveTableContainer({
    super.key,
    required this.child,
    this.columnCount,
    this.firstColumnWidth = 180,
    this.dataColumnWidth = 87,
    this.minContainerWidth,
    this.enableHorizontalScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.blueGreyLight.color.withOpacity(0.3)
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // S'assurer qu'on a une largeur minimum
          final minWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;
          final maxHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 500.0;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth,
                minHeight: 100.0, // Assurer une hauteur minimum
                maxHeight: maxHeight, // Assurer une hauteur maximum
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
