import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerUtils {
  static Widget createShimmer({
    required BuildContext context,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (isDarkMode) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFF404040), 
        highlightColor: const Color(0xFF606060), 
        child: child,
      );
    } else {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: child,
      );
    }
  }

  static Widget createLoadingContainer({
    required BuildContext context,
    double? height,
    double? width,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return createShimmer(
      context: context,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
        height: height ?? 32,
        width: width, // Enlever ?? double.infinity qui cause l'erreur
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF505050) : Colors.grey.shade300,
          borderRadius: borderRadius ?? BorderRadius.circular(6),
        ),
      ),
    );
  }

  static Widget createLoadingList({
    required BuildContext context,
    int itemCount = 5,
    double? itemHeight,
    double? itemWidth,
    EdgeInsetsGeometry? itemMargin,
    BorderRadius? itemBorderRadius,
  }) {
    return createShimmer(
      context: context,
      child: Column(
        children: List.generate(itemCount, (i) => Container(
          margin: itemMargin ?? const EdgeInsets.symmetric(vertical: 6),
          height: itemHeight ?? 32,
          width: itemWidth, // Utiliser itemWidth directement si fourni
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF505050) 
              : Colors.grey.shade300,
            borderRadius: itemBorderRadius ?? BorderRadius.circular(6),
          ),
        )),
      ),
    );
  }
}
