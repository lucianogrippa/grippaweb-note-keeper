import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';

class NoteSearchButton extends StatelessWidget {
  const NoteSearchButton({
    super.key,
    this.categoryId,
    this.groupId,
    this.enabled = true,
    this.onSelected,
  });

  final String? categoryId;
  final String? groupId;
  final bool enabled;
  final ValueChanged<Notes>? onSelected;

  Future<void> _open(BuildContext context) async {
    final result = await showSearch<_SearchResult?>(
      context: context,
      delegate: _NoteSearchDelegate(categoryId: categoryId, groupId: groupId),
    );
    if (!context.mounted || result == null) return;
    if (onSelected != null && result.group.id == groupId) {
      onSelected!(result.note);
    } else {
      context.go(
        Uri(
          path: '/notes/${result.group.id}',
          queryParameters: {'note': result.note.id},
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Search notes',
    onPressed: !enabled ? null : () => _open(context),
    icon: const Icon(Icons.search),
  );
}

class _SearchResult {
  const _SearchResult(this.note, this.group, this.category);
  final Notes note;
  final NoteGroups group;
  final NoteCategory category;
}

class _NoteSearchDelegate extends SearchDelegate<_SearchResult?> {
  _NoteSearchDelegate({this.categoryId, this.groupId})
    : super(searchFieldLabel: 'Search titles and descriptions');

  final String? categoryId;
  final String? groupId;

  Future<List<_SearchResult>> _search(String text) async {
    final session = await locator<IAccountService>()
        .checkSessionFromStoredToken();
    if (session.status != AuthStatus.authenticated ||
        session.account.id.isEmpty) {
      throw StateError('Session expired. Please sign in again.');
    }
    final categories = await locator<INoteCategoryRepository>().findByUserId(
      session.account.id,
    );
    final selected = categories.where(
      (category) => categoryId == null || category.id == categoryId,
    );
    final results = <_SearchResult>[];
    for (final category in selected) {
      final groups = await locator<INoteGroupRepository>().getAllGroups(
        category.id,
      );
      for (final group in groups) {
        if (groupId != null && group.id != groupId) continue;
        final notes = await locator<INoteRepository>().searchWithTitleOrContent(
          group.id,
          text,
          '',
        );
        results.addAll(
          notes.map((note) => _SearchResult(note, group, category)),
        );
      }
    }
    results.sort(
      (a, b) =>
          a.note.title.toLowerCase().compareTo(b.note.title.toLowerCase()),
    );
    return results;
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear search',
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Close search',
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildMatches();

  @override
  Widget buildSuggestions(BuildContext context) => _buildMatches();

  Widget _buildMatches() {
    final text = query.trim();
    if (text.isEmpty) {
      return const Center(
        child: Text('Enter a note title or description to search.'),
      );
    }
    return FutureBuilder<List<_SearchResult>>(
      future: _search(text),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to search notes: ${snapshot.error}'),
          );
        }
        final results = snapshot.requireData;
        if (results.isEmpty) {
          return const Center(child: Text('No notes match your search.'));
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return ListTile(
                  title: Text(
                    result.note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${result.category.name} / ${result.group.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: result.note.isEncrypted
                      ? const Icon(Icons.lock_outline)
                      : null,
                  onTap: () {
                    close(context, result);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
