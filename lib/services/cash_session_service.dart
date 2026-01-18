import './supabase_service.dart';

/// Service for managing cash sessions and transactions
class CashSessionService {
  final _client = SupabaseService.client;

  // ============================================================================
  // CASH SESSIONS - Complete CRUD Operations
  // ============================================================================

  /// Get the currently active cash session for the logged-in user
  Future<Map<String, dynamic>?> getActiveCashSession() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('cash_sessions')
          .select('*, user_profiles(full_name)')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al cargar sesión de caja activa: $e');
    }
  }

  /// Get all cash sessions with optional filtering
  Future<List<Map<String, dynamic>>> getCashSessions({
    bool activeOnly = false,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      var query = _client
          .from('cash_sessions')
          .select('*, user_profiles(full_name)');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('opened_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('opened_at', endDate.toIso8601String());
      }

      final response = await query.order('opened_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar sesiones de caja: $e');
    }
  }

  /// Get a single cash session by ID
  Future<Map<String, dynamic>> getCashSessionById(String id) async {
    try {
      final response = await _client
          .from('cash_sessions')
          .select('*, user_profiles(full_name)')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al cargar sesión de caja: $e');
    }
  }

  /// Open a new cash session
  Future<Map<String, dynamic>> openCashSession({
    required double openingAmount,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Check if there's already an active session
      final activeSession = await getActiveCashSession();
      if (activeSession != null) {
        throw Exception('Ya existe una sesión de caja activa');
      }

      final data = {
        'user_id': userId,
        'opening_amount': openingAmount,
        'is_active': true,
        'notes': notes,
      };

      final response = await _client
          .from('cash_sessions')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al abrir sesión de caja: $e');
    }
  }

  /// Close an active cash session
  Future<void> closeCashSession({
    required String sessionId,
    required double closingAmount,
    String? notes,
  }) async {
    try {
      final session = await getCashSessionById(sessionId);

      if (session['is_active'] != true) {
        throw Exception('La sesión de caja ya está cerrada');
      }

      final openingAmount = (session['opening_amount'] as num).toDouble();
      final totalSales = (session['total_sales'] as num?)?.toDouble() ?? 0;
      final totalCash = (session['total_cash'] as num?)?.toDouble() ?? 0;
      final totalCard = (session['total_card'] as num?)?.toDouble() ?? 0;
      final totalQr = (session['total_qr'] as num?)?.toDouble() ?? 0;

      final expectedAmount = openingAmount + totalCash;
      final difference = closingAmount - expectedAmount;

      final updates = {
        'closing_amount': closingAmount,
        'expected_amount': expectedAmount,
        'difference': difference,
        'closed_at': DateTime.now().toIso8601String(),
        'is_active': false,
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _client.from('cash_sessions').update(updates).eq('id', sessionId);
    } catch (e) {
      throw Exception('Error al cerrar sesión de caja: $e');
    }
  }

  /// Get detailed session summary with transactions
  Future<Map<String, dynamic>> getCashSessionSummary(String sessionId) async {
    try {
      final session = await getCashSessionById(sessionId);

      final transactions = await _client
          .from('cash_transactions')
          .select('*, user_profiles(full_name)')
          .eq('cash_session_id', sessionId)
          .order('created_at', ascending: true);

      final payments = await _client
          .from('payments')
          .select('*, orders(order_number)')
          .eq('cash_session_id', sessionId)
          .order('created_at', ascending: true);

      return {...session, 'transactions': transactions, 'payments': payments};
    } catch (e) {
      throw Exception('Error al cargar resumen de sesión: $e');
    }
  }

  // ============================================================================
  // CASH TRANSACTIONS - Complete CRUD Operations
  // ============================================================================

  /// Get transactions for a specific cash session
  Future<List<Map<String, dynamic>>> getTransactionsBySession(
    String sessionId,
  ) async {
    try {
      final response = await _client
          .from('cash_transactions')
          .select('*, user_profiles(full_name)')
          .eq('cash_session_id', sessionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al cargar transacciones: $e');
    }
  }

  /// Create a new cash transaction
  Future<Map<String, dynamic>> createTransaction({
    required String cashSessionId,
    required String type,
    required double amount,
    String? reason,
    String? notes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final data = {
        'cash_session_id': cashSessionId,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'reason': reason,
        'notes': notes,
      };

      final response = await _client
          .from('cash_transactions')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error al crear transacción: $e');
    }
  }

  /// Get transaction statistics for a session
  Future<Map<String, dynamic>> getTransactionStatistics(
    String sessionId,
  ) async {
    try {
      final transactions = await getTransactionsBySession(sessionId);

      final deposits = transactions
          .where((t) => t['type'] == 'deposit')
          .toList();
      final withdrawals = transactions
          .where((t) => t['type'] == 'withdrawal')
          .toList();

      final totalDeposits = deposits.fold<double>(
        0,
        (sum, t) => sum + ((t['amount'] as num).toDouble()),
      );

      final totalWithdrawals = withdrawals.fold<double>(
        0,
        (sum, t) => sum + ((t['amount'] as num).toDouble()),
      );

      return {
        'total_transactions': transactions.length,
        'deposits_count': deposits.length,
        'withdrawals_count': withdrawals.length,
        'total_deposits': totalDeposits,
        'total_withdrawals': totalWithdrawals,
        'net_amount': totalDeposits - totalWithdrawals,
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas de transacciones: $e');
    }
  }

  // ============================================================================
  // CASH SESSION ANALYTICS
  // ============================================================================

  /// Get session performance comparison
  Future<List<Map<String, dynamic>>> getSessionPerformance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessions = await getCashSessions(
        startDate: startDate,
        endDate: endDate,
      );

      final performanceData = sessions.map((session) {
        final openingAmount =
            (session['opening_amount'] as num?)?.toDouble() ?? 0;
        final closingAmount =
            (session['closing_amount'] as num?)?.toDouble() ?? 0;
        final totalSales = (session['total_sales'] as num?)?.toDouble() ?? 0;
        final difference = (session['difference'] as num?)?.toDouble() ?? 0;

        return {
          'session_id': session['id'],
          'user_name': session['user_profiles']?['full_name'] ?? 'Desconocido',
          'opened_at': session['opened_at'],
          'closed_at': session['closed_at'],
          'opening_amount': openingAmount,
          'closing_amount': closingAmount,
          'total_sales': totalSales,
          'difference': difference,
          'duration': session['closed_at'] != null
              ? DateTime.parse(
                  session['closed_at'],
                ).difference(DateTime.parse(session['opened_at'])).inMinutes
              : null,
        };
      }).toList();

      return performanceData;
    } catch (e) {
      throw Exception('Error al cargar rendimiento de sesiones: $e');
    }
  }

  /// Get average session metrics
  Future<Map<String, dynamic>> getAverageSessionMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final sessions = await getCashSessions(
        startDate: startDate,
        endDate: endDate,
      );

      final closedSessions = sessions.where((s) => !s['is_active']).toList();

      if (closedSessions.isEmpty) {
        return {
          'average_sales': 0,
          'average_difference': 0,
          'average_duration_minutes': 0,
          'total_sessions': 0,
        };
      }

      final totalSales = closedSessions.fold<double>(
        0,
        (sum, s) => sum + ((s['total_sales'] as num?)?.toDouble() ?? 0),
      );

      final totalDifferences = closedSessions.fold<double>(
        0,
        (sum, s) => sum + ((s['difference'] as num?)?.toDouble() ?? 0).abs(),
      );

      final totalDuration = closedSessions.fold<int>(0, (sum, s) {
        if (s['closed_at'] != null) {
          return sum +
              DateTime.parse(
                s['closed_at'],
              ).difference(DateTime.parse(s['opened_at'])).inMinutes;
        }
        return sum;
      });

      return {
        'average_sales': totalSales / closedSessions.length,
        'average_difference': totalDifferences / closedSessions.length,
        'average_duration_minutes': totalDuration / closedSessions.length,
        'total_sessions': closedSessions.length,
      };
    } catch (e) {
      throw Exception('Error al calcular métricas promedio: $e');
    }
  }

  /// Get discrepancy report (sessions with differences)
  Future<List<Map<String, dynamic>>> getDiscrepancyReport({
    required DateTime startDate,
    required DateTime endDate,
    double threshold = 5.0,
  }) async {
    try {
      final sessions = await getCashSessions(
        startDate: startDate,
        endDate: endDate,
      );

      final discrepancies = sessions
          .where((session) {
            final difference = (session['difference'] as num?)?.toDouble() ?? 0;
            return difference.abs() >= threshold;
          })
          .map((session) {
            return {
              'session_id': session['id'],
              'user_name':
                  session['user_profiles']?['full_name'] ?? 'Desconocido',
              'opened_at': session['opened_at'],
              'closed_at': session['closed_at'],
              'expected_amount': session['expected_amount'],
              'closing_amount': session['closing_amount'],
              'difference': session['difference'],
              'notes': session['notes'],
            };
          })
          .toList();

      return discrepancies;
    } catch (e) {
      throw Exception('Error al generar reporte de discrepancias: $e');
    }
  }
}
