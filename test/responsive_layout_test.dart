import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/theme/app_theme.dart';
import 'package:note_keeper/app/theme/theme_controller.dart';
import 'package:note_keeper/features/home/groups_page.dart';
import 'package:note_keeper/features/home/home_page.dart';
import 'package:note_keeper/features/home/notes_page.dart';
import 'package:note_keeper/features/login/login_page.dart';
import 'package:note_keeper/features/registration/registration_page.dart';
import 'package:note_keeper/features/widgets/responsive_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'groups_page_test.dart' show FakeAccountService;
import 'note_search_test.dart' show SearchAuth, SearchCategories, SearchGroups;
import 'notes_repository_test.dart'
    show NoteTestDatabase, NoteTestStorage, NotesBox;

void main() {
  late GoRouter router;
  late ThemeController themeController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    themeController = ThemeController(await SharedPreferences.getInstance());
    final categories = SearchCategories();
    for (final category in categories.categories) {
      category
        ..description = 'Description'
        ..createdAt = DateTime(2026, 1, 1)
        ..updatedAt = DateTime(2026, 1, 1);
    }
    categories.categories.first.name = 'A very long category title ' * 8;
    final groups = SearchGroups();
    await groups.createGroup(
      NoteGroups()
        ..id = ''
        ..categoriesId = 'a'
        ..name = 'A very long group title ' * 8,
    );
    final notes = NoteRepository(
      databaseService: NoteTestDatabase(),
      storageService: NoteTestStorage(),
    )..db = NotesBox();
    await notes.createNote(
      Notes()
        ..id = ''
        ..groupsId = '0'
        ..title = 'Title'
        ..content = 'Note content'
        ..isEncrypted = true,
    );
    locator.registerSingleton<INoteCategoryRepository>(categories);
    locator.registerSingleton<INoteGroupRepository>(groups);
    locator.registerSingleton<INoteRepository>(notes);
    locator.registerSingleton<IAccountService>(FakeAccountService());
    locator.registerSingleton<AuthNotifier>(SearchAuth());
    locator.registerSingleton(LoadingNotifier());
    locator.registerSingleton(NoteCategoryNotifier(categories));
    locator.registerSingleton(NoteGroupsNotifier(categories, groups));
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/groups/:id',
          builder: (_, state) =>
              GroupsPage(categoryId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notes/:id',
          builder: (_, state) =>
              NotesPage(groupId: state.pathParameters['id']!),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
          path: '/registration',
          builder: (_, _) => const RegistrationPage(),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await locator.reset();
    themeController.dispose();
  });

  for (final (size, columns) in [
    (const Size(320, 568), 1),
    (const Size(390, 844), 1),
    (const Size(568, 320), 1),
    (const Size(844, 390), 2),
    (const Size(768, 1024), 2),
    (const Size(1024, 768), 3),
    (const Size(1440, 900), 3),
  ]) {
    testWidgets('pages adapt to ${size.width}x${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ThemeControllerScope(
          controller: themeController,
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.create(Brightness.light),
            darkTheme: AppTheme.create(Brightness.dark),
            themeMode: themeController.mode,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      for (final path in ['/home', '/groups/a', '/notes/0']) {
        router.go(path);
        await tester.pumpAndSettle(const Duration(milliseconds: 400));
        final grid = tester.widget<GridView>(
          find.descendant(
            of: find.byType(ResponsiveGrid),
            matching: find.byType(GridView),
          ),
        );
        expect(
          (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
              .crossAxisCount,
          columns,
        );
        expect(find.byTooltip('Search notes'), findsOneWidget);
        expect(find.byTooltip('Theme'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: path);
      }
      for (final path in ['/login', '/registration']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsWidgets);
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  }

  testWidgets('dialogs and login scroll with enlarged text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ThemeControllerScope(
        controller: themeController,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.create(Brightness.light),
          darkTheme: AppTheme.create(Brightness.dark),
          themeMode: themeController.mode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New Category'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    router.go('/groups/a');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add group'));
    await tester.pumpAndSettle();
    expect(find.text('New Group'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    router.go('/notes/0');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    expect(find.text('New Note'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    router.go('/login');
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('passwordField')));
    await tester.enterText(find.byKey(const Key('passwordField')), 'example');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/registration');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Confirm your password'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
