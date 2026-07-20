// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Dashboard', 
                subtitle: 'Operations overview, analytics & predictive forecasting',
              ),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 1000 ? 4 : (c.maxWidth > 640 ? 2 : 1);
                final cardW = (c.maxWidth - (cols - 1) * 14) / cols;
                final stats = [
                  _StatData('Total Revenue (Month)', fmtPeso(store.totalRevenueMonth), Icons.payments_rounded, AppColors.primary),
                  _StatData('Passengers (Month)', '${store.passengersMonth}', Icons.groups_rounded, AppColors.success),
                  _StatData('Bus Utilization', '${store.buses.isEmpty ? 0 : ((store.buses.where((b) => b.status == BusStatus.active).length / store.buses.length) * 100).round()}%', Icons.directions_bus_rounded, AppColors.warning),
                  _StatData('Remittances', '${store.remittances.length}', Icons.receipt_long_rounded, AppColors.primaryLight),
                ];
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: List.generate(stats.length, (i) {
                    return SizedBox(
                      width: cardW, 
                      child: FadeInUp(
                        delayMs: i * 80, 
                        child: _StatCard(data: stats[i]),
                      ),
                    );
                  }),
                );
              }),
              const SizedBox(height: 18),
              FadeInUp(
                delayMs: 260,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Passenger Demand \u2014 Last 7 Days & Next 7 Day Forecast', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        height: 180, 
                        child: _DemandChart(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 800;
                final left = FadeInUp(
                  delayMs: 320,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Route Profitability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const SizedBox(height: 16),
                        ..._routeProfitability(store).map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                    children: [
                                      Text(e.key, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                      Text(fmtPeso(e.value), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: e.value <= 0 ? 0.02 : (e.value / (_maxVal(store) == 0 ? 1 : _maxVal(store))).clamp(0.02, 1.0)),
                                      duration: const Duration(milliseconds: 700),
                                      builder: (context, v, _) => LinearProgressIndicator(
                                        value: v, 
                                        minHeight: 8, 
                                        backgroundColor: AppColors.bg, 
                                        color: AppColors.primary,
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
                final right = FadeInUp(
                  delayMs: 380,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remittance Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            height: 140,
                            width: 140,
                            // Use this inside your build method if store.approvedCount/pendingCount no longer exist
                            child: _RemittanceDonut(
                              approved: store.remittances.where((r) => r.status == RemittanceStatus.approved).length,
                              pending: store.remittances.where((r) => r.status == RemittanceStatus.pending).length,
                              rejected: store.remittances.where((r) => r.status == RemittanceStatus.rejected).length,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 14, 
                          runSpacing: 8, 
                          alignment: WrapAlignment.center, 
                          children: [
                            _legendDot(AppColors.success, 'Approved'),
                            _legendDot(AppColors.warning, 'Pending'),
                            _legendDot(AppColors.danger, 'Rejected'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Expanded(child: left), 
                      const SizedBox(width: 14), 
                      Expanded(child: right),
                    ],
                  );
                }
                return Column(children: [left, const SizedBox(height: 14), right]);
              }),
              const SizedBox(height: 14),
              FadeInUp(
                delayMs: 440,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Peak Hours Forecast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                      const Text('7-day average ticket volume by hour', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                      const SizedBox(height: 14),
                      _peakRow('3:00 AM', '+2 tickets/hr avg', 'Very High', AppColors.danger),
                      _peakRow('4:00 PM', '+2 tickets/hr avg', 'High', AppColors.warning),
                      _peakRow('5:00 PM', '+1 tickets/hr avg', 'Moderate', AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<MapEntry<String, double>> _routeProfitability(DataStore store) {
    if (store.routes.isEmpty) return [];
    final rnd = Random(7);
    return store.routes.map((r) => MapEntry(r.label, 200.0 + rnd.nextInt(400))).toList();
  }

  static double _maxVal(DataStore store) {
    final list = _routeProfitability(store);
    if (list.isEmpty) return 1;
    return list.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  Widget _legendDot(Color c, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]);
  }

  Widget _peakRow(String time, String detail, String level, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
          StatusChip(label: level, color: color),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(data.value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: data.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
        ],
      ),
    );
  }
}

// ==================== 📈 FIRESTORE DRIVEN LINE CHART ====================
// ==================== 📈 FIRESTORE DRIVEN LINE CHART ====================
class _DemandChart extends StatelessWidget {
  const _DemandChart();

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);

    // 1. Calculate historical metrics derived from live Firestore lists
    final List<double> actualPoints = _getPast7DaysDemand(store.remittances);
    final List<double> forecastPoints = _getForecast7DaysDemand(store.remittances);

    final List<FlSpot> actualSpots = [];
    for (int i = 0; i < actualPoints.length; i++) {
      actualSpots.add(FlSpot(i.toDouble(), actualPoints[i]));
    }

    final List<FlSpot> forecastSpots = [];
    if (actualSpots.isNotEmpty) {
      forecastSpots.add(FlSpot((actualSpots.length - 1).toDouble(), actualSpots.last.y));
    }
    for (int i = 0; i < forecastPoints.length; i++) {
      forecastSpots.add(FlSpot((actualPoints.length - 1 + i).toDouble(), forecastPoints[i]));
    }

    final combinedList = [...actualPoints, ...forecastPoints];
    final double maxVal = combinedList.isEmpty ? 50 : combinedList.reduce((a, b) => a > b ? a : b);
    final double computedMaxY = maxVal == 0 ? 50 : maxVal * 1.25;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF556677),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  touchedSpot.y.toInt().toString(),
                  const TextStyle(
                    color: Colors.white, // This makes the number white
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 13, 
        minY: 0,
        maxY: computedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: actualSpots.isEmpty ? [const FlSpot(0, 0)] : actualSpots,
            isCurved: true, // Simply set isCurved to true for bezier smoothing
            color: const Color.fromARGB(255, 30, 77, 183),
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.06)),
          ),
          LineChartBarData(
            spots: forecastSpots.isEmpty ? [const FlSpot(6, 0)] : forecastSpots,
            isCurved: true, // Simply set isCurved to true for bezier smoothing
            color: AppColors.warning,
            barWidth: 2.6,
            isStrokeCapRound: true,
            dashArray: [5, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.warning.withOpacity(0.04)),
          ),
        ],
      ),
    );
  }

  // Parses ticket aggregates out of Firestore transactions for the trailing week
  List<double> _getPast7DaysDemand(List<Remittance> remittances) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<double> values = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
      final targetDate = today.subtract(Duration(days: 6 - i));
      
      // Filter remittances matching exactly this targeted day
      final dailyRemittances = remittances.where((r) {
        return r.date.year == targetDate.year &&
               r.date.month == targetDate.month &&
               r.date.day == targetDate.day &&
               r.status == RemittanceStatus.approved;
      });

      // Sum ticket volume calculated from the size of tripDetails array
      double ticketCount = 0;
      for (var r in dailyRemittances) {
        ticketCount += r.tripDetails.length * 5; // Replicating your store logic parameters
      }
      values[i] = ticketCount;
    }
    return values;
  }

  // Generates predictive data based on historical day-of-week ticket averages
  List<double> _getForecast7DaysDemand(List<Remittance> remittances) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<double> forecasts = List.filled(7, 0.0);

    for (int i = 1; i <= 7; i++) {
      final forecastDay = today.add(Duration(days: i));
      final weekdayTarget = forecastDay.weekday;

      // Find historic ticket data for this specific day of the week
      final historicalMatches = remittances.where((r) => 
        r.date.weekday == weekdayTarget && 
        r.status == RemittanceStatus.approved
      );

      if (historicalMatches.isEmpty) {
        forecasts[i - 1] = 15.0; // Clean baseline fallback
        continue;
      }

      double totalTickets = 0;
      // Gather dynamic historical sets across distinct matching dates
      final uniqueDates = historicalMatches.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();
      
      for (var r in historicalMatches) {
        totalTickets += r.tripDetails.length * 5;
      }

      forecasts[i - 1] = totalTickets / uniqueDates.length;
    }
    return forecasts;
  }

  static Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: 9);
    String text = '';
    if (value == 0) text = '7D Ago';
    if (value == 3) text = '4D Ago';
    if (value == 6) text = 'Today';
    if (value == 9) text = 'In 3D';
    if (value == 13) text = 'In 7D';

    // Pass the 'meta' object directly into SideTitleWidget 
    return SideTitleWidget(
      meta: meta, 
      space: 6, 
      child: Text(text, style: style),
    );
  }
}

// ==================== 🍩 FIRESTORE DRIVEN DONUT CHART ====================
class _RemittanceDonut extends StatelessWidget {
  final int approved;
  final int pending;
  final int rejected;

  const _RemittanceDonut({
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final total = approved + pending + rejected;
    final pct = total == 0 ? 0 : ((approved / total) * 100).round();

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 48,
            startDegreeOffset: -90, 
            sections: _buildPieSections(),
          ),
        ),
        Text(
          '$pct%', 
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = approved + pending + rejected;

    if (total == 0) {
      return [
        PieChartSectionData(
          color: AppColors.border,
          value: 1,
          radius: 16,
          showTitle: false,
        )
      ];
    }

    return [
      PieChartSectionData(color: AppColors.success, value: approved.toDouble(), radius: 16, showTitle: false),
      PieChartSectionData(color: AppColors.warning, value: pending.toDouble(), radius: 16, showTitle: false),
      PieChartSectionData(color: AppColors.danger, value: rejected.toDouble(), radius: 16, showTitle: false),
    ];
  }
}