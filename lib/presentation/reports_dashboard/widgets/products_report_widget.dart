import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Products Report Widget
/// Displays top-selling and underperforming products with bar charts
class ProductsReportWidget extends StatelessWidget {
  final DateTimeRange dateRange;
  final bool isRefreshing;

  const ProductsReportWidget({
    super.key,
    required this.dateRange,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> mockTopProducts = [
      {"name": "Café Americano", "quantity": 245, "revenue": 1225.00},
      {"name": "Croissant", "quantity": 198, "revenue": 990.00},
      {"name": "Cappuccino", "quantity": 187, "revenue": 1122.00},
      {"name": "Sandwich Mixto", "quantity": 156, "revenue": 1248.00},
      {"name": "Jugo Natural", "quantity": 142, "revenue": 852.00},
      {"name": "Ensalada César", "quantity": 128, "revenue": 1152.00},
      {"name": "Té Verde", "quantity": 115, "revenue": 460.00},
      {"name": "Brownie", "quantity": 98, "revenue": 490.00},
      {"name": "Smoothie", "quantity": 87, "revenue": 609.00},
      {"name": "Tostadas", "quantity": 76, "revenue": 380.00},
    ];

    final List<Map<String, dynamic>> mockUnderperforming = [
      {"name": "Sopa del Día", "quantity": 12, "revenue": 96.00},
      {"name": "Té de Hierbas", "quantity": 18, "revenue": 72.00},
      {"name": "Galletas", "quantity": 23, "revenue": 92.00},
    ];

    return isRefreshing
        ? Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopProductsChart(context, mockTopProducts),
                SizedBox(height: 2.h),
                _buildTopProductsList(context, mockTopProducts),
                SizedBox(height: 2.h),
                _buildUnderperformingProducts(context, mockUnderperforming),
              ],
            ),
          );
  }

  Widget _buildTopProductsChart(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    final theme = Theme.of(context);
    final topFive = products.take(5).toList();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Productos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: Semantics(
              label: "Gráfico de barras mostrando los 5 productos más vendidos",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (topFive
                                  .map((p) => p["quantity"] as int)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2)
                          .toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${topFive[group.x.toInt()]["name"]}\n${rod.toY.toInt()} unidades',
                          theme.textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < topFive.length) {
                            final name =
                                topFive[value.toInt()]["name"] as String;
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                name.length > 10
                                    ? '${name.substring(0, 10)}...'
                                    : name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    topFive.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (topFive[index]["quantity"] as int).toDouble(),
                          color: theme.colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsList(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'Bs',
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos Más Vendidos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.colorScheme.outline, height: 2.h),
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product["name"] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${product["quantity"]} unidades',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(product["revenue"]),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.light
                            ? const Color(0xFF059669)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnderperformingProducts(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'Bs',
      decimalDigits: 2,
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'trending_down',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Productos de Bajo Rendimiento',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.colorScheme.outline, height: 2.h),
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product["name"] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${product["quantity"]} unidades',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(product["revenue"]),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
