import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/cash_session_service.dart';
import './widgets/add_transaction_dialog_widget.dart';
import './widgets/close_register_dialog_widget.dart';
import './widgets/open_register_dialog_widget.dart';
import './widgets/session_tab_widget.dart';
import './widgets/summary_tab_widget.dart';
import './widgets/transactions_tab_widget.dart';

class CashRegister extends StatefulWidget {
  const CashRegister({super.key});

  @override
  State<CashRegister> createState() => _CashRegisterState();
}

class _CashRegisterState extends State<CashRegister>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CashSessionService _cashSessionService = CashSessionService();
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  String? _sessionId;
  double _initialCash = 0.0;
  double _currentCashTotal = 0.0;
  double _currentCardTotal = 0.0;
  double _currentQRTotal = 0.0;
  final List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionData() async {
    try {
      final session = await _cashSessionService.getActiveCashSession();
      if (session == null) {
        if (!mounted) return;
        setState(() {
          _isSessionActive = false;
          _sessionStartTime = null;
          _sessionId = null;
          _initialCash = 0.0;
          _currentCashTotal = 0.0;
          _currentCardTotal = 0.0;
          _currentQRTotal = 0.0;
          _transactions.clear();
        });
        return;
      }

      final sessionId = session['id'] as String;
      final summary = await _cashSessionService.getCashSessionSummary(
        sessionId,
      );
      final payments = List<Map<String, dynamic>>.from(
        summary['payments'] as List<dynamic>? ?? [],
      );
      final cashTransactions = List<Map<String, dynamic>>.from(
        summary['transactions'] as List<dynamic>? ?? [],
       );
      double cashTotal = 0;
      double cardTotal = 0;
      double qrTotal = 0;
      final transactions = <Map<String, dynamic>>[];

      for (final payment in payments) {
        final method = payment['method'] as String? ?? 'cash';
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        switch (method) {
          case 'cash':
            cashTotal += amount;
            break;
          case 'card':
            cardTotal += amount;
            break;
          case 'qr':
            qrTotal += amount;
            break;
        }

        final createdAt = DateTime.tryParse(
          payment['created_at'] as String? ?? '',
        );
        final orderNumber = (payment['orders'] as Map<String, dynamic>?)?[
            'order_number'] as String?;

        transactions.add({
          'id': payment['id'] ?? '${payment['created_at']}_payment',
          'timestamp': createdAt ?? DateTime.now(),
          'type': 'sale',
          'amount': amount,
          'paymentMethod': method,
          'orderNumber': orderNumber,
          'category': 'Venta',
          'note': payment['notes'] as String? ?? '',
        });
      }

      for (final transaction in cashTransactions) {
        final type = transaction['type'] as String? ?? 'deposit';
        final amountValue = (transaction['amount'] as num?)?.toDouble() ?? 0;
        final isWithdrawal = type == 'withdrawal' || type == 'closing';
        final mappedAmount = isWithdrawal ? -amountValue : amountValue;
        final createdAt = DateTime.tryParse(
          transaction['created_at'] as String? ?? '',
        );

        transactions.add({
          'id': transaction['id'] ?? '${transaction['created_at']}_cash_txn',
          'timestamp': createdAt ?? DateTime.now(),
          'type': isWithdrawal ? 'expense' : 'income',
          'amount': mappedAmount,
          'paymentMethod': 'cash',
          'orderNumber': null,
          'category': _mapCashTransactionCategory(type),
          'note': transaction['reason'] as String? ??
              transaction['notes'] as String? ??
              '',
        });
      }

      transactions.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _isSessionActive = true;
        _sessionId = sessionId;
        _sessionStartTime = DateTime.tryParse(
          session['opened_at'] as String? ?? '',
        );
        _initialCash = (session['opening_amount'] as num?)?.toDouble() ?? 0.0;
        _currentCashTotal = cashTotal;
        _currentCardTotal = cardTotal;
        _currentQRTotal = qrTotal;
        _transactions
          ..clear()
          ..addAll(transactions);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar caja: $e')));
    }
  }

  String _mapCashTransactionCategory(String type) {
    switch (type) {
      case 'opening':
        return 'Apertura';
      case 'closing':
        return 'Cierre';
      case 'withdrawal':
        return 'Retiro';
      case 'deposit':
        return 'Ingreso';
      default:
        return 'Movimiento';
    }
  }
     
  void _openRegister() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => OpenRegisterDialog(
        onConfirm: (initialAmount) async {
          try {
            await _cashSessionService.openCashSession(
              openingAmount: initialAmount,
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            await _loadSessionData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al abrir caja: $e')),
            );
          } 
        },
      ),
    );
  }

  void _closeRegister() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => CloseRegisterDialog(
      expectedCash: _initialCash + _currentCashTotal,
        onConfirm: (actualCash, variance) async {
          try {
            final sessionId = _sessionId;
            if (sessionId == null) {
              throw Exception('No hay sesión de caja activa');
            }
            await _cashSessionService.closeCashSession(
              sessionId: sessionId,
              closingAmount: actualCash,
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            _showCloseConfirmation(variance);
            await _loadSessionData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cerrar caja: $e')),
          );
          }
        },
      ),
    );
  }

  void _showCloseConfirmation(double variance) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Caja Cerrada',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'El turno ha sido cerrado exitosamente.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (variance.abs() > 0.01)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: variance > 0
                    ? theme.brightness == Brightness.light
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1)
                    : theme.brightness == Brightness.light
                        ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: variance > 0 ? 'trending_up' : 'trending_down',
                    color: variance > 0
                        ? theme.brightness == Brightness.light
                            ? const Color(0xFF059669)
                            : const Color(0xFF10B981)
                        : theme.brightness == Brightness.light
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Variación: Bs ${variance.abs().toStringAsFixed(2)} ${variance > 0 ? "sobrante" : "faltante"}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: variance > 0
                            ? theme.brightness == Brightness.light
                                ? const Color(0xFF059669)
                                : const Color(0xFF10B981)
                            : theme.brightness == Brightness.light
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
     ),
      ],
    ),
  );
}

  void _addTransaction() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        onConfirm: (type, amount, paymentMethod, category, note) async {
          try {
            final sessionId = _sessionId;
            if (sessionId == null) {
              throw Exception('No hay sesión de caja activa');
            }
            final transactionType =
                type == 'expense' ? 'withdrawal' : 'deposit';
            await _cashSessionService.createTransaction(
              cashSessionId: sessionId,
              type: transactionType,
              amount: amount,
              reason: category,
              notes: note.isNotEmpty ? note : null,
            );
            if (!mounted) return;
            Navigator.of(context).pop();
            await _loadSessionData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al registrar transacción: $e')),
          );
          }
        },
      ),
    );
  }

  String _getSessionDuration() {
    if (_sessionStartTime == null) return "00:00:00";
    final duration = DateTime.now().difference(_sessionStartTime!);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: theme.colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'app_registration',
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caja Registradora',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isSessionActive)
                              Text(
                                'Turno activo: ${_getSessionDuration()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_isSessionActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFF059669).withValues(alpha: 0.1)
                                : const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Activo',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.brightness == Brightness.light
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: const [
                      Tab(text: 'Sesión'),
                      Tab(text: 'Transacciones'),
                      Tab(text: 'Resumen'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              SessionTabWidget(
                isSessionActive: _isSessionActive,
                sessionStartTime: _sessionStartTime,
                initialCash: _initialCash,
                currentCashTotal: _currentCashTotal,
                currentCardTotal: _currentCardTotal,
                currentQRTotal: _currentQRTotal,
                onOpenRegister: _openRegister,
                onCloseRegister: _closeRegister,
              ),
              TransactionsTabWidget(
                transactions: _transactions,
                isSessionActive: _isSessionActive,
              ),
              SummaryTabWidget(
                isSessionActive: _isSessionActive,
                sessionStartTime: _sessionStartTime,
                initialCash: _initialCash,
                currentCashTotal: _currentCashTotal,
                currentCardTotal: _currentCardTotal,
                currentQRTotal: _currentQRTotal,
                transactions: _transactions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
