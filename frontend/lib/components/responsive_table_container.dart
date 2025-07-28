import 'package:flutter/material.dart';

class ResponsiveTableContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  const ResponsiveTableContainer({
    Key? key,
    required this.child,
    this.padding,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: decoration,
          padding: padding,
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
