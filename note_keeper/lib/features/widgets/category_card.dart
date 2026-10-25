import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/domain/categories.dart';

class CategoryCard extends StatelessWidget {

  final void Function(NoteCategory category) onViewClick;
  final void Function(NoteCategory category) onEditClick;
  final void Function(NoteCategory category) onDeleteClick;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onViewClick,
    required this.onEditClick,
    required this.onDeleteClick,
  });

  final NoteCategory category;


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: Text(
                  category.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                Text('Create at: ${DateFormat.yMMMMEEEEd().format(category.createdAt)}', textAlign: TextAlign.left,),
                IconButton(onPressed: () => onViewClick(category), icon: const Icon(Icons.note_alt), tooltip: 'View notes',),
                IconButton(onPressed: () => onEditClick(category), icon: const Icon(Icons.edit), tooltip: 'Edit category',),
                IconButton(onPressed: () => onDeleteClick(category), icon: const Icon(Icons.delete), tooltip: 'Delete category',),
              ],
            )
          ],
        ),
      ),
    );
  }
}