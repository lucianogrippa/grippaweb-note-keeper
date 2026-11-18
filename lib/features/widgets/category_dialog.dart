import 'package:flutter/material.dart';
import 'package:note_keeper/app/domain/categories.dart';

class NoteCategoryDialog extends StatelessWidget {
  final String title;
  final NoteCategory? category;
  final void Function(NoteCategory category) onSubmit;

  const NoteCategoryDialog({
    super.key,
    this.category,
    required this.title,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newCategory = NoteCategory()
              ..id = category?.id ?? ''
              ..name = nameController.text.trim()
              ..description = descriptionController.text.trim();
            onSubmit(newCategory);
            
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
