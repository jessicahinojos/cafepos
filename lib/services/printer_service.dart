import './supabase_service.dart';

class PrinterService {
  final _supabase = SupabaseService.client;

  // Get default printer
  Future<Map<String, dynamic>?> getDefaultPrinter() async {
    try {
      final response = await _supabase
          .from('printers')
          .select()
          .eq('is_default', true)
          .eq('is_active', true)
          .eq('status', 'online')
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting default printer: $e');
      return null;
    }
  }

  // Get all active printers
  Future<List<Map<String, dynamic>>> getActivePrinters() async {
    try {
      final response = await _supabase
          .from('printers')
          .select()
          .eq('is_active', true)
          .order('is_default', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  // Get receipt template by type
  Future<Map<String, dynamic>?> getReceiptTemplate(String type) async {
    try {
      final response = await _supabase
          .from('receipt_templates')
          .select()
          .eq('type', type)
          .eq('is_default', true)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting receipt template: $e');
      return null;
    }
  }

  // Create print job
  Future<String?> createPrintJob({
    required String orderId,
    required String type,
    String? printerId,
    String? templateId,
    required Map<String, dynamic> printData,
  }) async {
    try {
      // Get default printer if not specified
      if (printerId == null) {
        final defaultPrinter = await getDefaultPrinter();
        printerId = defaultPrinter?['id'];
      }

      // Get default template if not specified
      if (templateId == null) {
        final defaultTemplate = await getReceiptTemplate(type);
        templateId = defaultTemplate?['id'];
      }

      final response = await _supabase
          .from('print_jobs')
          .insert({
            'printer_id': printerId,
            'template_id': templateId,
            'order_id': orderId,
            'type': type,
            'status': 'pending',
            'print_data': printData,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      print('Error creating print job: $e');
      return null;
    }
  }

  // Print receipt for order
  Future<bool> printOrderReceipt(String orderId) async {
    try {
      // Get order details with items
      final orderData = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*),
            clients(*),
            user_profiles(full_name),
            payments(*)
          ''')
          .eq('id', orderId)
          .single();

      final printData = _buildReceiptData(orderData);

      final jobId = await createPrintJob(
        orderId: orderId,
        type: 'sale',
        printData: printData,
      );

      return jobId != null;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  // Print kitchen order
  Future<bool> printKitchenOrder(String orderId) async {
    try {
      final orderData = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      final printData = _buildKitchenOrderData(orderData);

      final jobId = await createPrintJob(
        orderId: orderId,
        type: 'kitchen',
        printData: printData,
      );

      return jobId != null;
    } catch (e) {
      print('Error printing kitchen order: $e');
      return false;
    }
  }

  // Update print job status
  Future<bool> updatePrintJobStatus(
    String jobId,
    String status,
    String? errorMessage,
  ) async {
    try {
      await _supabase
          .from('print_jobs')
          .update({
            'status': status,
            'error_message': errorMessage,
            if (status == 'completed')
              'printed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId);

      return true;
    } catch (e) {
      print('Error updating print job: $e');
      return false;
    }
  }

  // Get pending print jobs
  Future<List<Map<String, dynamic>>> getPendingPrintJobs() async {
    try {
      final response = await _supabase
          .from('print_jobs')
          .select('*, printers(*), receipt_templates(*)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting pending print jobs: $e');
      return [];
    }
  }

  // Build receipt data
  Map<String, dynamic> _buildReceiptData(Map<String, dynamic> order) {
    return {
      'order_number': order['order_number'],
      'table_number': order['table_number'],
      'date': order['created_at'],
      'items': order['order_items'],
      'subtotal': order['subtotal'],
      'tax': order['tax'],
      'discount': order['discount'],
      'total': order['total'],
      'payment': order['payments']?.first,
      'client': order['clients'],
      'cashier': order['user_profiles']?['full_name'],
    };
  }

  // Build kitchen order data
  Map<String, dynamic> _buildKitchenOrderData(Map<String, dynamic> order) {
    return {
      'order_number': order['order_number'],
      'table_number': order['table_number'],
      'time': order['created_at'],
      'items': order['order_items']
          .map(
            (item) => {
              'name': item['product_name'],
              'quantity': item['quantity'],
              'notes': item['notes'],
            },
          )
          .toList(),
    };
  }

  // Update printer status
  Future<bool> updatePrinterStatus(String printerId, String status) async {
    try {
      await _supabase
          .from('printers')
          .update({
            'status': status,
            'last_ping': DateTime.now().toIso8601String(),
          })
          .eq('id', printerId);

      return true;
    } catch (e) {
      print('Error updating printer status: $e');
      return false;
    }
  }
}
