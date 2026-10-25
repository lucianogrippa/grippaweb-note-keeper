import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final authNotifier = locator<AuthNotifier>();
  final loadNotifier = locator<LoadingNotifier>();

  final noteCategoryNotifier = locator<NoteCategoryNotifier>();
  ValueNotifier<String> outputMessage = ValueNotifier('');

  final TextEditingController _categoryNameController =
  TextEditingController();
  final TextEditingController _categoryDescriptionController =
  TextEditingController();

  @override
  void initState() {
    
    super.initState();

    var userId = authNotifier.state.account.id;

    this.noteCategoryNotifier.loadCategories(userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Note Keeper'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            tooltip: _isSearching ? 'Close search' : 'Search categories',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          IconButton(
            onPressed: () => _addNewCategory(context),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: noteCategoryNotifier,
          builder: (context, child) {
            var totalCategories = noteCategoryNotifier.categoryList.length;

            if (totalCategories == 0) {
              return Text('Use add button to add categories.');
            }

            return ListView.builder(
              itemCount: totalCategories,
              itemBuilder: (context, index) {
                var category = noteCategoryNotifier.categoryList.elementAt(
                  index,
                );

                // insert card for each items
                return Card(child: ListTile(title: Text(category.name)));
              },
            );
          },
        ),
      ),
    );
  }

  void _addNewCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {



        return AlertDialog(
          title: const Text('Add New Category'),
          actionsAlignment: MainAxisAlignment.end,

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: const InputDecoration(hintText: 'Category Name'),
              ),
              TextField(
                controller: _categoryDescriptionController,
                decoration: const InputDecoration(
                  hintText: 'Category Description',
                ),
              ),

              if(outputMessage.value.isNotEmpty)
                ValueListenableBuilder(
                  valueListenable: outputMessage,
                  builder: (context, value, child) {
                    return Text(
                      value,
                      style: const TextStyle(color: Colors.red),
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                loadNotifier.show();
                
                Future.delayed(const Duration(seconds: 1), () async {
                  if(!context.mounted) return;

                  await _confirmAddCategory(context);
                  loadNotifier.hide();
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAddCategory(BuildContext context) async{
    outputMessage.value = '';

    final categoryName = _categoryNameController.text.trim();
    final categoryDescription = _categoryDescriptionController.text.trim();

    if (categoryName.isNotEmpty) {

      if(categoryName.isEmpty) {
        outputMessage.value = 'Category name cannot be empty';
      }

      // max 150 characters for category name
      if(categoryName.length > 150) {
        outputMessage.value = 'Category name cannot exceed 150 characters';
      }

      if(categoryDescription.isEmpty) {
        outputMessage.value = 'Category description cannot be empty';
      }

      // max 300 characters for category description
      if(categoryDescription.length > 300) {
        outputMessage.value = 'Category description cannot exceed 300 characters';
      }

      NoteCategory category = NoteCategory()
        ..id = ''
        ..name = categoryName
        ..description = _categoryDescriptionController.text.trim()
        ..userId = authNotifier.state.account.id;

      // Add the new category using the notifier
      var newCategory = await noteCategoryNotifier.addCategory(category);

      if(newCategory == null) {
        outputMessage.value = 'Failed to add category';
        return;
      }

      if(!context.mounted) return;

      Navigator.of(context).pop();
    }
  }

  void _logout(BuildContext context) async {
    await authNotifier.logout();

    if (context.mounted) {
      context.go("/login");
    }
  }
}
