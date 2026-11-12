import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/app/theme/app_theme.dart';
import 'package:note_keeper/features/home/notes_page.dart';
import 'package:note_keeper/features/widgets/category_dialog.dart';

import 'groups_page_test.dart' show FakeAccountService;
import 'note_search_test.dart' show SearchCategories, SearchGroups;
import 'notes_repository_test.dart'
    show NoteTestDatabase, NoteTestStorage, NotesBox;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('category inputs are separated in $brightness', (tester) async {
      final category = NoteCategory()
        ..id = '1'
        ..name = 'Siti'
        ..description = 'Siti web';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.create(brightness),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => NoteCategoryDialog(
                    title: 'Edit Category',
                    category: category,
                    onSubmit: (_) {},
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      final first = tester.getRect(fields.at(0));
      final second = tester.getRect(fields.at(1));
      expect(second.top - first.bottom, greaterThanOrEqualTo(16));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('note editor separates title, content and encryption controls', (
    tester,
  ) async {
    final categories = SearchCategories();
    final groups = SearchGroups();
    final notes = NoteRepository(
      databaseService: NoteTestDatabase(),
      storageService: NoteTestStorage(),
    )..db = NotesBox();
    final group = await groups.createGroup(
      NoteGroups()
        ..id = ''
        ..categoriesId = 'a'
        ..name = 'Group',
    );
    locator.registerSingleton<INoteCategoryRepository>(categories);
    locator.registerSingleton<INoteGroupRepository>(groups);
    locator.registerSingleton<INoteRepository>(notes);
    locator.registerSingleton<IAccountService>(FakeAccountService());
    locator.registerSingleton(NoteGroupsNotifier(categories, groups));
    addTearDown(() async => locator.reset());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.create(Brightness.light),
        home: NotesPage(groupId: group!.id),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add note'));
    await tester.pumpAndSettle();
    final title = tester.getRect(find.widgetWithText(TextFormField, 'Title'));
    final content = tester.getRect(
      find.widgetWithText(TextFormField, 'Content'),
    );
    final encryption = tester.getRect(find.byType(SwitchListTile));
    expect(content.top - title.bottom, greaterThanOrEqualTo(16));
    expect(encryption.top - content.bottom, greaterThanOrEqualTo(8));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Title',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Content'),
      'Text',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await notes.getAll(group.id)).single.content, 'Text');
    expect(tester.takeException(), isNull);
  });
}
