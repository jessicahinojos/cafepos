import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen for CafePOS Application
/// Provides branded launch experience while initializing POS services
/// Determines user authentication status and navigates accordingly
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isInitializing = true;
  String _statusMessage = 'Inicializando sistema...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  /// Setup logo scale and fade animations
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  /// Initialize application services and determine navigation route
  Future<void> _initializeApp() async {
    try {
      // Simulate checking authentication tokens
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _statusMessage = 'Verificando autenticación...';
      });

      // Simulate loading offline data cache
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _statusMessage = 'Cargando datos locales...';
      });

      // Simulate syncing with Supabase
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _statusMessage = 'Sincronizando con servidor...';
      });

      // Simulate preparing product catalogs
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _statusMessage = 'Preparando catálogos...';
      });

      setState(() {
        _isInitializing = false;
      });

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 400));

      // Navigate based on authentication status
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        setState(() {
          _statusMessage = 'Error de inicialización';
          _isInitializing = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        _navigateToNextScreen();
      }
    }
  }

  /// Determine and navigate to appropriate screen
  void _navigateToNextScreen() {
    // Mock authentication check - in production, check actual auth tokens
    final bool isAuthenticated =
        false; // Change to true to test authenticated flow
    final bool hasActiveSession = false;

    if (isAuthenticated && hasActiveSession) {
      // Navigate to Main Dashboard for authenticated users with active sessions
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/main-dashboard');
    } else {
      // Navigate to Login Screen for users with expired sessions or first-time users
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/login-screen');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Hide status bar on Android, use brand-colored status bar on iOS
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.brightness == Brightness.light
                ? [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.primaryContainer,
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.surface.withValues(alpha: 0.95),
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo Section
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogoSection(theme),
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator and Status Message
              _buildLoadingSection(theme),

              SizedBox(height: size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }

  /// Build logo section with restaurant branding
  Widget _buildLogoSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'restaurant',
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // App Name
        Text(
          'CafePOS',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Sistema de Punto de Venta',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Build loading indicator and status message section
  Widget _buildLoadingSection(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading Indicator
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status Message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _statusMessage,
            key: ValueKey<String>(_statusMessage),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
