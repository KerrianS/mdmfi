import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final String title;

  const TableHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey.shade200,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
