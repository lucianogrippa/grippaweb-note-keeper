import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    this.scaledTextLines = 4,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemHeight;
  final int scaledTextLines;

  @override
  Widget build(BuildContext context) {
    final extraHeight =
        (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(
          0.0,
          double.infinity,
        ) *
        scaledTextLines;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600
                ? 1
                : constraints.maxWidth < 900
                ? 2
                : 3;
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: itemHeight + extraHeight,
              ),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            );
          },
        ),
      ),
    );
  }
}
