import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

/// Notifier state for loading widget
class LoadingNotifier extends ChangeNotifier {
  bool _isLoading = false;
  LoadingNotifier();

  /// show loading
  void show() => _setLoading(true);

  // hide loading
  void hide() => _setLoading(false);

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;

    // may be called from the router redirect while the framework is building
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool get isLoading => _isLoading;
}
