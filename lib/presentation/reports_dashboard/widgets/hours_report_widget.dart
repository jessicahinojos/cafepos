import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Hours Report Widget
/// Displays peak business hours with heatmap and hourly distribution
class HoursReportWidget extends StatelessWidget {
  final DateTimeRange dateRange;
  final bool isRefreshing;

  const HoursReportWidget({
    super.key,
    required this.dateRange,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> mockHourlyData = [
      {"hour": "08:00", "orders": 12, "revenue": 240.00},
      {"hour": "09:00", "orders": 28, "revenue": 560.00},
      {"hour": "10:00", "orders": 45, "revenue": 900.00},
      {"hour": "11:00", "orders": 52, "revenue": 1040.00},
      {"hour": "12:00", "orders": 68, "revenue": 1360.00},
      {"hour": "13:00", "orders": 75, "revenue": 1500.00},
      {"hour": "14:00", "orders": 62, "revenue": 1240.00},
      {"hour": "15:00", "orders": 38, "revenue": 760.00},
      {"hour": "16:00", "orders": 42, "revenue": 840.00},
      {"hour": "17:00", "orders": 55, "revenue": 1100.00},
      {"hour": "18:00", "orders": 71, "revenue": 1420.00},
      {"hour": "19:00", "orders": 82, "revenue": 1640.00},
      {"hour": "20:00", "orders": 65, "revenue": 1300.00},
      {"hour": "21:00", "orders": 48, "revenue": 960.00},
    ];

    final maxOrders = mockHourlyData
        .map((h) => h["orders"] as int)
        .reduce((a, b) => a > b ? a : b);

    return isRefreshing
        ? Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeakHoursCard(context, mockHourlyData),
                SizedBox(height: 2.h),
                _buildHourlyDistributionChart(context, mockHourlyData),
                SizedBox(height: 2.h),
                _buildHeatmap(context, mockHourlyData, maxOrders),
              ],
            ),
          );
  }

  Widget _buildPeakHoursCard(
    BuildContext context,
    List<Map<String, dynamic>> data,
  ) {
    final theme = Theme.of(context);

    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => (b["orders"] as int).compareTo(a["orders"] as int));
    final peakHour = sortedData.first;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: 'schedule',
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hora Pico',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  peakHour["hour"] as String,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${peakHour["orders"]} órdenes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyDistributionChart(
    BuildContext context,
    List<Map<String, dynamic>> data,
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
            'Distribución por Hora',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: Semantics(
              label:
                  "Gráfico de barras mostrando distribución de órdenes por hora",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (data
                                  .map((h) => h["orders"] as int)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2)
                          .toDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[group.x.toInt()]["hour"]}\n${rod.toY.toInt()} órdenes',
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
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length &&
                              value.toInt() % 2 == 0) {
                            return Text(
                              (data[value.toInt()]["hour"] as String).substring(
                                0,
                                2,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    data.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data[index]["orders"] as int).toDouble(),
                          color: theme.colorScheme.primary,
                          width: 12,
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

  Widget _buildHeatmap(
    BuildContext context,
    List<Map<String, dynamic>> data,
    int maxOrders,
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
            'Mapa de Calor',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 1.w,
            runSpacing: 1.h,
            children: data.map((hour) {
              final orders = hour["orders"] as int;
              final intensity = orders / maxOrders;
              final color = Color.lerp(
                theme.colorScheme.primary.withValues(alpha: 0.2),
                theme.colorScheme.primary,
                intensity,
              )!;

              return Container(
                width: 20.w,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      hour["hour"] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: intensity > 0.5
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      orders.toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: intensity > 0.5
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bajo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                width: 40.w,
                height: 1.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Alto',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
