import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/auth_state.dart';
import 'package:note_keeper/app/domain/groups.dart';
import 'package:note_keeper/app/domain/notes.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/app/repositories/category_repository.dart';
import 'package:note_keeper/app/repositories/groups_repository.dart';
import 'package:note_keeper/app/repositories/notes_repository.dart';
import 'package:note_keeper/app/services/account_service.dart';
import 'package:note_keeper/features/home/home_scaffold.dart';
import 'package:note_keeper/features/home/note_search.dart';
import 'package:note_keeper/features/widgets/responsive_grid.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.groupId, this.noteId});

  final String groupId;
  final String? noteId;

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _notes = locator<INoteRepository>();
  final _groups = locator<INoteGroupRepository>();
  final _categories = locator<INoteCategoryRepository>();
  final _account = locator<IAccountService>();
  final _revealed = <String, String>{};
  final _revealing = <String>{};
  late Future<NoteGroups?> _groupFuture;
  List<Notes> _items = [];
  String? _openedNoteId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _groupFuture = _load(widget.groupId);
  }

  @override
  void didUpdateWidget(covariant NotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _items = [];
      _revealed.clear();
      _revealing.clear();
      _openedNoteId = null;
      _groupFuture = _load(widget.groupId);
    } else if (oldWidget.noteId != widget.noteId) {
      _openedNoteId = null;
    }
  }

  Future<NoteGroups?> _load(String groupId) async {
    final session = await _account.checkSessionFromStoredToken();
    if (session.status != AuthStatus.authenticated) return null;
    final group = await _groups.getGroupById(groupId);
    if (group == null) return null;
    final category = await _categories.findById(group.categoriesId);
    if (category == null || category.userId != session.account.id) return null;
    final items = await _notes.getAll(groupId);
    if (mounted && widget.groupId == groupId) _items = items.toList();
    return group;
  }

  Future<String?> _reveal(Notes note) async {
    final session = await _account.checkSessionFromStoredToken();
    if (session.status != AuthStatus.authenticated) {
      throw StateError('Session expired. Please sign in again.');
    }
    final group = await _groups.getGroupById(note.groupsId);
    final category = group == null
        ? null
        : await _categories.findById(group.categoriesId);
    if (category == null || category.userId != session.account.id) {
      throw StateError('Note is no longer available.');
    }
    return _notes.revealContent(note.id);
  }

  Future<void> _toggleReveal(Notes note) async {
    if (_revealed.containsKey(note.id)) {
      setState(() => _revealed.remove(note.id));
      return;
    }
    setState(() => _revealing.add(note.id));
    try {
      final content = await _reveal(note);
      if (!mounted || widget.groupId != note.groupsId) return;
      if (content == null) {
        _error('Unable to decrypt note.');
      } else {
        setState(() => _revealed[note.id] = content);
      }
    } catch (error) {
      if (mounted) _error('Unable to decrypt note: $error');
    } finally {
      if (mounted) setState(() => _revealing.remove(note.id));
    }
  }

  void _error(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _view(Notes note) {
    showDialog<void>(
      context: context,
      builder: (context) => _NoteViewer(note: note, reveal: _reveal),
    );
  }

  Future<void> _refresh() async {
    final groupId = widget.groupId;
    final items = await _notes.getAll(groupId);
    if (!mounted || widget.groupId != groupId) return;
    setState(() {
      _items = items.toList();
      _revealed.clear();
    });
  }

  Future<void> _edit([Notes? note]) async {
    final groupId = widget.groupId;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NoteEditor(
        note: note,
        reveal: _reveal,
        save: (result) async {
          if (!mounted || widget.groupId != groupId) {
            throw StateError('The group is no longer open.');
          }
          final draft = Notes()
            ..id = note?.id ?? ''
            ..groupsId = groupId
            ..title = result.title
            ..content = result.content
            ..isEncrypted = result.encrypted;
          final saved = note == null
              ? await _notes.createNote(draft)
              : await _notes.updateNote(
                  draft,
                  preserveEncryptedContent: result.preserveEncryptedContent,
                );
          if (saved == null) {
            throw StateError('Check the title and encryption settings.');
          }
        },
      ),
    );
    if (saved != true || !mounted || widget.groupId != groupId) return;
    setState(() => _busy = true);
    try {
      await _refresh();
    } catch (error) {
      if (mounted) _error('Note saved, but could not reload notes: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Notes note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
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
    if (confirmed != true || !mounted || widget.groupId != note.groupsId) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await _notes.deleteNote(note.id)) {
        if (mounted) _error('Could not delete note.');
      } else {
        await _refresh();
      }
    } catch (error) {
      if (mounted) _error('Could not delete note: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<NoteGroups?>(
    future: _groupFuture,
    builder: (context, snapshot) {
      final group = snapshot.data;
      final ready =
          snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError &&
          group != null;
      if (ready && widget.noteId != null && widget.noteId != _openedNoteId) {
        final noteId = widget.noteId!;
        _openedNoteId = noteId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.noteId != noteId) return;
          final matches = _items.where((note) => note.id == noteId);
          if (matches.isEmpty) {
            _error('Note not found.');
          } else {
            _view(matches.first);
          }
        });
      }

      return HomeScaffold(
        title: Text(
          group == null ? 'Notes' : '${group.name} (${_items.length})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onBack: () => context.go(
          group == null ? '/home' : '/groups/${group.categoriesId}',
        ),
        actions: [
          NoteSearchButton(
            categoryId: group?.categoriesId,
            groupId: widget.groupId,
            enabled: ready,
            onSelected: _view,
          ),
          IconButton(
            tooltip: 'Add note',
            onPressed: !ready || _busy ? null : () => _edit(),
            icon: const Icon(Icons.add),
          ),
        ],
        body: snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
            ? Center(child: Text('Failed to load notes: ${snapshot.error}'))
            : group == null
            ? const Center(child: Text('Group not found.'))
            : _items.isEmpty
            ? Center(child: Text('Use add button to add notes.'))
            : ResponsiveGrid(
                itemHeight: 220,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final note = _items[index];
                  final revealed = _revealed[note.id];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => _view(note),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: note.isEncrypted
                                ? const Icon(Icons.lock_outline)
                                : null,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                note.isEncrypted
                                    ? (revealed ?? '••••••••')
                                    : note.content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _CopyNoteMenu(
                                title: note.title,
                                content: note.isEncrypted
                                    ? revealed
                                    : note.content,
                              ),
                              if (note.isEncrypted)
                                IconButton(
                                  tooltip: revealed == null
                                      ? 'Show content'
                                      : 'Hide content',
                                  onPressed: _revealing.contains(note.id)
                                      ? null
                                      : () => _toggleReveal(note),
                                  icon: Icon(
                                    revealed == null
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              IconButton(
                                tooltip: 'Edit note',
                                onPressed: _busy ? null : () => _edit(note),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'Delete note',
                                onPressed: _busy ? null : () => _delete(note),
                                icon: const Icon(Icons.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
    },
  );
}

class _NoteViewer extends StatefulWidget {
  const _NoteViewer({required this.note, required this.reveal});

  final Notes note;
  final Future<String?> Function(Notes) reveal;

  @override
  State<_NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<_NoteViewer> {
  String? _content;
  bool _loading = false;
  String? _error;

  Future<void> _toggle() async {
    if (_content != null) {
      setState(() => _content = null);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = await widget.reveal(widget.note);
      if (!mounted) return;
      setState(() {
        _content = content;
        if (content == null) _error = 'Unable to decrypt note.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to decrypt note: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.note.title),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.isEncrypted
                  ? (_content ?? '••••••••')
                  : widget.note.content,
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      _CopyNoteMenu(
        title: widget.note.title,
        content: widget.note.isEncrypted ? _content : widget.note.content,
      ),
      if (widget.note.isEncrypted)
        IconButton(
          tooltip: _content == null ? 'Show content' : 'Hide content',
          onPressed: _loading ? null : _toggle,
          icon: Icon(
            _content == null ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

enum _CopyNoteField { title, content }

class _CopyNoteMenu extends StatelessWidget {
  const _CopyNoteMenu({required this.title, required this.content});

  final String title;
  final String? content;

  Future<void> _copy(BuildContext context, _CopyNoteField field) async {
    final text = field == _CopyNoteField.title ? title : content;
    if (text == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              field == _CopyNoteField.title
                  ? 'Title copied to clipboard.'
                  : 'Content copied to clipboard.',
            ),
          ),
        );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not copy to clipboard: ${error.message ?? error.code}',
          ),
        ),
      );
    } on MissingPluginException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<_CopyNoteField>(
    tooltip: 'Copy note',
    icon: const Icon(Icons.copy),
    onSelected: (field) => _copy(context, field),
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: _CopyNoteField.title,
        child: Text('Copy title'),
      ),
      PopupMenuItem(
        value: _CopyNoteField.content,
        enabled: content != null,
        child: const Text('Copy content'),
      ),
    ],
  );
}

class _NoteDraft {
  const _NoteDraft(
    this.title,
    this.content,
    this.encrypted,
    this.preserveEncryptedContent,
  );
  final String title;
  final String content;
  final bool encrypted;
  final bool preserveEncryptedContent;
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({
    required this.note,
    required this.reveal,
    required this.save,
  });
  final Notes? note;
  final Future<String?> Function(Notes) reveal;
  final Future<void> Function(_NoteDraft) save;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _content = TextEditingController(
    text: widget.note?.isEncrypted == true ? '' : widget.note?.content ?? '',
  );
  late bool _encrypted = widget.note?.isEncrypted ?? false;
  late bool _unlocked = widget.note?.isEncrypted != true;
  late bool _visible = _unlocked;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await widget.save(
        _NoteDraft(_title.text.trim(), _content.text, _encrypted, !_unlocked),
      );
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save note: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_visible) {
      setState(() => _visible = false);
      return;
    }
    if (_unlocked) {
      setState(() => _visible = true);
      return;
    }
    setState(() => _loading = true);
    try {
      final content = await widget.reveal(widget.note!);
      if (!mounted) return;
      if (content == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to decrypt note.')),
        );
      } else {
        setState(() {
          _content.text = content;
          _unlocked = true;
          _visible = true;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to decrypt note: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_visible)
                TextFormField(
                  controller: _content,
                  decoration: const InputDecoration(labelText: 'Content'),
                  minLines: 3,
                  maxLines: 8,
                )
              else
                const ListTile(
                  title: Text('Content'),
                  subtitle: Text('••••••••'),
                ),
              const SizedBox(height: 8),
              if (widget.note?.isEncrypted == true)
                IconButton(
                  tooltip: _visible ? 'Hide content' : 'Show content',
                  onPressed: _loading ? null : _toggle,
                  icon: Icon(
                    _visible ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              SwitchListTile(
                title: const Text('Encrypt note'),
                value: _encrypted,
                onChanged: !_unlocked
                    ? null
                    : (value) => setState(() => _encrypted = value),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _loading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _loading ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );
}
