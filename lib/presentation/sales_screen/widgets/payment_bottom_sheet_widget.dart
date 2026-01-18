import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PaymentBottomSheetWidget extends StatefulWidget {
  final double total;
  final String orderType;
  final List<Map<String, dynamic>> cartItems;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
  onPaymentComplete;

  const PaymentBottomSheetWidget({
    super.key,
    required this.total,
    required this.orderType,
    required this.cartItems,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentBottomSheetWidget> createState() =>
      _PaymentBottomSheetWidgetState();
}

class _PaymentBottomSheetWidgetState extends State<PaymentBottomSheetWidget> {
  String _selectedPaymentMethod = '';
  final TextEditingController _cashController = TextEditingController();
  double _receivedAmount = 0.0;
  double _changeAmount = 0.0;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    setState(() {
      _receivedAmount = double.tryParse(_cashController.text) ?? 0.0;
      _changeAmount = _receivedAmount - widget.total;
    });
  }

  void _processPayment() async {
    HapticFeedback.mediumImpact();

    final paymentData = {
      'method': _selectedPaymentMethod,
      'amount': _receivedAmount > 0 ? _receivedAmount : widget.total,
      'referenceNumber': _selectedPaymentMethod == 'card'
          ? 'REF${DateTime.now().millisecondsSinceEpoch}'
          : null,
      'paymentMethod': _selectedPaymentMethod,
    };

    try {
      final result = await widget.onPaymentComplete(paymentData);
      if (mounted) {
        Navigator.of(context).pop(paymentData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al procesar pago: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Método de Pago',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Total: Bs ${widget.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  _buildPaymentOption(
                    context,
                    'Efectivo',
                    'payment',
                    'cash',
                  ),
                  SizedBox(height: 2.h),
                  _buildPaymentOption(
                    context,
                    'Tarjeta',
                    'credit_card',
                    'card',
                  ),
                  SizedBox(height: 2.h),
                  _buildPaymentOption(context, 'Código QR', 'qr_code', 'qr'),
                ],
              ),
            ),
            _selectedPaymentMethod == 'cash'
                ? _buildCashCalculator(context)
                : _selectedPaymentMethod == 'card'
                ? _buildCardProcessing(context)
                : _selectedPaymentMethod == 'qr'
                ? _buildQRScanner(context)
                : Container(),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    String label,
    String iconName,
    String method,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.brightness == Brightness.light
              ? const Color(0xFFF8FAFC)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.brightness == Brightness.light
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashCalculator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateChange(),
            decoration: InputDecoration(
              labelText: 'Monto Recibido',
              prefixText: 'Bs ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:', style: theme.textTheme.titleMedium),
              Text(
                'Bs ${widget.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recibido:', style: theme.textTheme.titleMedium),
              Text(
                'Bs ${_receivedAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _changeAmount >= 0
                  ? (theme.brightness == Brightness.light
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1))
                  : (theme.brightness == Brightness.light
                        ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cambio:',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Bs ${_changeAmount.abs().toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _changeAmount >= 0
                        ? (theme.brightness == Brightness.light
                              ? const Color(0xFF059669)
                              : const Color(0xFF10B981))
                        : (theme.brightness == Brightness.light
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFEF4444)),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _receivedAmount >= widget.total ? _processPayment : null,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmar Pago',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardProcessing(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'credit_card',
            color: theme.colorScheme.primary,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Procesando Tarjeta',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Esperando confirmación del terminal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmar Pago',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/WhatsApp_Image_2026-01-12_at_08.40.56-1768226758920.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Escanear Código QR',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Cliente debe escanear el código para pagar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmar Pago',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
