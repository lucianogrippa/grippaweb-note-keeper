import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/features/home/note_search.dart';
import 'package:note_keeper/features/home/notes_page.dart';
import 'package:note_keeper/features/home/home_page.dart';
import 'package:note_keeper/features/home/groups_page.dart';

import 'groups_page_test.dart' show FakeAccountService, FakeGroups;
import 'notes_repository_test.dart'
    show NoteTestDatabase, NoteTestStorage, NotesBox;

class SearchCategories implements INoteCategoryRepository {
  final categories = <NoteCategory>[
    NoteCategory()
      ..id = 'a'
      ..userId = 'user'
      ..name = 'Work',
    NoteCategory()
      ..id = 'b'
      ..userId = 'user'
      ..name = 'Personal',
    NoteCategory()
      ..id = 'c'
      ..userId = 'other'
      ..name = 'Other',
  ];

  @override
  Future<Set<NoteCategory>> findByUserId(String userId) async =>
      categories.where((category) => category.userId == userId).toSet();

  @override
  Future<NoteCategory?> findById(String id) async =>
      categories.where((category) => category.id == id).firstOrNull;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class SearchGroups extends FakeGroups {
  @override
  Future<NoteGroups?> getGroupById(String id) async => groups[id];
}

class SearchAuth implements AuthNotifier {
  @override
  final state = AuthState.authenticated(
    Account.fromUser(
      user: const User(id: 'user', name: 'User', lastname: '', email: ''),
    ),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late GoRouter router;
  late NoteRepository notes;

  setUp(() async {
    final categories = SearchCategories();
    for (final category in categories.categories) {
      category.description = 'Description';
      category.createdAt = DateTime(2026, 1, 1);
      category.updatedAt = category.createdAt;
    }
    final groups = SearchGroups();
    notes = NoteRepository(
      databaseService: NoteTestDatabase(),
      storageService: NoteTestStorage(),
    )..db = NotesBox();
    for (final (category, name) in [
      ('a', 'First'),
      ('a', 'Second'),
      ('b', 'Third'),
      ('c', 'Private'),
    ]) {
      await groups.createGroup(
        NoteGroups()
          ..id = ''
          ..categoriesId = category
          ..name = name,
      );
    }
    for (final (group, title, content, encrypted, description) in [
      ('0', 'Alpha match', 'first', true, ''),
      ('1', 'Beta match', 'second', false, ''),
      ('2', 'Gamma match', 'third', false, ''),
      ('3', 'Other match', 'private', false, ''),
      ('0', 'Different', 'match', false, ''),
      ('0', 'Descriptive note', 'unrelated', false, 'Searchable detail'),
    ]) {
      await notes.createNote(
        Notes()
          ..id = ''
          ..groupsId = group
          ..title = title
          ..content = content
          ..description = description
          ..isEncrypted = encrypted,
      );
    }
    locator.registerSingleton<INoteCategoryRepository>(categories);
    locator.registerSingleton<INoteGroupRepository>(groups);
    locator.registerSingleton<INoteRepository>(notes);
    locator.registerSingleton<IAccountService>(FakeAccountService());
    locator.registerSingleton<AuthNotifier>(SearchAuth());
    locator.registerSingleton(LoadingNotifier());
    locator.registerSingleton(NoteCategoryNotifier(categories));
    locator.registerSingleton(NoteGroupsNotifier(categories, groups));
    router = GoRouter(
      initialLocation: '/global',
      routes: [
        GoRoute(path: '/home', builder: (_, state) => const HomePage()),
        GoRoute(
          path: '/groups/:id',
          builder: (_, state) =>
              GroupsPage(categoryId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/global',
          builder: (_, state) =>
              const Scaffold(appBar: null, body: NoteSearchButton()),
        ),
        GoRoute(
          path: '/category/:id',
          builder: (_, state) => Scaffold(
            body: NoteSearchButton(categoryId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/group/:id',
          builder: (_, state) => Scaffold(
            body: NoteSearchButton(
              categoryId: 'a',
              groupId: state.pathParameters['id'],
            ),
          ),
        ),
        GoRoute(
          path: '/notes/:id',
          builder: (_, state) => NotesPage(
            groupId: state.pathParameters['id']!,
            noteId: state.uri.queryParameters['note'],
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await locator.reset();
  });

  testWidgets('searches titles in the current scope and opens a masked note', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mAtCh');
    await tester.pumpAndSettle();
    expect(find.text('Alpha match'), findsOneWidget);
    expect(find.text('Beta match'), findsOneWidget);
    expect(find.text('Gamma match'), findsOneWidget);
    expect(find.text('Other match'), findsNothing);
    expect(find.text('Different'), findsNothing);
    expect(find.text('Work / First'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.enterText(find.byType(TextField), 'searchable DETAIL');
    await tester.pumpAndSettle();
    expect(find.text('Descriptive note'), findsOneWidget);
    expect(find.text('Alpha match'), findsNothing);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    router.go('/category/a');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'match');
    await tester.pumpAndSettle();
    expect(find.text('Alpha match'), findsOneWidget);
    expect(find.text('Beta match'), findsOneWidget);
    expect(find.text('Gamma match'), findsNothing);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    router.go('/group/0');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'match');
    await tester.pumpAndSettle();
    expect(find.text('Alpha match'), findsOneWidget);
    expect(find.text('Beta match'), findsNothing);
    await tester.tap(find.text('Alpha match'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byTooltip('Show content'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ignores content and displays empty search state', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a note title or description to search.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pumpAndSettle();
    expect(find.text('No notes match your search.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a note title or description to search.'),
      findsOneWidget,
    );
  });

  testWidgets('real pages use their own scope and reopen a result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'match');
    await tester.pumpAndSettle();
    expect(find.text('Gamma match'), findsOneWidget);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    router.go('/groups/a');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search notes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'match');
    await tester.pumpAndSettle();
    expect(find.text('Beta match'), findsOneWidget);
    expect(find.text('Gamma match'), findsNothing);
    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    router.go('/notes/0');
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Search notes'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'match');
      await tester.pumpAndSettle();
      expect(find.text('Beta match'), findsNothing);
      await tester.tap(find.text('Alpha match').last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });
}
