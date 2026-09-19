import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/features/home/home_view.dart';
import 'package:note_keeper/features/login/login_page.dart';


final Map<String, bool> routesAuthList = {
  "/login": false, // no need protection by session
  "/login-error": false,
  '/home': true,
};

/// define route for entire application
final routerProvider = Provider<GoRouter>((ref) {

  final notifier = ValueNotifier<int>(0);

  ref.listen(authProvider, (_, _) {
      notifier.value++;
  });

  return GoRouter(

    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) async {

        // before switch route check if the application is authenticated
        final authState = await ref.watch(authProvider.future);
        final loggedIn =  authState.status == AuthStatus.authenticated;

        final routeToRedirect = routesAuthList.entries.firstWhere((entry)=>state.matchedLocation.contains(entry.key),
            orElse: () => MapEntry("-1", false));

        final needAuth = routeToRedirect.value != '-1';


        if (needAuth && !loggedIn) {
          return '/login';
        }

        if(state.fullPath == '') {
          // not find match redirect to Home
          return '/home';
        }


        return state.fullPath;
    },
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/error-page',
        builder: (_, _) => const LoginPage(),
      ),
    ],
  );
});