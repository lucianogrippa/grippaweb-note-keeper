import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/features/home/groups_page.dart';
import 'package:note_keeper/features/home/notes_page.dart';

import 'groups_page_test.dart'
    show FakeAccountService, FakeCategories, FakeGroups;
import 'notes_repository_test.dart'
    show NoteTestDatabase, NoteTestStorage, NotesBox;

class PageGroups extends FakeGroups {
  @override
  Future<NoteGroups?> getGroupById(String id) async => groups[id];
}

void main() {
  late PageGroups groups;
  late NotesBox box;
  late NoteTestStorage storage;
  late FakeAccountService account;
  late GoRouter router;

  setUp(() async {
    groups = PageGroups();
    box = NotesBox();
    storage = NoteTestStorage();
    account = FakeAccountService();
    final categories = FakeCategories();
    final repository = NoteRepository(
      databaseService: NoteTestDatabase(),
      storageService: storage,
    )..db = box;
    await groups.createGroup(
      NoteGroups()
        ..id = ''
        ..categoriesId = 'category'
        ..name = 'Group',
    );
    locator.registerSingleton(NoteGroupsNotifier(categories, groups));
    locator.registerSingleton<INoteCategoryRepository>(categories);
    locator.registerSingleton<INoteGroupRepository>(groups);
    locator.registerSingleton<INoteRepository>(repository);
    locator.registerSingleton<IAccountService>(account);
    router = GoRouter(
      initialLocation: '/groups/category',
      routes: [
        GoRoute(
          path: '/groups/:id',
          builder: (_, state) =>
              GroupsPage(categoryId: state.pathParameters['id']!),
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

  testWidgets(
    'group opens notes; encrypted content is revealed only on demand',
    (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();
      expect(find.text('Group (0)'), findsOneWidget);

      await tester.tap(find.byTooltip('Add note'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Secret',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Content'),
        'private value',
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Secret'), findsOneWidget);
      expect(find.text('private value'), findsNothing);
      expect(box.entries.values.single.content, isNot('private value'));
      final ciphertext = box.entries.values.single.content;

      await tester.tap(find.text('Secret'));
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byTooltip('Show content'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsNothing);

      await tester.tap(find.byTooltip('Show content'));
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsOneWidget);
      await tester.tap(find.byTooltip('Hide content'));
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsNothing);

      await tester.tap(find.byTooltip('Edit note'));
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Content'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Renamed',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(box.entries.values.single.content, ciphertext);
      expect(find.text('Renamed'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit note'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byTooltip('Show content'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('private value'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Content'),
        'changed value',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('changed value'), findsNothing);
      await tester.tap(find.byTooltip('Show content'));
      await tester.pumpAndSettle();
      expect(find.text('changed value'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete note'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(box.entries, isEmpty);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Work (1)'), findsOneWidget);
    },
  );

  testWidgets('decryption failure leaves content hidden', (tester) async {
    final repo = locator<INoteRepository>();
    final note = (await repo.createNote(
      (Notes()
        ..id = ''
        ..groupsId = '0'
        ..title = 'Secret'
        ..content = 'private'
        ..isEncrypted = true),
    ))!;
    storage.available = false;
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Show content'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to decrypt note.'), findsOneWidget);
    expect(find.text('private'), findsNothing);
    expect(box.entries[note.id]!.content, isNot('***'));
  });

  testWidgets('other users cannot open a group', (tester) async {
    account.userId = 'other';
    await tester.pumpWidget(const MaterialApp(home: NotesPage(groupId: '0')));
    await tester.pumpAndSettle();
    expect(find.text('Group not found.'), findsOneWidget);
    final add = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add),
    );
    expect(add.onPressed, isNull);
  });

  testWidgets('copies titles and only visible encrypted content', (
    tester,
  ) async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<dynamic, dynamic>)['text'] as String,
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final repo = locator<INoteRepository>();
    await repo.createNote(
      Notes()
        ..id = ''
        ..groupsId = '0'
        ..title = 'Secret title'
        ..content = 'Secret content'
        ..isEncrypted = true,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy note'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuItem>(
            find.ancestor(
              of: find.text('Copy content'),
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuItem,
              ),
            ),
          )
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Copy title'));
    await tester.pumpAndSettle();
    expect(copied, ['Secret title']);

    await tester.tap(find.byTooltip('Show content'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy content'));
    await tester.pumpAndSettle();
    expect(copied, ['Secret title', 'Secret content']);

    await tester.tap(find.byTooltip('Hide content'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Secret title'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('Copy note')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuItem>(
            find.ancestor(
              of: find.text('Copy content'),
              matching: find.byWidgetPredicate(
                (widget) => widget is PopupMenuItem,
              ),
            ),
          )
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Copy title'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('Show content')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('Copy note')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy content'));
    await tester.pumpAndSettle();
    expect(copied, [
      'Secret title',
      'Secret content',
      'Secret title',
      'Secret content',
    ]);
  });

  testWidgets('copies unencrypted content', (tester) async {
    final copied = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<dynamic, dynamic>)['text'] as String,
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await locator<INoteRepository>().createNote(
      Notes()
        ..id = ''
        ..groupsId = '0'
        ..title = 'Plain'
        ..content = 'Full plain content'
        ..isEncrypted = false,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy content'));
    await tester.pumpAndSettle();
    expect(copied, ['Full plain content']);
  });

  testWidgets('plain notes display content and failed saves retain edits', (
    tester,
  ) async {
    final repo = locator<INoteRepository>();
    await repo.createNote(
      Notes()
        ..id = ''
        ..groupsId = '0'
        ..title = 'Existing'
        ..content = 'First'
        ..isEncrypted = false,
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.byTooltip('Show content'), findsNothing);
    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Existing',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Content'),
      'Unsaved text',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save note'), findsOneWidget);
    expect(find.text('Unsaved text'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Another',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved text'), findsOneWidget);
    expect(box.entries, hasLength(2));
  });
}
