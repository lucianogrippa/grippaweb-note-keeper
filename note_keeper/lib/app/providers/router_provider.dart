import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/storage_service.dart';
import 'package:note_keeper/features/common/LoadingOverlay.dart';
import 'package:note_keeper/features/home/home_page.dart';
import 'package:note_keeper/features/login/login_page.dart';
import 'package:note_keeper/features/registration/registration_page.dart';


final Map<String, bool> routesAuthList = {
  "/login": false, // no need protection by session
  "/login-error": false,
  '/home': true,
};

/// define route for entire application
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, _) {
    notifier.value++;
  });

  ref.onDispose(() {
    notifier.dispose();
  });


  return GoRouter(

    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) async {

      final IStorageService storageService = await ref.read(storageServiceProvider.future);

      if(!await storageService.isMasterPasswordExists()) {
        // go to registration page if master password is not set
        return '/registration';
      }

      // before switch route check if the application is authenticated
      final authState = await ref.read(authStateProvider.future);
      final authService = await ref.read(accountServiceProvider.future);


      final loggedIn = authState.status == AuthStatus.authenticated;

      final isAccountExists = await authService.isAccountExists();

      if(!isAccountExists && state.matchedLocation != '/registration') {
        return '/registration';
      }

      final routeToRedirect = routesAuthList.entries.firstWhere((entry) =>
          state.matchedLocation.contains(entry.key),
          orElse: () => MapEntry("-1", false));

      final needAuth = routeToRedirect.value != '-1';


      if (needAuth && !loggedIn) {
        return '/login';
      }


      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final isLoading = ref.watch(loadingProvider);
          return LoadingOverlay(
            isLoading: isLoading,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) =>  HomePage(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) =>  LoginPage(),
          ),
          GoRoute(
              path: '/registration',
              builder: (_, _) => RegistrationPage())
        ]),
    ],
  );
});