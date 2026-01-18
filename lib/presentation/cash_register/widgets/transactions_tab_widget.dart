import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TransactionsTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isSessionActive;

  const TransactionsTabWidget({
    super.key,
    required this.transactions,
    required this.isSessionActive,
  });

  String _formatCurrency(double amount) {
    return 'Bs ${amount.abs().toStringAsFixed(2)}';
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (transactionDate == today) {
      return 'Hoy';
    } else if (transactionDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  Color _getPaymentMethodColor(String method, bool isLight) {
    switch (method) {
      case 'cash':
        return isLight ? const Color(0xFF059669) : const Color(0xFF10B981);
      case 'card':
        return isLight ? const Color(0xFF2563EB) : const Color(0xFF3B82F6);
      case 'qr':
        return isLight ? const Color(0xFFD97706) : const Color(0xFFF59E0B);
      default:
        return isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'qr':
        return 'QR';
      default:
        return method;
    }
  }

  String _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return 'payments';
      case 'card':
        return 'credit_card';
      case 'qr':
        return 'qr_code_scanner';
      default:
        return 'payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isSessionActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'receipt_long',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay transacciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abre la caja para ver las transacciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'receipt_long',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin transacciones aún',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Las transacciones aparecerán aquí',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (final transaction in transactions) {
      final date = _formatDate(transaction["timestamp"] as DateTime);
      groupedTransactions.putIfAbsent(date, () => []);
      groupedTransactions[date]!.add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final date = groupedTransactions.keys.elementAt(index);
        final dateTransactions = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                date,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
            ...dateTransactions.map((transaction) {
              final type = transaction["type"] as String;
              final amount = transaction["amount"] as double;
              final paymentMethod = transaction["paymentMethod"] as String;
              final orderNumber = transaction["orderNumber"] as String?;
              final category = transaction["category"] as String;
              final note = transaction["note"] as String;
              final timestamp = transaction["timestamp"] as DateTime;

              final isPositive = amount > 0;
              final amountColor = isPositive
                  ? (theme.brightness == Brightness.light
                        ? const Color(0xFF059669)
                        : const Color(0xFF10B981))
                  : (theme.brightness == Brightness.light
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFEF4444));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showTransactionDetails(context, transaction),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getPaymentMethodColor(
                                    paymentMethod,
                                    theme.brightness == Brightness.light,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: CustomIconWidget(
                                    iconName: _getPaymentMethodIcon(
                                      paymentMethod,
                                    ),
                                    color: _getPaymentMethodColor(
                                      paymentMethod,
                                      theme.brightness == Brightness.light,
                                    ),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          category,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if (orderNumber != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              orderNumber,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      note,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color:
                                                theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(amount),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: amountColor,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(timestamp),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.brightness == Brightness.light
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPaymentMethodColor(
                                    paymentMethod,
                                    theme.brightness == Brightness.light,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomIconWidget(
                                      iconName: _getPaymentMethodIcon(
                                        paymentMethod,
                                      ),
                                      color: _getPaymentMethodColor(
                                        paymentMethod,
                                        theme.brightness == Brightness.light,
                                      ),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getPaymentMethodLabel(paymentMethod),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: _getPaymentMethodColor(
                                              paymentMethod,
                                              theme.brightness ==
                                                  Brightness.light,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
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
            }),
          ],
        );
      },
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final theme = Theme.of(context);
    final type = transaction["type"] as String;
    final amount = transaction["amount"] as double;
    final paymentMethod = transaction["paymentMethod"] as String;
    final orderNumber = transaction["orderNumber"] as String?;
    final category = transaction["category"] as String;
    final note = transaction["note"] as String;
    final timestamp = transaction["timestamp"] as DateTime;
    final id = transaction["id"] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Detalles de Transacción',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              context: context,
              label: 'ID de Transacción',
              value: id,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context: context,
              label: 'Categoría',
              value: category,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context: context,
              label: 'Monto',
              value: _formatCurrency(amount),
              valueColor: amount > 0
                  ? (theme.brightness == Brightness.light
                        ? const Color(0xFF059669)
                        : const Color(0xFF10B981))
                  : (theme.brightness == Brightness.light
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context: context,
              label: 'Método de Pago',
              value: _getPaymentMethodLabel(paymentMethod),
            ),
            if (orderNumber != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                context: context,
                label: 'Número de Orden',
                value: orderNumber,
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(
              context: context,
              label: 'Fecha y Hora',
              value: '${_formatDate(timestamp)} ${_formatTime(timestamp)}',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context: context, label: 'Nota', value: note),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.light
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
