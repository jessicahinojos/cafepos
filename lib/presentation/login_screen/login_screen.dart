import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/email_login_widget.dart';
import './widgets/pin_pad_widget.dart';

/// Login Screen for CafePOS Application
/// Provides PIN and email authentication with biometric support
/// Implements secure access control for restaurant staff
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPinLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 6.h),
                _buildLogo(theme),
                SizedBox(height: 4.h),
                _buildAppTitle(theme),
                SizedBox(height: 2.h),
                _buildSubtitle(theme),
                SizedBox(height: 6.h),
                _buildAuthToggle(theme),
                SizedBox(height: 4.h),
                _buildAuthContent(theme),
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  _buildErrorMessage(theme),
                ],
                SizedBox(height: 4.h),
                _buildBiometricOption(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'restaurant',
          size: 15.w,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAppTitle(ThemeData theme) {
    return Text(
      'CafePOS',
      style: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Text(
      'Sistema de Punto de Venta',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildAuthToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'PIN',
              isSelected: _isPinLogin,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isPinLogin = true;
                  _errorMessage = '';
                });
              },
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Email',
              isSelected: !_isPinLogin,
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isPinLogin = false;
                  _errorMessage = '';
                });
              },
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthContent(ThemeData theme) {
    return _isPinLogin
        ? PinPadWidget(onPinComplete: _handlePinLogin, isLoading: _isLoading)
        : EmailLoginWidget(onLogin: _handleEmailLogin, isLoading: _isLoading);
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFDC2626).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFDC2626)
              : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            size: 20,
            color: theme.brightness == Brightness.light
                ? const Color(0xFFDC2626)
                : const Color(0xFFEF4444),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricOption(ThemeData theme) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _handleBiometricLogin,
          icon: CustomIconWidget(
            iconName: 'fingerprint',
            size: 24,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            'Usar autenticación biométrica',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildDemoCredentials(theme),
      ],
    );
  }

  Widget _buildDemoCredentials(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Credenciales de Prueba:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          _buildCredentialRow(
            'Admin',
            'admin@cafepos.com / admin123 (PIN: 1234)',
            theme,
          ),
          _buildCredentialRow(
            'Caja',
            'cajero@cafepos.com / cajero123 (PIN: 5678)',
            theme,
          ),
          _buildCredentialRow(
            'Mesero',
            'mesero@cafepos.com / mesero123 (PIN: 9012)',
            theme,
          ),
          _buildCredentialRow(
            'Cocina',
            'cocina@cafepos.com / cocina123 (PIN: 3456)',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String role, String credentials, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 15.w,
            child: Text(
              '$role:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              credentials,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePinLogin(String pin) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Query user_profiles for matching PIN
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .eq('pin_code', pin)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        throw Exception('PIN incorrecto. Intente nuevamente.');
      }

      final email = response['email'] as String;

      // Map email to password (temporary solution for demo)
      final passwordMap = {
        'admin@cafepos.com': 'admin123',
        'cajero@cafepos.com': 'cajero123',
        'mesero@cafepos.com': 'mesero123',
        'cocina@cafepos.com': 'cocina123',
      };

      final password = passwordMap[email];
      if (password == null) {
        throw Exception('Error de configuración de usuario');
      }

      // Sign in with email and password
      await _authService.signInWithEmail(email: email, password: password);

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/main-dashboard');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleEmailLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _authService.signInWithEmail(email: email, password: password);

      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/main-dashboard');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(const Duration(seconds: 1));

    // Mock biometric authentication
    HapticFeedback.mediumImpact();
    if (mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/main-dashboard');
    }
  }
}
