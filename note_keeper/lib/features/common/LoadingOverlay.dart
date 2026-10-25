import 'package:flutter/material.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;

  const LoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loadingNotifier = locator<LoadingNotifier>();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          ListenableBuilder(
            listenable: loadingNotifier,
            builder: (context, _) {
              if (!loadingNotifier.isLoading) return const SizedBox.shrink();
              return const Stack(
                children: [
                  ModalBarrier(dismissible: false, color: Colors.white38),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
