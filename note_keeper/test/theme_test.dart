import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/services/storage_service.dart';
import 'package:note_keeper/app/theme/app_theme.dart';
import 'package:note_keeper/app/theme/theme_controller.dart';
import 'package:note_keeper/features/home/home_scaffold.dart';
import 'package:note_keeper/features/widgets/theme_mode_selector.dart';
import 'package:note_keeper/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'groups_page_test.dart' show FakeAccountService;
import 'note_search_test.dart' show SearchCategories, SearchGroups;
import 'notes_repository_test.dart'
    show NoteTestDatabase, NoteTestStorage, NotesBox;

class ThemeStorage implements IStorageService {
  @override
  Future<String> loadStoredAuthToken() async => 'session';
  @override
  Future<bool> isMasterPasswordExists() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ThemeAccount extends FakeAccountService {
  @override
  Future<bool> isAccountExists() async => true;
}

class FailingPreferences implements SharedPreferences {
  @override
  String? getString(String key) => null;
  @override
  Future<bool> setString(String key, String value) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme preference defaults to system and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = ThemeController(preferences);
    expect(controller.mode, ThemeMode.system);
    await controller.setMode(ThemeMode.dark);
    expect(ThemeController(preferences).mode, ThemeMode.dark);
    await controller.setMode(ThemeMode.light);
    expect(ThemeController(preferences).mode, ThemeMode.light);
    await controller.setMode(ThemeMode.system);
    expect(ThemeController(preferences).mode, ThemeMode.system);
    controller.dispose();
  });

  testWidgets('theme changes retain navigation and follow system brightness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(await SharedPreferences.getInstance());
    final categories = SearchCategories();
    for (final category in categories.categories) {
      category
        ..description = 'Description'
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);
    }
    final groups = SearchGroups();
    locator.registerSingleton<IStorageService>(ThemeStorage());
    locator.registerSingleton<IAccountService>(ThemeAccount());
    locator.registerSingleton(LoadingNotifier());
    locator.registerSingleton(AuthNotifier());
    locator.registerSingleton(NoteCategoryNotifier(categories));
    locator.registerSingleton(NoteGroupsNotifier(categories, groups));
    locator.registerSingleton<INoteRepository>(
      NoteRepository(
        databaseService: NoteTestDatabase(),
        storageService: NoteTestStorage(),
      )..db = NotesBox(),
    );
    locator.registerSingleton(controller);
    addTearDown(() async {
      await locator.reset();
      controller.dispose();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(find.text('Work'), findsOneWidget);
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(find.text('Work (0)'), findsOneWidget);

    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ThemeMode> &&
            widget.value == ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    var context = tester.element(find.byType(HomeScaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.text('Work (0)'), findsOneWidget);
    expect(
      ThemeController(await SharedPreferences.getInstance()).mode,
      ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ThemeMode> &&
            widget.value == ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();
    context = tester.element(find.byType(HomeScaffold));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(find.text('Work (0)'), findsOneWidget);

    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ThemeMode> &&
            widget.value == ThemeMode.system,
      ),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    context = tester.element(find.byType(HomeScaffold));
    expect(Theme.of(context).brightness, Brightness.dark);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;
    router.go('/login');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Theme'), findsOneWidget);
    router.go('/registration');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a failed preference write shows an error and keeps the mode', (
    tester,
  ) async {
    final controller = ThemeController(FailingPreferences());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ThemeControllerScope(
        controller: controller,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ThemeModeSelector())),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CheckedPopupMenuItem<ThemeMode> &&
            widget.value == ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.system);
    expect(find.textContaining('Could not save theme:'), findsOneWidget);
  });

  test('light and dark themes color primary surfaces and ensure contrast', () {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.create(brightness);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, brightness);
      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.primary);
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onPrimary);
      final background = theme.colorScheme.primary.computeLuminance();
      final foreground = theme.colorScheme.onPrimary.computeLuminance();
      final ratio = background > foreground
          ? (background + 0.05) / (foreground + 0.05)
          : (foreground + 0.05) / (background + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(theme.cardTheme.color, theme.colorScheme.surfaceContainerHigh);
    }
  });
}
