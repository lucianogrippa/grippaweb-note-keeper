import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/features/widgets/category_card.dart';

void main() {
  testWidgets('description fills the card width and is clickable', (
    tester,
  ) async {
    final category = NoteCategory()
      ..name = 'Category'
      ..description = 'Short description'
      ..createdAt = DateTime(2026, 1, 1);
    NoteCategory? selectedCategory;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 300,
              child: CategoryCard(
                category: category,
                onViewClick: (selected) => selectedCategory = selected,
                onEditClick: (_) {},
                onDeleteClick: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final cardContent = tester.getRect(
      find
          .descendant(of: find.byType(Card), matching: find.byType(Column))
          .first,
    );
    final descriptionInkWell = find
        .ancestor(
          of: find.text('Short description'),
          matching: find.byType(InkWell),
        )
        .first;
    final description = tester.getRect(descriptionInkWell);
    expect(description.left, cardContent.left);
    expect(description.right, cardContent.right);

    await tester.tapAt(Offset(description.right - 4, description.center.dy));
    expect(selectedCategory, same(category));
  });
}
