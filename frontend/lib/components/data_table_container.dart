import 'package:flutter/material.dart';
import 'package:mobaitec_decision_making/components/table_header.dart';
import 'package:mobaitec_decision_making/utils/colors.dart';

class DataTableContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final bool horizontalScrollEnabled;

  const DataTableContainer({
    super.key,
    required this.title,
    required this.child,
    this.horizontalScrollEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TableHeader(title: title),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.blueGreyLight.color.withOpacity(0.3)
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: horizontalScrollEnabled 
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(child: child),
                    )
                  : SingleChildScrollView(child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
