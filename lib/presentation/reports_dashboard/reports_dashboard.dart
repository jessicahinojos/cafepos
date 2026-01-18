import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/hours_report_widget.dart';
import './widgets/inventory_report_widget.dart';
import './widgets/products_report_widget.dart';
import './widgets/sales_report_widget.dart';

/// Reports Dashboard Screen
/// Provides comprehensive business analytics with interactive charts
/// Supports Sales, Products, Hours, and Inventory reports with date filtering
class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() => _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  String _selectedPreset = 'Semana';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  void _updateDateRange(DateTimeRange range, String preset) {
    setState(() {
      _selectedDateRange = range;
      _selectedPreset = preset;
    });
  }

  void _exportReport(String format) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exportando reporte en formato $format...'),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Reportes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Exportar',
            onSelected: _exportReport,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'CSV',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'table_chart',
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text('Exportar CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'PDF',
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'picture_as_pdf',
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text('Exportar PDF'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 2.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(14.h),
          child: Column(
            children: [
              DateRangeSelectorWidget(
                selectedDateRange: _selectedDateRange,
                selectedPreset: _selectedPreset,
                onDateRangeChanged: _updateDateRange,
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Ventas'),
                  Tab(text: 'Productos'),
                  Tab(text: 'Horarios'),
                  Tab(text: 'Inventario'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: TabBarView(
          controller: _tabController,
          children: [
            SalesReportWidget(
              dateRange: _selectedDateRange,
              isRefreshing: _isRefreshing,
            ),
            ProductsReportWidget(
              dateRange: _selectedDateRange,
              isRefreshing: _isRefreshing,
            ),
            HoursReportWidget(
              dateRange: _selectedDateRange,
              isRefreshing: _isRefreshing,
            ),
            InventoryReportWidget(
              dateRange: _selectedDateRange,
              isRefreshing: _isRefreshing,
            ),
          ],
        ),
      ),
    );
  }
}
