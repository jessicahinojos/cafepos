import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CustomerDetailSheet extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onAddPoints;
  final VoidCallback onNewOrder;
  final VoidCallback onEdit;

  const CustomerDetailSheet({
    super.key,
    required this.customer,
    required this.onAddPoints,
    required this.onNewOrder,
    required this.onEdit,
  });

  @override
  State<CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<CustomerDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '€${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 1.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomImageWidget(
                            imageUrl: widget.customer["avatar"] as String,
                            width: 20.w,
                            height: 20.w,
                            fit: BoxFit.cover,
                            semanticLabel:
                                widget.customer["semanticLabel"] as String,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.customer["name"] as String,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'phone',
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                    size: 16,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    widget.customer["phone"] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.brightness == Brightness.light
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.customer["email"] != null) ...[
                                SizedBox(height: 0.5.h),
                                Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'email',
                                      color:
                                          theme.brightness == Brightness.light
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                      size: 16,
                                    ),
                                    SizedBox(width: 1.w),
                                    Expanded(
                                      child: Text(
                                        widget.customer["email"] as String,
                                        style: theme.textTheme.bodyMedium
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
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                CustomIconWidget(
                                  iconName: 'stars',
                                  color: theme.colorScheme.primary,
                                  size: 32,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  '${widget.customer["points"]}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  'Puntos',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(3.w),
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
                              children: [
                                CustomIconWidget(
                                  iconName: 'shopping_bag',
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  size: 32,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  '${widget.customer["totalOrders"]}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Pedidos',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(3.w),
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
                              children: [
                                CustomIconWidget(
                                  iconName: 'euro',
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  size: 32,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  _formatCurrency(
                                    widget.customer["totalSpent"] as double,
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onAddPoints();
                            },
                            icon: CustomIconWidget(
                              iconName: 'add_circle_outline',
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text('Añadir Puntos'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onNewOrder();
                            },
                            icon: CustomIconWidget(
                              iconName: 'shopping_cart',
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            label: const Text('Nuevo Pedido'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Historial de Compras'),
                  Tab(text: 'Movimientos de Puntos'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.brightness == Brightness.light
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
                indicatorColor: theme.colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPurchaseHistory(scrollController, theme),
                    _buildPointsHistory(scrollController, theme),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchaseHistory(
    ScrollController scrollController,
    ThemeData theme,
  ) {
    final purchaseHistory = widget.customer["purchaseHistory"] as List<dynamic>;

    return purchaseHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'receipt_long',
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  size: 64,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Sin historial de compras',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.all(4.w),
            itemCount: purchaseHistory.length,
            itemBuilder: (context, index) {
              final order = purchaseHistory[index] as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order["orderId"] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatCurrency(order["amount"] as double),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'calendar_today',
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatDate(order["date"] as DateTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          CustomIconWidget(
                            iconName: 'shopping_bag',
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${order["items"]} artículos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.brightness == Brightness.light
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.light
                              ? const Color(0xFF059669)
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomIconWidget(
                              iconName: 'stars',
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '+${order["pointsEarned"]} puntos ganados',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildPointsHistory(
    ScrollController scrollController,
    ThemeData theme,
  ) {
    final pointsHistory = widget.customer["pointsHistory"] as List<dynamic>;

    return pointsHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'stars',
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  size: 64,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Sin movimientos de puntos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.brightness == Brightness.light
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.all(4.w),
            itemCount: pointsHistory.length,
            itemBuilder: (context, index) {
              final transaction = pointsHistory[index] as Map<String, dynamic>;
              final isEarned = transaction["type"] == "earned";
              final points = transaction["points"] as int;

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? (theme.brightness == Brightness.light
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF10B981))
                                    .withValues(alpha: 0.12)
                              : (theme.brightness == Brightness.light
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: isEarned ? 'add_circle' : 'remove_circle',
                          color: isEarned
                              ? (theme.brightness == Brightness.light
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF10B981))
                              : (theme.brightness == Brightness.light
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFEF4444)),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction["description"] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              _formatDate(transaction["date"] as DateTime),
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
                        '${isEarned ? '+' : ''}$points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isEarned
                              ? (theme.brightness == Brightness.light
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF10B981))
                              : (theme.brightness == Brightness.light
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
