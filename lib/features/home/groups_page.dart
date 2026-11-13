import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/notifiers/note_groups_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/features/home/home_scaffold.dart';
import 'package:note_keeper/features/home/note_search.dart';
import 'package:note_keeper/features/widgets/responsive_grid.dart';

class GroupsPage extends StatefulWidget {
  final String categoryId;

  const GroupsPage({super.key, required this.categoryId});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _groupsNotifier = locator<NoteGroupsNotifier>();
  final _notesRepository = locator<INoteRepository>();
  final _accountService = locator<IAccountService>();
  late Future<NoteCategory?> _categoryFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _categoryFuture = _loadCategory(widget.categoryId);
  }

  @override
  void didUpdateWidget(covariant GroupsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _categoryFuture = _loadCategory(widget.categoryId);
    }
  }

  Future<NoteCategory?> _loadCategory(String categoryId) async {
    final session = await _accountService.checkSessionFromStoredToken();
    final category = await _groupsNotifier.getCategoryById(categoryId);
    if (session.status != AuthStatus.authenticated ||
        category == null ||
        category.userId != session.account.id) {
      return null;
    }
    await _groupsNotifier.loadGroups(categoryId);
    return category;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editGroup([NoteGroups? group]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _GroupDialog(group: group),
    );
    if (name == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final edited = NoteGroups()
        ..id = group?.id ?? ''
        ..categoriesId = widget.categoryId
        ..name = name;
      if (group != null) {
        edited.createdAt = group.createdAt;
        edited.updatedAt = group.updatedAt;
      }
      final result = group == null
          ? await _groupsNotifier.addGroup(edited)
          : await _groupsNotifier.updateGroup(edited);
      if (result == null && mounted) {
        _showError('Failed to save group.');
      }
    } catch (error) {
      if (mounted) _showError('Failed to save group: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGroup(NoteGroups group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? Groups containing notes cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      if (await _notesRepository.hasNotes(group.id)) {
        if (mounted) _showError('Cannot delete a group containing notes.');
      } else if (!await _groupsNotifier.deleteGroup(group)) {
        if (mounted) _showError('Failed to delete group.');
      }
    } catch (error) {
      if (mounted) _showError('Failed to delete group: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NoteCategory?>(
      future: _categoryFuture,
      builder: (context, snapshot) {
        final category = snapshot.data;
        return ListenableBuilder(
          listenable: _groupsNotifier,
          builder: (context, _) {
            final allGroups = _groupsNotifier.getGroupsByCategoryId(
              widget.categoryId,
            );
            final groups = allGroups.toList();
            final ready =
                snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError &&
                category != null;

            return HomeScaffold(
              title: Text(
                category == null
                    ? 'Groups'
                    : '${category.name} (${allGroups.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onBack: () => context.go('/home'),
              actions: [
                NoteSearchButton(categoryId: widget.categoryId, enabled: ready),
                IconButton(
                  onPressed: !ready || _isSaving ? null : () => _editGroup(),
                  tooltip: 'Add group',
                  icon: const Icon(Icons.add),
                ),
              ],
              body: snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasError
                  ? Center(
                      child: Text('Failed to load groups: ${snapshot.error}'),
                    )
                  : category == null
                  ? const Center(child: Text('Category not found.'))
                  : groups.isEmpty
                  ? const Center(child: Text('Use add button to add groups.'))
                  : ResponsiveGrid(
                      itemHeight: 136,
                      scaledTextLines: 2,
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        return Container(
                          margin: const EdgeInsets.all(8),
                          child: Card(
                            child: InkWell(
                              onTap: () => context.go('/notes/${group.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(
                                      group.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: Text(
                                            'Create at: ${DateFormat.yMMMMEEEEd().format(group.createdAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _editGroup(group),
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'Edit group',
                                      ),
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _deleteGroup(group),
                                        icon: const Icon(Icons.delete),
                                        tooltip: 'Delete group',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}

class _GroupDialog extends StatefulWidget {
  const _GroupDialog({this.group});

  final NoteGroups? group;

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.group?.name ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.group == null ? 'New Group' : 'Edit Group'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Group name cannot be empty'
                  : null,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _nameController.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
