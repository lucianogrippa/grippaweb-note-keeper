import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier state for loading widget
class LoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// show loading
  void show() => state = true;

  // hide loading
  void hide() => state = false;
}

final loadingProvider = NotifierProvider<LoadingNotifier, bool>(() {
  return LoadingNotifier();
});
