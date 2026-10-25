import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:note_keeper/app/domain/categories.dart';
import 'package:note_keeper/app/notifiers/auth_notifier.dart';
import 'package:note_keeper/app/notifiers/loading_notifier.dart';
import 'package:note_keeper/app/notifiers/note_category_notifier.dart';
import 'package:note_keeper/app/providers/app_provider.dart';
import 'package:note_keeper/features/widgets/category_card.dart';
import 'package:note_keeper/features/widgets/category_dialog.dart';

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

  @override
  void initState() {
    super.initState();

    var userId = authNotifier.state.account.id;

    loadNotifier.show();

    Future.delayed(Duration(milliseconds: 300), () {
      if (!context.mounted) return;

      noteCategoryNotifier.loadCategories(userId);
      loadNotifier.hide();
    });
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
                  hintText: 'Search...',
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
            onPressed: () => _showAddCategory(context),
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

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1.5,
                mainAxisExtent: MediaQuery.of(context).size.height / 3,
              ),
              itemCount: totalCategories,

              itemBuilder: (context, index) {
                var category = noteCategoryNotifier.categoryList.elementAt(
                  index,
                ); // insert card for each items
                return CategoryCard(
                  category: category,
                  onViewClick: (category) {
                    _onGoToGroupView(context, category);
                  },
                  onEditClick: (category) {
                    _showEditDialog(context, category);
                  },
                  onDeleteClick: (category) {
                    _showDeleteDialog(context, category);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }


  void _showEditDialog(BuildContext context, NoteCategory category) {

    showDialog(context: context, builder: (context) {
      return NoteCategoryDialog(
        title: 'Edit Category',
        category: category,
        onSubmit: (NoteCategory categoryItem) {
          loadNotifier.show();

          Future.delayed(Duration(milliseconds: 300), () async {
            if(!context.mounted) return;
            await _confirmEditCategory(context, categoryItem);
            loadNotifier.hide();
            Navigator.of(context).pop(true);
          });

        },
      );
    });
  }

  void _showDeleteDialog(BuildContext context, NoteCategory category){

    // before delete show confirm dialog

   showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Category'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _confirmDelete(category);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

  }

  void _onGoToGroupView(BuildContext context, NoteCategory category) {
    context.go('/groups/${category.id}');
  }

  void _showAddCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return NoteCategoryDialog(
          title: 'New Category',
          onSubmit: (NoteCategory categoryItem) {
            loadNotifier.show();

            Future.delayed(Duration(milliseconds: 300), () async {
              if(!context.mounted) return;
              await _confirmAddCategory(context, categoryItem.name, categoryItem.description);
              loadNotifier.hide();
              Navigator.of(context).pop(true);
            });

          },
        );
      },
    );
  }

  Future<void> _confirmAddCategory(
    BuildContext context,
    String categoryName,
    String categoryDescription,
  ) async {
    outputMessage.value = '';

    if (categoryName.isNotEmpty) {
      if (categoryName.isEmpty) {
        outputMessage.value = 'Category name cannot be empty';
      }

      // max 150 characters for category name
      if (categoryName.length > 150) {
        outputMessage.value = 'Category name cannot exceed 150 characters';
      }

      if (categoryDescription.isEmpty) {
        outputMessage.value = 'Category description cannot be empty';
      }

      // max 300 characters for category description
      if (categoryDescription.length > 300) {
        outputMessage.value =
            'Category description cannot exceed 300 characters';
      }

      NoteCategory category = NoteCategory()
        ..id = ''
        ..name = categoryName
        ..description = categoryDescription
        ..userId = authNotifier.state.account.id;

      // Add the new category using the notifier
      var newCategory = await noteCategoryNotifier.addCategory(category);

      if (newCategory == null) {
        outputMessage.value = 'Failed to add category';
        return;
      }

      if (!context.mounted) return;

      Navigator.of(context).pop();
    }
  }

  void _logout(BuildContext context) async {
    await authNotifier.logout();

    if (context.mounted) {
      context.go("/login");
    }
  }

  Future<void> _confirmDelete(NoteCategory category) async {
    await noteCategoryNotifier.deleteCategory(category);
  }

  Future<void> _confirmEditCategory(BuildContext context, NoteCategory categoryItem) async {}
}
