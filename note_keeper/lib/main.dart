import 'package:flutter/material.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/providers/router_provider.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/features/common/LoadingOverlay.dart';

/// Main Application class using router provider
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final router = routerProvider();

    return LoadingOverlay(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
      ),
    );

    /// Using Material app routing for settings go_router
    // return MaterialApp.router(
    //   debugShowCheckedModeBanner: false,
    //   routerConfig: router,
    //   title: 'Flutter Demo',
    //   theme: ThemeData(
    //     colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    //   ),
    // );
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
}
