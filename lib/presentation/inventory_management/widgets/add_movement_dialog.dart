import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Add Movement Dialog
/// Form for recording inventory movements (IN, OUT, ADJUSTMENT)
class AddMovementDialog extends StatefulWidget {
  final List<Map<String, dynamic>> supplies;
  final Function(Map<String, dynamic>) onMovementAdded;

  const AddMovementDialog({
    super.key,
    required this.supplies,
    required this.onMovementAdded,
  });

  @override
  State<AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedSupply;
  String _selectedType = 'IN';
  final List<String> _movementTypes = ['IN', 'OUT', 'ADJUSTMENT'];

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _getMovementTypeText(String type) {
    switch (type) {
      case 'IN':
        return 'Entrada (Compra)';
      case 'OUT':
        return 'Salida (Consumo/Desperdicio)';
      case 'ADJUSTMENT':
        return 'Ajuste de Inventario';
      default:
        return type;
    }
  }

  Color _getMovementTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'IN':
        return theme.brightness == Brightness.light
            ? Color(0xFF059669)
            : Color(0xFF10B981);
      case 'OUT':
        return theme.brightness == Brightness.light
            ? Color(0xFFDC2626)
            : Color(0xFFEF4444);
      case 'ADJUSTMENT':
        return theme.brightness == Brightness.light
            ? Color(0xFFD97706)
            : Color(0xFFF59E0B);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  void _submitMovement() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      final supply = widget.supplies.firstWhere(
        (s) => s["name"] == _selectedSupply,
      );

      double quantity = double.parse(_quantityController.text);
      if (_selectedType == 'OUT') {
        quantity = -quantity.abs();
      } else if (_selectedType == 'ADJUSTMENT') {
        // Keep the sign as entered by user
      } else {
        quantity = quantity.abs();
      }

      final movement = {
        "id": DateTime.now().millisecondsSinceEpoch,
        "supplyName": _selectedSupply!,
        "type": _selectedType,
        "quantity": quantity,
        "unit": supply["unit"],
        "timestamp": DateTime.now(),
        "user": "Usuario Actual",
        "note": _noteController.text.trim(),
      };

      widget.onMovementAdded(movement);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Movimiento registrado exitosamente'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Registrar Movimiento',
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  'Tipo de Movimiento',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  children: _movementTypes.map((type) {
                    final isSelected = _selectedType == type;
                    final typeColor = _getMovementTypeColor(type, theme);
                    return ChoiceChip(
                      label: Text(_getMovementTypeText(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedType = type);
                        }
                      },
                      selectedColor: typeColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? typeColor
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? typeColor
                            : theme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Suministro',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSupply,
                  decoration: InputDecoration(
                    hintText: 'Seleccionar suministro',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                  items: widget.supplies.map((supply) {
                    return DropdownMenuItem<String>(
                      value: supply["name"],
                      child: Text(
                        '${supply["name"]} (${supply["unit"]})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSupply = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor seleccione un suministro';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),
                Text(
                  'Cantidad',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: _selectedType == 'ADJUSTMENT'
                        ? 'Ingrese cantidad (+ o -)'
                        : 'Ingrese cantidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    suffixText: _selectedSupply != null
                        ? widget.supplies.firstWhere(
                            (s) => s["name"] == _selectedSupply,
                          )["unit"]
                        : '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una cantidad';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    if (_selectedType != 'ADJUSTMENT' && quantity <= 0) {
                      return 'La cantidad debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 3.h),
                Text(
                  'Nota (Opcional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Agregar nota sobre este movimiento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitMovement,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Registrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
