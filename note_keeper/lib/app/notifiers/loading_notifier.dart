import 'package:flutter/cupertino.dart';

/// Notifier state for loading widget
class LoadingNotifier extends ChangeNotifier {
  bool _isLoading = false;
  LoadingNotifier();

  /// show loading
  void show() {
    _isLoading = true;
    notifyListeners();
  }

  // hide loading
  void hide() {
    _isLoading = false;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
}
