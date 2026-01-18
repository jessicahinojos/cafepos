import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CategoryManagementDialog extends StatefulWidget {
  const CategoryManagementDialog({super.key});

  @override
  State<CategoryManagementDialog> createState() =>
      _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final List<Map<String, dynamic>> _categories = [
    {
      "id": 1,
      "name": "Bebidas Calientes",
      "productCount": 15,
      "isActive": true,
    },
    {"id": 2, "name": "Bebidas Frías", "productCount": 12, "isActive": true},
    {"id": 3, "name": "Panadería", "productCount": 8, "isActive": true},
    {"id": 4, "name": "Comida", "productCount": 20, "isActive": true},
    {"id": 5, "name": "Postres", "productCount": 6, "isActive": true},
    {"id": 6, "name": "Snacks", "productCount": 10, "isActive": false},
  ];

  void _addCategory() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nueva Categoría',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            hintText: 'Ej: Bebidas Especiales',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _categories.add({
                    "id": _categories.length + 1,
                    "name": nameController.text,
                    "productCount": 0,
                    "isActive": true,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoría creada exitosamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _editCategory(int index) {
    final category = _categories[index];
    final TextEditingController nameController = TextEditingController(
      text: category["name"] as String,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Editar Categoría',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _categories[index]["name"] = nameController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoría actualizada exitosamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int index) {
    final category = _categories[index];
    final productCount = category["productCount"] as int;

    if (productCount > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'No se puede eliminar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Esta categoría tiene $productCount productos asociados. Por favor, reasigne los productos antes de eliminar la categoría.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar Categoría',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Está seguro de que desea eliminar esta categoría?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Categoría eliminada exitosamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _toggleCategoryStatus(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _categories[index]["isActive"] =
          !(_categories[index]["isActive"] as bool);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: EdgeInsets.all(4.w),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestionar Categorías',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: EdgeInsets.all(4.w),
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isActive = category["isActive"] as bool;

                  return Container(
                    key: ValueKey(category["id"]),
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      leading: CustomIconWidget(
                        iconName: 'drag_handle',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      title: Text(
                        category["name"] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${category["productCount"]} productos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (_) => _toggleCategoryStatus(index),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          PopupMenuButton(
                            icon: CustomIconWidget(
                              iconName: 'more_vert',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'edit',
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    SizedBox(width: 3.w),
                                    const Text('Editar'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _editCategory(index),
                                  );
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'delete',
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: 3.w),
                                    const Text('Eliminar'),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () => _deleteCategory(index),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addCategory,
                  icon: CustomIconWidget(
                    iconName: 'add',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: const Text('Nueva Categoría'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
