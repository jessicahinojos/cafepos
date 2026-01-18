import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CloseRegisterDialog extends StatefulWidget {
  final double expectedCash;
  final Function(double, double) onConfirm;

  const CloseRegisterDialog({
    super.key,
    required this.expectedCash,
    required this.onConfirm,
  });

  @override
  State<CloseRegisterDialog> createState() => _CloseRegisterDialogState();
}

class _CloseRegisterDialogState extends State<CloseRegisterDialog> {
  final TextEditingController _actualCashController = TextEditingController();
  final Map<double, int> _denominations = {
    100.0: 0,
    50.0: 0,
    20.0: 0,
    10.0: 0,
    5.0: 0,
    1.0: 0,
    0.50: 0,
    0.25: 0,
  };

  double get _totalAmount {
    double total = 0;
    _denominations.forEach((denomination, count) {
      total += denomination * count;
    });
    return total;
  }

  double get _variance {
    final actualCash = double.tryParse(_actualCashController.text) ?? 0;
    return actualCash - widget.expectedCash;
  }

  void _updateAmount() {
    setState(() {
      _actualCashController.text = _totalAmount.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variance = _variance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          (theme.brightness == Brightness.light
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'lock',
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cerrar Caja',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Efectivo Esperado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs ${widget.expectedCash.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    CustomIconWidget(
                      iconName: 'account_balance_wallet',
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cuenta el efectivo en caja',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _actualCashController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Efectivo Real',
                  prefixText: '\$ ',
                  suffixIcon: IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _actualCashController.clear();
                      setState(() {
                        _denominations.updateAll((key, value) => 0);
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: 'clear',
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calculate',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculadora de Denominaciones',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._denominations.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Bs ${entry.key.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      if (entry.value > 0) {
                                        setState(() {
                                          _denominations[entry.key] =
                                              entry.value - 1;
                                          _updateAmount();
                                        });
                                      }
                                    },
                                    icon: CustomIconWidget(
                                      iconName: 'remove_circle_outline',
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _denominations[entry.key] =
                                            entry.value + 1;
                                        _updateAmount();
                                      });
                                    },
                                    icon: CustomIconWidget(
                                      iconName: 'add_circle_outline',
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Bs ${(entry.key * entry.value).toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '\$${_totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_actualCashController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: variance.abs() > 0.01
                        ? (variance > 0
                                  ? (theme.brightness == Brightness.light
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF10B981))
                                  : (theme.brightness == Brightness.light
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFEF4444)))
                              .withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: variance.abs() > 0.01
                            ? (variance > 0 ? 'trending_up' : 'trending_down')
                            : 'check_circle',
                        color: variance.abs() > 0.01
                            ? (variance > 0
                                  ? (theme.brightness == Brightness.light
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF10B981))
                                  : (theme.brightness == Brightness.light
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFEF4444)))
                            : theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variance.abs() > 0.01
                                  ? (variance > 0 ? 'Sobrante' : 'Faltante')
                                  : 'Cuadrado',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: variance.abs() > 0.01
                                    ? (variance > 0
                                          ? (theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF10B981))
                                          : (theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFFEF4444)))
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              variance.abs() > 0.01
                                  ? '\$${variance.abs().toStringAsFixed(2)}'
                                  : 'El efectivo coincide',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: variance.abs() > 0.01
                                    ? (variance > 0
                                          ? (theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFF059669)
                                                : const Color(0xFF10B981))
                                          : (theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFFEF4444)))
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final actualCash = double.tryParse(
                          _actualCashController.text,
                        );
                        if (actualCash != null && actualCash >= 0) {
                          widget.onConfirm(actualCash, variance);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor ingresa un monto válido',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.light
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFEF4444),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
