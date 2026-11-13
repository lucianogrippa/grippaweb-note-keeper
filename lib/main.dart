import 'package:flutter/material.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/providers/router_provider.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/features/common/loading_overlay.dart';
import 'package:note_keeper/app/theme/app_theme.dart';
import 'package:note_keeper/app/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Main Application class using router provider
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final _router = routerProvider();
  late final _themeController = locator<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          title: 'Note Keeper',
          theme: AppTheme.create(Brightness.light),
          darkTheme: AppTheme.create(Brightness.dark),
          themeMode: _themeController.mode,
          builder: (context, child) => LoadingOverlay(child: child!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}

void main() async {
  await _init();
  runApp(const MainApp());
}

Future<void> _init() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.init();

  configureLocators();

  await locator.allReady();
  locator.registerSingleton(
    ThemeController(await SharedPreferences.getInstance()),
  );
}
