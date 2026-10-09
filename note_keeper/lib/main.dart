import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:note_keeper/app/providers/router_provider.dart';
import 'package:note_keeper/app/services/database_service.dart';
import 'package:note_keeper/app/services/security_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Main Application class using router provider
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final router = ref.watch(routerProvider);

    /// Using Material app routing for settings go_router
    return MaterialApp.router(
      routerConfig: router,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      )
    );
  }
}

void main() async {
  await _initDb();
  runApp(
      ProviderScope(
          child: const MainApp()
      )
  );
}

Future<void> _initDb() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.create().init();
}
