import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences)
    : _mode = _readMode(_preferences.getString(_key));

  static const _key = 'theme_mode';
  final SharedPreferences _preferences;
  ThemeMode _mode;
  bool _saving = false;

  ThemeMode get mode => _mode;
  bool get saving => _saving;

  static ThemeMode _readMode(String? value) => switch (value) {
    null || 'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => throw FormatException('Unknown theme mode: $value'),
  };

  Future<void> setMode(ThemeMode mode) async {
    if (_saving || mode == _mode) return;
    _saving = true;
    notifyListeners();
    try {
      if (!await _preferences.setString(_key, mode.name)) {
        throw StateError('Failed to save theme preference.');
      }
      _mode = mode;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ThemeControllerScope>()
      ?.notifier;
}
