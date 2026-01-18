import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SummaryTabWidget extends StatelessWidget {
  final bool isSessionActive;
  final DateTime? sessionStartTime;
  final double initialCash;
  final double currentCashTotal;
  final double currentCardTotal;
  final double currentQRTotal;
  final List<Map<String, dynamic>> transactions;

  const SummaryTabWidget({
    super.key,
    required this.isSessionActive,
    required this.sessionStartTime,
    required this.initialCash,
    required this.currentCashTotal,
    required this.currentCardTotal,
    required this.currentQRTotal,
    required this.transactions,
  });

  String _formatCurrency(double amount) {
    return 'Bs ${amount.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '--/--/---- --:--';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  Map<String, dynamic> _calculateSummary() {
    double totalSales = 0;
    double totalIncome = 0;
    double totalExpenses = 0;
    int salesCount = 0;
    int incomeCount = 0;
    int expenseCount = 0;

    for (final transaction in transactions) {
      final type = transaction["type"] as String;
      final amount = (transaction["amount"] as double).abs();

      if (type == "sale") {
        totalSales += amount;
        salesCount++;
      } else if (type == "income") {
        totalIncome += amount;
        incomeCount++;
      } else if (type == "expense") {
        totalExpenses += amount;
        expenseCount++;
      }
    }

    final totalAmount = currentCashTotal + currentCardTotal + currentQRTotal;
    final netAmount = totalAmount - initialCash;

    return {
      "totalSales": totalSales,
      "totalIncome": totalIncome,
      "totalExpenses": totalExpenses,
      "salesCount": salesCount,
      "incomeCount": incomeCount,
      "expenseCount": expenseCount,
      "totalAmount": totalAmount,
      "netAmount": netAmount,
    };
  }

  Future<void> _exportPDF(BuildContext context) async {
    HapticFeedback.lightImpact();

    final summary = _calculateSummary();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumen de Caja',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Fecha: ${_formatDateTime(sessionStartTime)}'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Totales por Método de Pago',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Efectivo:'),
                  pw.Text(_formatCurrency(currentCashTotal)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tarjeta:'),
                  pw.Text(_formatCurrency(currentCardTotal)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Código QR:'),
                  pw.Text(_formatCurrency(currentQRTotal)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Resumen de Transacciones',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ventas (${summary["salesCount"]}):'),
                  pw.Text(_formatCurrency(summary["totalSales"])),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Ingresos (${summary["incomeCount"]}):'),
                  pw.Text(_formatCurrency(summary["totalIncome"])),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gastos (${summary["expenseCount"]}):'),
                  pw.Text(_formatCurrency(summary["totalExpenses"])),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(summary["totalAmount"]),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
                iconName: 'summarize',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay resumen disponible',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Abre la caja para ver el resumen',
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

    final summary = _calculateSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
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
                      iconName: 'calendar_today',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Información del Turno',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context: context,
                  label: 'Inicio',
                  value: _formatDateTime(sessionStartTime),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context: context,
                  label: 'Efectivo Inicial',
                  value: _formatCurrency(initialCash),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Totales por Método de Pago',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentSummaryCard(
            context: context,
            icon: 'payments',
            label: 'Efectivo',
            amount: currentCashTotal,
            color: theme.brightness == Brightness.light
                ? const Color(0xFF059669)
                : const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildPaymentSummaryCard(
            context: context,
            icon: 'credit_card',
            label: 'Tarjeta',
            amount: currentCardTotal,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _buildPaymentSummaryCard(
            context: context,
            icon: 'qr_code_scanner',
            label: 'Código QR',
            amount: currentQRTotal,
            color: theme.brightness == Brightness.light
                ? const Color(0xFFD97706)
                : const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          Text(
            'Resumen de Transacciones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  context: context,
                  label: 'Ventas',
                  count: summary["salesCount"],
                  amount: summary["totalSales"],
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF059669)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context: context,
                  label: 'Ingresos',
                  count: summary["incomeCount"],
                  amount: summary["totalIncome"],
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context: context,
                  label: 'Gastos',
                  count: summary["expenseCount"],
                  amount: summary["totalExpenses"],
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total en Caja',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatCurrency(summary["totalAmount"]),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ganancia Neta',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(summary["netAmount"]),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _exportPDF(context),
              icon: CustomIconWidget(
                iconName: 'picture_as_pdf',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              label: const Text('Exportar PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light
                ? const Color(0xFF64748B)
                : const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard({
    required BuildContext context,
    required String icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF334155),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(iconName: icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            _formatCurrency(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required int count,
    required double amount,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                '$count transacciones',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
