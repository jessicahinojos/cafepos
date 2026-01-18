import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/report_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class SalesReportWidget extends StatefulWidget {
  final DateTimeRange dateRange;
  final bool isRefreshing;

  const SalesReportWidget({
    super.key,
    required this.dateRange,
    required this.isRefreshing,
  });

  @override
  State<SalesReportWidget> createState() => _SalesReportWidgetState();
}

class _SalesReportWidgetState extends State<SalesReportWidget> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  Map<String, dynamic>? _salesData;
  List<Map<String, dynamic>> _dailySummary = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  @override
  void didUpdateWidget(SalesReportWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange ||
        (widget.isRefreshing && !oldWidget.isRefreshing)) {
      _loadSalesData();
    }
  }

  Future<void> _loadSalesData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final salesReport = await _reportService.getSalesReport(
        startDate: widget.dateRange.start,
        endDate: widget.dateRange.end,
      );

      final dailySummary = await _reportService.getDailySalesSummary(
        startDate: widget.dateRange.start,
        endDate: widget.dateRange.end,
      );

      setState(() {
        _salesData = salesReport;
        _dailySummary = dailySummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'Bs',
      decimalDigits: 2,
    );

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text('Error al cargar datos', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _loadSalesData,
              icon: CustomIconWidget(
                iconName: 'refresh',
                color: Colors.white,
                size: 20,
              ),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_salesData == null) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final totalSales = (_salesData!['total_sales'] as num).toDouble();
    final orderCount = _salesData!['order_count'] as int;
    final averageTicket = (_salesData!['average_ticket'] as num).toDouble();
    final totalTax = (_salesData!['total_tax'] as num).toDouble();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'Ventas Totales',
                  currencyFormat.format(totalSales),
                  'trending_up',
                  theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'Pedidos',
                  '$orderCount',
                  'receipt_long',
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'Ticket Promedio',
                  currencyFormat.format(averageTicket),
                  'point_of_sale',
                  const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  theme,
                  'IVA Total',
                  currencyFormat.format(totalTax),
                  'account_balance',
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Daily Sales Chart
          Text(
            'Evolución de Ventas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 40.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _dailySummary.isEmpty
                ? Center(
                    child: Text(
                      'No hay datos para mostrar',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: totalSales / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.brightness == Brightness.light
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < _dailySummary.length) {
                                final date =
                                    _dailySummary[value.toInt()]['date']
                                        as String;
                                final day = date.split('-').last;
                                return Padding(
                                  padding: EdgeInsets.only(top: 1.h),
                                  child: Text(
                                    day,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'Bs${value.toInt()}',
                                style: theme.textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dailySummary.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['total_sales'] as num).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: theme.colorScheme.primary,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withAlpha(26),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date =
                                  _dailySummary[spot.x.toInt()]['date']
                                      as String;
                              return LineTooltipItem(
                                '${currencyFormat.format(spot.y)}\n$date',
                                theme.textTheme.bodySmall!.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String title,
    String value,
    String iconName,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(iconName: iconName, color: color, size: 24),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
