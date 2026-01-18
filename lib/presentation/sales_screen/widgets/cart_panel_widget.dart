import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CartPanelWidget extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double cartTotal;
  final int cartItemCount;
  final String orderType;
  final List<String> orderTypes;
  final Function(String) onOrderTypeChanged;
  final Function(int, int) onUpdateQuantity;
  final Function(int) onRemoveItem;
  final Function(int, String) onUpdateNote;
  final Function(int, double) onUpdateDiscount;
  final VoidCallback onCheckout;

  const CartPanelWidget({
    super.key,
    required this.cartItems,
    required this.cartTotal,
    required this.cartItemCount,
    required this.orderType,
    required this.orderTypes,
    required this.onOrderTypeChanged,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    required this.onUpdateNote,
    required this.onUpdateDiscount,
    required this.onCheckout,
  });

  @override
  State<CartPanelWidget> createState() => _CartPanelWidgetState();
}

class _CartPanelWidgetState extends State<CartPanelWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -5) {
          setState(() => _isExpanded = true);
        } else if (details.primaryDelta! > 5) {
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? 60.h : 18.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
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
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'shopping_cart',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Carrito (${widget.cartItemCount})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Bs ${widget.cartTotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Checkout button - always visible
            if (widget.cartItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                child: ElevatedButton(
                  onPressed: widget.onCheckout,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, _isExpanded ? 6.h : 5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'payment',
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Procesar Pago',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Bs ${widget.cartTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            widget.cartItems.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'shopping_cart_outlined',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: _isExpanded ? 64 : 40,
                          ),
                           SizedBox(height: _isExpanded ? 2.h : 1.h),
                          Text(
                            'Carrito vacío',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: _isExpanded
                                  ? theme.textTheme.titleMedium?.fontSize
                                  : (theme.textTheme.titleMedium?.fontSize ??
                                        14) *
                                      0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        height: 6.h,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.orderTypes.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(width: 2.w),
                          itemBuilder: (context, index) {
                            final type = widget.orderTypes[index];
                            final isSelected = widget.orderType == type;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.onOrderTypeChanged(type);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.brightness == Brightness.light
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.brightness == Brightness.light
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 1.h),
                      if (_isExpanded)
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: widget.cartItems.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 1.h),
                            itemBuilder: (context, index) {
                              final item = widget.cartItems[index];
                              return Dismissible(
                                key: Key(item["id"].toString()),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => widget.onRemoveItem(index),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 4.w),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'delete',
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.light
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item["name"] as String,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            SizedBox(height: 0.5.h),
                                            Text(
                                              'Bs ${(item["price"] as double).toStringAsFixed(2)}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            if ((item["note"] as String)
                                                .isNotEmpty) ...[
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                'Nota: ${item["note"]}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                            if ((item["discount"] as double) >
                                                0) ...[
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                'Descuento: -Bs ${(item["discount"] as double).toStringAsFixed(2)}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          theme.brightness ==
                                                              Brightness.light
                                                          ? const Color(
                                                              0xFF059669,
                                                            )
                                                          : const Color(
                                                              0xFF10B981,
                                                            ),
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color:
                                                theme.brightness ==
                                                    Brightness.light
                                                ? const Color(0xFFE2E8F0)
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: CustomIconWidget(
                                                iconName: 'remove',
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                widget.onUpdateQuantity(
                                                  index,
                                                  (item["quantity"] as int) - 1,
                                                );
                                              },
                                            ),
                                            Text(
                                              '${item["quantity"]}',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: CustomIconWidget(
                                                iconName: 'add',
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                widget.onUpdateQuantity(
                                                  index,
                                                  (item["quantity"] as int) + 1,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 8.h,
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.cartItems.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 2.w),
                            itemBuilder: (context, index) {
                              final item = widget.cartItems[index];
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item["name"] as String,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'x${item["quantity"]} • Bs ${((item["price"] as double) * (item["quantity"] as int)).toStringAsFixed(2)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
