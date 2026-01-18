import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/account_section_widget.dart';
import './widgets/business_settings_widget.dart';
import './widgets/data_management_widget.dart';
import './widgets/support_section_widget.dart';
import './widgets/system_settings_widget.dart';
import './widgets/user_management_widget.dart';

/// Settings Screen - Comprehensive app configuration and user management
/// Provides role-based access controls and grouped settings layout
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  // Mock business settings (would come from database in production)
  final Map<String, dynamic> businessSettings = {
    "restaurantName": "Café Delicias",
    "address": "Av. 6 de Agosto 2345, La Paz, Bolivia",
    "phone": "+591 2234 5678",
    "email": "info@cafedelicias.bo",
    "taxRate": 21.0,
    "currency": "EUR",
    "loyaltyPointsRate": 1.0,
    "receiptFooter": "¡Gracias por su visita!",
    "logo":
        "https://img.rocket.new/generatedImages/rocket_gen_img_187443be1-1766818927039.png",
    "logoSemanticLabel":
        "Café Delicias logo featuring a stylized coffee cup with steam in warm brown tones",
  };

  // Mock printer settings
  final Map<String, dynamic> printerSettings = {
    "connectedPrinter": "Epson TM-T20III",
    "connectionType": "Bluetooth",
    "paperWidth": "80mm",
    "autoPrint": true,
  };

  // Mock system preferences
  bool _offlineSync = true;
  bool _notifications = true;
  bool _biometricAuth = false;
  String _selectedTheme = "Auto";

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authService.getCurrentUserProfile();

      setState(() {
        currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: 'Configuración'),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_errorMessage != null || currentUser == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(title: 'Configuración'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 2.h),
              Text(
                'Error al cargar datos del usuario',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  _errorMessage ?? 'Usuario no encontrado',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: _loadCurrentUser,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Configuración',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'help_outline',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHelpDialog();
            },
            tooltip: 'Ayuda',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          children: [
            // Account Section
            AccountSectionWidget(
              currentUser: currentUser!,
              onLogout: _handleLogout,
            ),
            SizedBox(height: 3.h),

            // Business Settings (Admin only)
            if (currentUser!["role"] == "admin") ...[
              BusinessSettingsWidget(
                businessSettings: businessSettings,
                onEditReceipt: _showReceiptEditor,
                onEditBusiness: _showBusinessEditor,
              ),
              SizedBox(height: 3.h),
            ],

            // System Settings
            SystemSettingsWidget(
              printerSettings: printerSettings,
              offlineSync: _offlineSync,
              notifications: _notifications,
              biometricAuth: _biometricAuth,
              selectedTheme: _selectedTheme,
              onOfflineSyncChanged: (value) {
                setState(() => _offlineSync = value);
                HapticFeedback.lightImpact();
              },
              onNotificationsChanged: (value) {
                setState(() => _notifications = value);
                HapticFeedback.lightImpact();
              },
              onBiometricAuthChanged: (value) {
                setState(() => _biometricAuth = value);
                HapticFeedback.lightImpact();
              },
              onThemeChanged: (value) {
                setState(() => _selectedTheme = value);
                HapticFeedback.lightImpact();
              },
              onPrinterSetup: _showPrinterSetup,
            ),
            SizedBox(height: 3.h),

            // User Management (Admin only)
            if (currentUser!["role"] == "admin") ...[
              UserManagementWidget(
                onAddUser: _showAddUserDialog,
                onManageUsers: _navigateToUserManagement,
              ),
              SizedBox(height: 3.h),
            ],

            // Data Management
            DataManagementWidget(
              onBackup: _handleBackup,
              onRestore: _handleRestore,
              onClearCache: _handleClearCache,
            ),
            SizedBox(height: 3.h),

            // Support Section
            SupportSectionWidget(
              onContactSupport: _handleContactSupport,
              onViewDocumentation: _handleViewDocumentation,
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cerrar Sesión',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Está seguro de que desea cerrar sesión?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.signOut();

                if (mounted) {
                  Navigator.pop(context);
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/login-screen', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _showReceiptEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Editor de Recibo',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logo del Negocio',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 2.h),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Image picker would be implemented here
                        },
                        child: Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: businessSettings["logo"] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CustomImageWidget(
                                    imageUrl: businessSettings["logo"],
                                    width: 30.w,
                                    height: 30.w,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        businessSettings["logoSemanticLabel"],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'add_photo_alternate',
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 32,
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Subir Logo',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Mensaje de Pie de Página',
                        hintText: 'Ingrese mensaje personalizado',
                      ),
                      controller: TextEditingController(
                        text: businessSettings["receiptFooter"],
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vista Previa',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                if (businessSettings["logo"] != null)
                                  CustomImageWidget(
                                    imageUrl: businessSettings["logo"],
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                    semanticLabel:
                                        businessSettings["logoSemanticLabel"],
                                  ),
                                SizedBox(height: 1.h),
                                Text(
                                  businessSettings["restaurantName"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  businessSettings["address"],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 2.h),
                                const Divider(color: Colors.black),
                                SizedBox(height: 1.h),
                                Text(
                                  businessSettings["receiptFooter"],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Configuración de recibo guardada'),
                            ),
                          );
                        },
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBusinessEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Información del Negocio',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Restaurante',
                      ),
                      controller: TextEditingController(
                        text: businessSettings["restaurantName"],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      controller: TextEditingController(
                        text: businessSettings["address"],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      controller: TextEditingController(
                        text: businessSettings["phone"],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      controller: TextEditingController(
                        text: businessSettings["email"],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Tasa de IVA (%)',
                      ),
                      controller: TextEditingController(
                        text: businessSettings["taxRate"].toString(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Puntos de Fidelidad por Euro',
                      ),
                      controller: TextEditingController(
                        text: businessSettings["loyaltyPointsRate"].toString(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 3.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Información del negocio actualizada',
                              ),
                            ),
                          );
                        },
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrinterSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Configuración de Impresora',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'bluetooth_connected',
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impresora Conectada',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                printerSettings["connectedPrinter"],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Dispositivos Disponibles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 2.h),
                  ...List.generate(3, (index) {
                    final printers = [
                      "Epson TM-T20III",
                      "Star TSP143III",
                      "Bixolon SRP-350III",
                    ];
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: CustomIconWidget(
                          iconName: 'print',
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        title: Text(printers[index]),
                        subtitle: Text('Bluetooth'),
                        trailing: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Conectado a ${printers[index]}'),
                              ),
                            );
                          },
                          child: const Text('Conectar'),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 2.h),
                  OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buscando dispositivos...'),
                        ),
                      );
                    },
                    icon: CustomIconWidget(
                      iconName: 'refresh',
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    label: const Text('Buscar Dispositivos'),
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imprimiendo recibo de prueba...'),
                        ),
                      );
                    },
                    icon: CustomIconWidget(
                      iconName: 'print',
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    label: const Text('Imprimir Prueba'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Agregar Usuario',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
              SizedBox(height: 2.h),
              TextField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rol'),
                items: ['Admin', 'Cajero', 'Mesero', 'Cocina']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (value) {},
              ),
              SizedBox(height: 2.h),
              TextField(
                decoration: const InputDecoration(labelText: 'PIN (4 dígitos)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario agregado exitosamente')),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _navigateToUserManagement() {
    // Navigate to user management screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando a gestión de usuarios...')),
    );
  }

  void _handleBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Crear Copia de Seguridad',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Desea crear una copia de seguridad de todos los datos?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copia de seguridad creada exitosamente'),
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _handleRestore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Restaurar Datos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Desea restaurar los datos desde una copia de seguridad? Esta acción sobrescribirá los datos actuales.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos restaurados exitosamente')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _handleClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Limpiar Caché',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          '¿Desea limpiar el caché de la aplicación? Esto liberará espacio de almacenamiento.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiado exitosamente')),
              );
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _handleContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contactar Soporte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email: soporte@cafepos.com',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Teléfono: +34 900 123 456',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 1.h),
            Text(
              'Horario: Lun-Vie 9:00-18:00',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _handleViewDocumentation() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Abriendo documentación...')));
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ayuda', style: Theme.of(context).textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Configuración de Cuenta',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 1.h),
              Text(
                'Gestione su perfil y cierre sesión de forma segura.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Configuración del Negocio',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 1.h),
              Text(
                'Configure información del restaurante, recibos y programa de fidelidad.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 2.h),
              Text(
                'Configuración del Sistema',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 1.h),
              Text(
                'Gestione impresoras, sincronización offline y preferencias de la app.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}