import 'dart:io';
import './supabase_service.dart';

/// Service for handling Supabase storage operations
class StorageService {
  final _client = SupabaseService.client;
  static const String productImagesBucket = 'product-images';

  /// Upload product image to Supabase storage
  /// Returns the storage path of the uploaded image
  Future<String> uploadProductImage(File imageFile) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Generate unique filename
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final filePath = 'products/$fileName';

      // Upload file to storage
      await _client.storage
          .from(productImagesBucket)
          .upload(filePath, imageFile);

      return filePath;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Get public URL for a product image
  String getProductImageUrl(String filePath) {
    try {
      return _client.storage.from(productImagesBucket).getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Error al obtener URL de imagen: $e');
    }
  }

  /// Delete product image from storage
  Future<void> deleteProductImage(String filePath) async {
    try {
      await _client.storage.from(productImagesBucket).remove([filePath]);
    } catch (e) {
      throw Exception('Error al eliminar imagen: $e');
    }
  }

  /// Update product image (delete old, upload new)
  Future<String> updateProductImage({
    required File newImageFile,
    String? oldImagePath,
  }) async {
    try {
      // Delete old image if exists
      if (oldImagePath != null && oldImagePath.isNotEmpty) {
        try {
          await deleteProductImage(oldImagePath);
        } catch (e) {
          // Continue even if delete fails
        }
      }

      // Upload new image
      return await uploadProductImage(newImageFile);
    } catch (e) {
      throw Exception('Error al actualizar imagen: $e');
    }
  }

  /// Check if file is an image
  bool isImageFile(String path) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
}
