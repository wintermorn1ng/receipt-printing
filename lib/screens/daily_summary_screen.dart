import 'package:flutter/material.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/models/daily_summary.dart';
import 'package:receipt_printing/services/summary_service.dart';

/// 日总结页面
///
/// 展示每日的订单统计数据（订单总数、各菜品销量、时段分布）
class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  late final SummaryService _summaryService;
  late DateTime _selectedDate;
  late Future<DailySummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryService = SummaryService(OrderDao());
    _selectedDate = DateTime.now();
    _loadSummary();
  }

  void _loadSummary() {
    _summaryFuture = _summaryService.getDailySummary(_selectedDate);
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _loadSummary();
    });
  }

  void _goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate.isBefore(tomorrow)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _loadSummary();
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadSummary();
      });
    }
  }

  String _formatDateDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return '今日';
    } else if (selected == yesterday) {
      return '昨日';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日总结'),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: FutureBuilder<DailySummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败: ${snapshot.error}'),
                  );
                }
                final summary = snapshot.data!;
                return _buildContent(summary);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = selected == today;
    final isFuture = selected.isAfter(today);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousDay,
            icon: const Icon(Icons.chevron_left),
            tooltip: '前一天',
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDateDisplay(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isToday || isFuture ? null : _goToNextDay,
            icon: const Icon(Icons.chevron_right),
            tooltip: '后一天',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DailySummary summary) {
    if (summary.totalOrders == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderCountCard(summary.totalOrders),
          const SizedBox(height: 16),
          _buildDishSalesList(summary.dishSummaries),
          const SizedBox(height: 16),
          _buildHourlyDistribution(summary.hourlyDistribution),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '当日暂无订单',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCountCard(int totalOrders) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '订单总数',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              totalOrders.toString(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              '单',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishSalesList(List<DishSummary> dishSummaries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '菜品销量',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...dishSummaries.map((dish) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dish.dishName,
                          style: Theme.of(context).textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${dish.count} 份',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyDistribution(Map<int, int> hourlyDistribution) {
    // 只显示 06-22 时的数据
    final filteredDistribution = Map.fromEntries(
      hourlyDistribution.entries.where(
        (e) => e.key >= 6 && e.key <= 22,
      ),
    );

    final maxCount = filteredDistribution.values.isEmpty
        ? 1
        : filteredDistribution.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: ExpansionTile(
        title: Text(
          '时段分布',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        initiallyExpanded: false,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: filteredDistribution.entries.map((entry) {
                final hour = entry.key;
                final count = entry.value;
                final barWidth =
                    maxCount > 0 ? (count / maxCount) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: barWidth,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 32,
                        child: Text(
                          count.toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}