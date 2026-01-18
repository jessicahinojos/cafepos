import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../services/storage_service.dart';

class AddProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final Function(Map<String, dynamic>) onSave;

  const AddProductDialog({super.key, this.product, required this.onSave});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final StorageService _storageService = StorageService();

  String? _selectedCategory;
  bool _isActive = true;
  String? _imageUrl;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<String> _categories = [
    'Bebidas Calientes',
    'Bebidas Frías',
    'Panadería',
    'Comida',
    'Postres',
    'Snacks',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!["name"] as String;
      _descriptionController.text = widget.product!["description"] as String;
      _skuController.text = widget.product!["sku"] as String;
      _priceController.text = (widget.product!["price"] as double).toString();
      _selectedCategory = widget.product!["category"] as String;
      _isActive = widget.product!["isActive"] as bool;
      _imageUrl = widget.product!["image"] as String;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _imageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar imagen'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImageFile = File(photo.path);
          _imageUrl = photo.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al tomar foto'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Seleccionar Imagen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor seleccione una categoría'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        String? finalImageUrl = _imageUrl;

        // Upload new image if file was selected
        if (_selectedImageFile != null) {
          final storagePath = await _storageService.uploadProductImage(
            _selectedImageFile!,
          );
          finalImageUrl = _storageService.getProductImageUrl(storagePath);
        }

        final productData = {
          "id": widget.product?["id"] ?? DateTime.now().millisecondsSinceEpoch,
          "name": _nameController.text,
          "description": _descriptionController.text,
          "sku": _skuController.text,
          "price": double.parse(_priceController.text),
          "category": _selectedCategory,
          "image":
              finalImageUrl ??
              "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400",
          "semanticLabel": "Imagen del producto ${_nameController.text}",
          "isActive": _isActive,
          "hasRecipe": widget.product?["hasRecipe"] ?? false,
          "salesCount": widget.product?["salesCount"] ?? 0,
        };

        widget.onSave(productData);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar producto: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: EdgeInsets.all(4.w),
      child: Container(
        constraints: BoxConstraints(maxHeight: 90.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product != null
                          ? 'Editar Producto'
                          : 'Agregar Producto',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _isUploading ? null : _showImageSourceDialog,
                          child: Stack(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: _imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _selectedImageFile != null
                                            ? Image.file(
                                                _selectedImageFile!,
                                                width: 40.w,
                                                height: 40.w,
                                                fit: BoxFit.cover,
                                              )
                                            : CustomImageWidget(
                                                imageUrl: _imageUrl!,
                                                width: 40.w,
                                                height: 40.w,
                                                fit: BoxFit.cover,
                                                semanticLabel:
                                                    "Imagen del producto",
                                              ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'add_a_photo',
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            size: 48,
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            'Agregar Foto',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Producto *',
                          hintText: 'Ej: Café Americano',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción *',
                          hintText: 'Descripción del producto',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese la descripción';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU *',
                          hintText: 'Ej: CAF-001',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el SKU';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          hintText: '0.00',
                          prefixText: 'Bs ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el precio';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Por favor ingrese un precio válido';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bebidas Calientes',
                            child: Text('Bebidas Calientes'),
                          ),
                          DropdownMenuItem(
                            value: 'Bebidas Frías',
                            child: Text('Bebidas Frías'),
                          ),
                          DropdownMenuItem(
                            value: 'Panadería',
                            child: Text('Panadería'),
                          ),
                          DropdownMenuItem(
                            value: 'Comida',
                            child: Text('Comida'),
                          ),
                          DropdownMenuItem(
                            value: 'Postres',
                            child: Text('Postres'),
                          ),
                          DropdownMenuItem(
                            value: 'Snacks',
                            child: Text('Snacks'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      SizedBox(height: 2.h),
                      SwitchListTile(
                        title: const Text('Producto Activo'),
                        subtitle: Text(
                          _isActive
                              ? 'Visible en el sistema'
                              : 'Oculto del sistema',
                          style: theme.textTheme.bodySmall,
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
                    child: OutlinedButton(
                      onPressed: _isUploading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveProduct,
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar'),
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
