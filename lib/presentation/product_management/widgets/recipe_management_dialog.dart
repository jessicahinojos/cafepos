import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RecipeManagementDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const RecipeManagementDialog({super.key, required this.product});

  @override
  State<RecipeManagementDialog> createState() => _RecipeManagementDialogState();
}

class _RecipeManagementDialogState extends State<RecipeManagementDialog> {
  final List<Map<String, dynamic>> _ingredients = [
    {
      "id": 1,
      "name": "Café en grano",
      "quantity": 18.0,
      "unit": "gr",
      "stock": 5000.0,
    },
    {
      "id": 2,
      "name": "Agua",
      "quantity": 200.0,
      "unit": "ml",
      "stock": 50000.0,
    },
  ];

  final List<Map<String, dynamic>> _availableIngredients = [
    {"id": 3, "name": "Leche entera", "unit": "ml", "stock": 10000.0},
    {"id": 4, "name": "Azúcar", "unit": "gr", "stock": 2000.0},
    {"id": 5, "name": "Canela", "unit": "gr", "stock": 500.0},
    {"id": 6, "name": "Chocolate en polvo", "unit": "gr", "stock": 1500.0},
  ];

  final List<String> _units = ['gr', 'ml', 'units'];

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        availableIngredients: _availableIngredients,
        units: _units,
        onAdd: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingrediente agregado a la receta'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _ingredients.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingrediente eliminado de la receta'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateQuantity(int index, double quantity) {
    setState(() {
      _ingredients[index]["quantity"] = quantity;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestionar Receta',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          widget.product["name"] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
              child: _ingredients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'restaurant',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 64,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No hay ingredientes en la receta',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Agregue ingredientes para crear la receta',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _ingredients.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 2.h),
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ingredient["name"] as String,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Stock: ${(ingredient["stock"] as double).toStringAsFixed(0)} ${ingredient["unit"]}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 25.w,
                                child: TextFormField(
                                  initialValue:
                                      (ingredient["quantity"] as double)
                                          .toString(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    suffixText: ingredient["unit"] as String,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 3.w,
                                      vertical: 1.h,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final quantity = double.tryParse(value);
                                    if (quantity != null) {
                                      _updateQuantity(index, quantity);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 2.w),
                              IconButton(
                                icon: CustomIconWidget(
                                  iconName: 'delete',
                                  color: theme.colorScheme.error,
                                  size: 24,
                                ),
                                onPressed: () => _removeIngredient(index),
                              ),
                            ],
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addIngredient,
                      icon: CustomIconWidget(
                        iconName: 'add',
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      label: const Text('Agregar Ingrediente'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receta guardada exitosamente'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIngredientDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableIngredients;
  final List<String> units;
  final Function(Map<String, dynamic>) onAdd;

  const _AddIngredientDialog({
    required this.availableIngredients,
    required this.units,
    required this.onAdd,
  });

  @override
  State<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<_AddIngredientDialog> {
  Map<String, dynamic>? _selectedIngredient;
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Agregar Ingrediente', style: theme.textTheme.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedIngredient,
            decoration: const InputDecoration(labelText: 'Ingrediente'),
            items: widget.availableIngredients.map((ingredient) {
              return DropdownMenuItem(
                value: ingredient,
                child: Text(ingredient["name"] as String),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIngredient = value;
              });
            },
          ),
          SizedBox(height: 2.h),
          TextFormField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Cantidad',
              suffixText: _selectedIngredient?["unit"] as String? ?? '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedIngredient != null &&
                _quantityController.text.isNotEmpty) {
              final quantity = double.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                final ingredient = Map<String, dynamic>.from(
                  _selectedIngredient!,
                );
                ingredient["quantity"] = quantity;
                widget.onAdd(ingredient);
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
