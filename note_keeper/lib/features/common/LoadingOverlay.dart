import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          // Transparent Background
          const ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          // Loading Indicator
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }
}
