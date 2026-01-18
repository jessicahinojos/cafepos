import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication Service for CafePOS
/// Handles user authentication with PIN, email, and session management
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sign in with email and password
  /// Returns user profile data on success, null on failure
  Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }

      // Fetch user profile from user_profiles table
      final profileData = await _client
          .from('user_profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      return profileData;
    } on AuthException catch (e) {
      throw Exception('Error de autenticación: ${e.message}');
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Sign in with PIN code
  /// Validates PIN against user_profiles and creates session
  Future<Map<String, dynamic>?> signInWithPin({required String pin}) async {
    try {
      // Find user by PIN code
      final profiles = await _client
          .from('user_profiles')
          .select()
          .eq('pin_code', pin)
          .eq('is_active', true);

      if (profiles.isEmpty) {
        throw Exception('PIN incorrecto');
      }

      final profile = profiles.first;

      // Get the user's email for authentication
      final email = profile['email'] as String;

      // For PIN login, we need to use a temporary password approach
      // In production, consider implementing custom authentication
      // For now, we'll use email-based auth with stored password
      throw Exception(
        'PIN login requiere configuración adicional en producción',
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión con PIN: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Get current authenticated user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profileData = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .single();

      return profileData;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Validate user has required role
  Future<bool> hasRole(String requiredRole) async {
    try {
      final role = await getCurrentUserRole();
      if (role == null) return false;

      // Admin has access to everything
      if (role == 'admin') return true;

      // Check specific role
      return role == requiredRole;
    } catch (e) {
      return false;
    }
  }
}
