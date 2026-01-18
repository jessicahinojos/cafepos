import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Inventory Report Widget
/// Displays supply consumption patterns and reorder recommendations
class InventoryReportWidget extends StatelessWidget {
  final DateTimeRange dateRange;
  final bool isRefreshing;

  const InventoryReportWidget({
    super.key,
    required this.dateRange,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> mockSupplyConsumption = [
      {
        "name": "Café en Grano",
        "consumed": 15.5,
        "unit": "kg",
        "stock": 8.2,
        "reorderPoint": 10.0,
      },
      {
        "name": "Leche",
        "consumed": 45.8,
        "unit": "L",
        "stock": 25.0,
        "reorderPoint": 30.0,
      },
      {
        "name": "Azúcar",
        "consumed": 8.3,
        "unit": "kg",
        "stock": 12.5,
        "reorderPoint": 5.0,
      },
      {
        "name": "Harina",
        "consumed": 12.7,
        "unit": "kg",
        "stock": 6.8,
        "reorderPoint": 8.0,
      },
      {
        "name": "Mantequilla",
        "consumed": 5.2,
        "unit": "kg",
        "stock": 3.5,
        "reorderPoint": 4.0,
      },
      {
        "name": "Huevos",
        "consumed": 180,
        "unit": "unidades",
        "stock": 120,
        "reorderPoint": 100,
      },
      {
        "name": "Queso",
        "consumed": 6.8,
        "unit": "kg",
        "stock": 4.2,
        "reorderPoint": 5.0,
      },
      {
        "name": "Tomate",
        "consumed": 9.5,
        "unit": "kg",
        "stock": 5.8,
        "reorderPoint": 6.0,
      },
    ];

    final lowStockItems = mockSupplyConsumption
        .where((item) => (item["stock"] as num) < (item["reorderPoint"] as num))
        .toList();

    return isRefreshing
        ? Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lowStockItems.isNotEmpty) ...[
                  _buildLowStockAlert(context, lowStockItems),
                  SizedBox(height: 2.h),
                ],
                _buildConsumptionChart(context, mockSupplyConsumption),
                SizedBox(height: 2.h),
                _buildSupplyList(context, mockSupplyConsumption),
              ],
            ),
          );
  }

  Widget _buildLowStockAlert(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFD97706).withValues(alpha: 0.1)
            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFD97706)
              : const Color(0xFFF59E0B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: theme.brightness == Brightness.light
                    ? const Color(0xFFD97706)
                    : const Color(0xFFF59E0B),
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Alerta de Stock Bajo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.light
                      ? const Color(0xFFD97706)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '${items.length} ${items.length == 1 ? 'producto necesita' : 'productos necesitan'} reabastecimiento',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: items.map((item) {
              return Chip(
                label: Text(
                  item["name"] as String,
                  style: theme.textTheme.bodySmall,
                ),
                backgroundColor: theme.colorScheme.surface,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(
    BuildContext context,
    List<Map<String, dynamic>> supplies,
  ) {
    final theme = Theme.of(context);
    final topFive = supplies.take(5).toList();

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
            'Consumo de Insumos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: Semantics(
              label:
                  "Gráfico de barras mostrando consumo de insumos principales",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (topFive
                                  .map((s) => s["consumed"] as num)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2)
                          .toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${topFive[group.x.toInt()]["name"]}\n${rod.toY.toStringAsFixed(1)} ${topFive[group.x.toInt()]["unit"]}',
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
                            value.toStringAsFixed(0),
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
                                name.length > 8
                                    ? '${name.substring(0, 8)}...'
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
                          toY: (topFive[index]["consumed"] as num).toDouble(),
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

  Widget _buildSupplyList(
    BuildContext context,
    List<Map<String, dynamic>> supplies,
  ) {
    final theme = Theme.of(context);

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
            'Estado de Inventario',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: supplies.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.colorScheme.outline, height: 2.h),
            itemBuilder: (context, index) {
              final supply = supplies[index];
              final stock = supply["stock"] as num;
              final reorderPoint = supply["reorderPoint"] as num;
              final isLowStock = stock < reorderPoint;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supply["name"] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Consumido: ${supply["consumed"]} ${supply["unit"]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stock: $stock ${supply["unit"]}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isLowStock
                                  ? (theme.brightness == Brightness.light
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFFF59E0B))
                                  : (theme.brightness == Brightness.light
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF10B981)),
                            ),
                          ),
                          if (isLowStock) ...[
                            SizedBox(height: 0.5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light
                                    ? const Color(
                                        0xFFD97706,
                                      ).withValues(alpha: 0.1)
                                    : const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Reabastecer',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.brightness == Brightness.light
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
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
