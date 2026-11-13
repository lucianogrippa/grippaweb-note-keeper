import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/user_account.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/features/home/groups_page.dart';

class FakeCategories implements INoteCategoryRepository {
  final category = NoteCategory()
    ..id = 'category'
    ..userId = 'user'
    ..name = 'Work';

  @override
  Future<NoteCategory?> findById(String id) async =>
      id == category.id ? category : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGroups implements INoteGroupRepository {
  final groups = <String, NoteGroups>{};
  int nextId = 0;

  @override
  Future<Set<NoteGroups>> getAllGroups(String categoryId) async =>
      groups.values.where((group) => group.categoriesId == categoryId).toSet();

  @override
  Future<NoteGroups?> createGroup(NoteGroups group) async {
    group.id = '${nextId++}';
    group.createdAt = DateTime(2026, 1, 1);
    group.updatedAt = group.createdAt;
    groups[group.id] = group;
    return group;
  }

  @override
  Future<NoteGroups?> updateGroup(NoteGroups group) async {
    groups[group.id] = group;
    return group;
  }

  @override
  Future<bool> deleteGroup(String id) async => groups.remove(id) != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotes implements INoteRepository {
  final groupsWithNotes = <String>{};

  @override
  Future<bool> hasNotes(String groupId) async =>
      groupsWithNotes.contains(groupId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountService implements IAccountService {
  String userId = 'user';

  @override
  Future<AuthState> checkSessionFromStoredToken() async =>
      AuthState.authenticated(
        Account.fromUser(
          user: User(id: userId, name: 'User', lastname: '', email: ''),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeGroups groups;
  late FakeNotes notes;
  late FakeAccountService account;

  setUp(() {
    groups = FakeGroups();
    notes = FakeNotes();
    account = FakeAccountService();
    locator.registerSingleton(NoteGroupsNotifier(FakeCategories(), groups));
    locator.registerSingleton<INoteRepository>(notes);
    locator.registerSingleton<IAccountService>(account);
  });

  tearDown(() async => locator.reset());

  testWidgets('group cards stay compact and usable on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await groups.createGroup(
      NoteGroups()
        ..id = ''
        ..categoriesId = 'category'
        ..name = 'A group',
    );
    await tester.pumpWidget(
      const MaterialApp(home: GroupsPage(categoryId: 'category')),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Card)).height, lessThan(150));
    expect(find.byTooltip('Edit group'), findsOneWidget);
    expect(find.byTooltip('Delete group'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates, edits and deletes groups', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GroupsPage(categoryId: 'category')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Work (0)'), findsOneWidget);
    expect(find.text('Use add button to add groups.'), findsOneWidget);

    await tester.tap(find.byTooltip('Add group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Group name cannot be empty'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '  Alpha  ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Work (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Beta');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Beta'), findsOneWidget);
    expect(groups.groups.values.single.createdAt, DateTime(2026, 1, 1));

    notes.groupsWithNotes.add(groups.groups.keys.single);
    await tester.tap(find.byTooltip('Delete group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cannot delete a group containing notes.'),
      findsOneWidget,
    );
    expect(groups.groups, hasLength(1));

    notes.groupsWithNotes.clear();
    await tester.tap(find.byTooltip('Delete group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(groups.groups, isEmpty);
    expect(find.text('Work (0)'), findsOneWidget);
  });

  testWidgets('does not expose groups belonging to another user', (
    tester,
  ) async {
    account.userId = 'other';
    await tester.pumpWidget(
      const MaterialApp(home: GroupsPage(categoryId: 'category')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Category not found.'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Add group'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
  });
}
