import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/services/account_service.dart';
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
GoRouter routerProvider() {
  final notifier = locator<AuthNotifier>();

  final storageService = locator<IStorageService>();
  final accountService = locator<IAccountService>();

  return GoRouter(

    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) async {

      if(!await storageService.isMasterPasswordExists()) {
        // go to registration page if master password is not set
        return '/registration';
      }

      final isAccountExists = await accountService.isAccountExists();

      if(!isAccountExists && state.matchedLocation != '/registration') {
        return '/registration';
      }

      // before switch route check if the application is authenticated
      final authState = await accountService.checkSessionFromStoredToken();

      final loggedIn = authState.status == AuthStatus.authenticated;

      final routeToRedirect = routesAuthList.entries.firstWhere((entry) =>
          state.matchedLocation.contains(entry.key),
          orElse: () => MapEntry("-1", false));

      final needAuth = routeToRedirect.value;


      if (needAuth && !loggedIn) {
        return '/login';
      }


      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final isLoading = locator<LoadingNotifier>().isLoading;
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
}