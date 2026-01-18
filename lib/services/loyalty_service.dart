import './supabase_service.dart';

class LoyaltyService {
  final _supabase = SupabaseService.client;

  // Get loyalty rules
  Future<List<Map<String, dynamic>>> getLoyaltyRules() async {
    try {
      final response = await _supabase
          .from('loyalty_rules')
          .select()
          .eq('is_active', true)
          .order('tier', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting loyalty rules: $e');
      return [];
    }
  }

  // Get client points balance
  Future<int> getClientPoints(String clientId) async {
    try {
      final response = await _supabase
          .from('clients')
          .select('loyalty_points')
          .eq('id', clientId)
          .single();

      return response['loyalty_points'] as int? ?? 0;
    } catch (e) {
      print('Error getting client points: $e');
      return 0;
    }
  }

  // Get client points history
  Future<List<Map<String, dynamic>>> getPointsHistory(
    String clientId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('points_transactions')
          .select('*, orders(order_number, total), user_profiles(full_name)')
          .eq('client_id', clientId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting points history: $e');
      return [];
    }
  }

  // Redeem points
  Future<bool> redeemPoints({
    required String clientId,
    required int points,
    String? orderId,
    String? notes,
    String? userId,
  }) async {
    try {
      // Check if client has enough points
      final currentBalance = await getClientPoints(clientId);
      if (currentBalance < points) {
        throw Exception('Puntos insuficientes');
      }

      // Create redemption transaction
      await _supabase.from('points_transactions').insert({
        'client_id': clientId,
        'order_id': orderId,
        'points_change': -points,
        'transaction_type': 'redeemed',
        'balance_before': currentBalance,
        'balance_after': currentBalance - points,
        'notes': notes ?? 'Redención de puntos',
        'user_id': userId,
      });

      // Update client points
      await _supabase
          .from('clients')
          .update({'loyalty_points': currentBalance - points})
          .eq('id', clientId);

      return true;
    } catch (e) {
      print('Error redeeming points: $e');
      return false;
    }
  }

  // Add bonus points
  Future<bool> addBonusPoints({
    required String clientId,
    required int points,
    required String notes,
    String? userId,
  }) async {
    try {
      final currentBalance = await getClientPoints(clientId);

      await _supabase.from('points_transactions').insert({
        'client_id': clientId,
        'points_change': points,
        'transaction_type': 'adjusted',
        'balance_before': currentBalance,
        'balance_after': currentBalance + points,
        'notes': notes,
        'user_id': userId,
      });

      await _supabase
          .from('clients')
          .update({'loyalty_points': currentBalance + points})
          .eq('id', clientId);

      return true;
    } catch (e) {
      print('Error adding bonus points: $e');
      return false;
    }
  }

  // Calculate points for order amount
  Future<int> calculatePointsForAmount(double amount, String tier) async {
    try {
      final rule = await _supabase
          .from('loyalty_rules')
          .select()
          .eq('tier', tier)
          .eq('is_active', true)
          .maybeSingle();

      if (rule == null) {
        return amount.floor(); // Default 1 point per Bs
      }

      final pointsPerBoliviano = rule['points_per_boliviano'] as num? ?? 1.0;
      final multiplier = rule['bonus_multiplier'] as num? ?? 1.0;

      return (amount * pointsPerBoliviano * multiplier).floor();
    } catch (e) {
      print('Error calculating points: $e');
      return amount.floor();
    }
  }

  // Get tier requirements
  Map<String, int> getTierRequirements() {
    return {'bronze': 0, 'silver': 2000, 'gold': 5000, 'platinum': 10000};
  }

  // Get next tier info for client
  Future<Map<String, dynamic>?> getNextTierInfo(String clientId) async {
    try {
      final client = await _supabase
          .from('clients')
          .select('points_earned_lifetime, loyalty_tier')
          .eq('id', clientId)
          .single();

      final currentPoints = client['points_earned_lifetime'] as int? ?? 0;
      final currentTier = client['loyalty_tier'] as String? ?? 'bronze';

      final requirements = getTierRequirements();
      String? nextTier;
      int? pointsNeeded;

      if (currentTier == 'bronze') {
        nextTier = 'silver';
        pointsNeeded = requirements['silver']! - currentPoints;
      } else if (currentTier == 'silver') {
        nextTier = 'gold';
        pointsNeeded = requirements['gold']! - currentPoints;
      } else if (currentTier == 'gold') {
        nextTier = 'platinum';
        pointsNeeded = requirements['platinum']! - currentPoints;
      }

      if (nextTier == null) {
        return null; // Already at max tier
      }

      return {
        'current_tier': currentTier,
        'next_tier': nextTier,
        'current_points': currentPoints,
        'points_needed': pointsNeeded,
        'progress': currentPoints / requirements[nextTier]!,
      };
    } catch (e) {
      print('Error getting next tier info: $e');
      return null;
    }
  }

  // Get top loyalty clients
  Future<List<Map<String, dynamic>>> getTopLoyaltyClients({
    int limit = 10,
  }) async {
    try {
      final response = await _supabase
          .from('clients')
          .select()
          .eq('is_active', true)
          .order('points_earned_lifetime', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting top loyalty clients: $e');
      return [];
    }
  }
}
