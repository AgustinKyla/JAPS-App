// ignore_for_file: deprecated_member_use, unnecessary_underscores

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class RemittancesPage extends StatefulWidget {
  const RemittancesPage({super.key});

  @override
  State<RemittancesPage> createState() => _RemittancesPageState();
}

class _RemittancesPageState extends State<RemittancesPage> {
  String _search = '';
  RemittanceStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        var list = store.remittances.where((r) {
          final matchesSearch = _search.isEmpty ||
              r.conductor.toLowerCase().contains(_search.toLowerCase()) ||
              r.driver.toLowerCase().contains(_search.toLowerCase()) ||
              r.bus.toLowerCase().contains(_search.toLowerCase());
          final matchesStatus = _statusFilter == null || r.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList()
          ..sort((a, b) => b.submitted.compareTo(a.submitted));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'Remittances', subtitle: 'Overview of all conductor remittance reports'),
              const SizedBox(height: 16),
              FadeInUp(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SearchField(hint: 'Search conductor, driver, or bus', onChanged: (v) => setState(() => _search = v)),
                          FilterDropdown<RemittanceStatus?>(
                            value: _statusFilter,
                            items: [null, ...RemittanceStatus.values],
                            labelOf: (v) => v == null ? 'All Status' : v.label,
                            onChanged: (v) => setState(() => _statusFilter = v),
                          ),
                          Text('${list.length} result${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, c) {
                        if (list.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No remittances found.', style: TextStyle(color: AppColors.textMuted))),
                          );
                        }
                        if (c.maxWidth < 760) {
                          return Column(children: list.asMap().entries.map((e) => FadeInUp(delayMs: e.key * 40, child: _RemittanceCard(r: e.value))).toList());
                        }
                        return _RemittanceTable(list: list);
                      }),
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
}

class _RemittanceTable extends StatelessWidget {
  final List<Remittance> list;
  const _RemittanceTable({required this.list});

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      columns: const [
        AppTableColumn('Date', 110),
        AppTableColumn('Conductor', 140),
        AppTableColumn('Driver', 140),
        AppTableColumn('Bus', 60),
        AppTableColumn('Trips', 60),
        AppTableColumn('Gross Income', 120),
        AppTableColumn('Total Revenue', 130),
        AppTableColumn('Status', 110),
        AppTableColumn('Submitted', 150),
        AppTableColumn('Details', 80),
      ],
      rows: list.map((r) {
        return [
          Text(fmtDate(r.date), style: const TextStyle(fontSize: 12.5)),
          Text(r.conductor, style: const TextStyle(fontSize: 12.5)),
          Text(r.driver, style: const TextStyle(fontSize: 12.5)),
          Text(r.bus, style: const TextStyle(fontSize: 12.5)),
          Text('${r.trips}', style: const TextStyle(fontSize: 12.5)),
          Text(fmtPeso(r.grossIncome), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          Text(fmtPeso(r.totalRevenue), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12.5)),
          StatusChip(label: r.status.label, color: remStatusColor(r.status)),
          Text(fmtDateTime(r.submitted), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => _openDetails(context, r),
            child: const Text('View'),
          ),
        ];
      }).toList(),
    );
  }
}

class _RemittanceCard extends StatelessWidget {
  final Remittance r;
  const _RemittanceCard({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(fmtDate(r.date), style: const TextStyle(fontWeight: FontWeight.bold)),
            StatusChip(label: r.status.label, color: remStatusColor(r.status)),
          ]),
          const SizedBox(height: 8),
          Text('Conductor: ${r.conductor}', style: const TextStyle(fontSize: 12.5)),
          Text('Driver: ${r.driver} \u2022 Bus ${r.bus}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Revenue: ${fmtPeso(r.totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
            TextButton(onPressed: () => _openDetails(context, r), child: const Text('View')),
          ]),
        ],
      ),
    );
  }
}

void _openDetails(BuildContext context, Remittance r) {
  final store = DataScope.of(context);
  final index = store.remittances.indexOf(r) + 1;
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: RemittanceDetailsPage(remittance: r, displayNumber: index),
        ),
      ),
    ),
  );
}

Widget _detailRow(String label, String value, {bool bold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: bold ? 14.5 : 12.5, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textDark)),
      ],
    ),
  );
}

//Remittance details page with all the information about a specific remittance report

class RemittanceDetailsPage extends StatelessWidget {
  final Remittance remittance;
  final int displayNumber;
  const RemittanceDetailsPage({super.key, required this.remittance, required this.displayNumber});

  String? _employeeIdFor(DataStore store, String name) {
    final match = store.users.where((u) => u.name == name);
    return match.isEmpty ? null : match.first.employeeId;
  }

  String? _plateFor(DataStore store, String busNo) {
    final match = store.buses.where((b) => b.busNo == busNo);
    return match.isEmpty ? null : match.first.plateNumber;
  }

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    final r = remittance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header: back arrow, title, date, status pill ----
                  FadeInUp(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4, right: 10),
                            child: Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textDark),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('Remittance Details ', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                  Text('#$displayNumber', style: const TextStyle(fontSize: 15, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(fmtDate(r.date), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        StatusChip(label: r.status == RemittanceStatus.pending ? 'Pending Review' : r.status.label, color: remStatusColor(r.status)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 900;
                    final left = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Personnel & Bus ----
                        FadeInUp(
                          delayMs: 80,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Personnel & Bus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 32,
                                  runSpacing: 16,
                                  children: [
                                    _personnelBlock('Conductor', r.conductor, _employeeIdFor(store, r.conductor)),
                                    _personnelBlock('Driver', r.driver, _employeeIdFor(store, r.driver)),
                                    _personnelBlock('Bus', 'Bus ${r.bus}', _plateFor(store, r.bus)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ---- Trips ----
                        FadeInUp(
                          delayMs: 140,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text('Trips (${r.trips})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                  const Spacer(),
                                  Text('${r.trips} total trips', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                ]),
                                const SizedBox(height: 12),
                                AppDataTable(
                                  columns: const [
                                    AppTableColumn('Trip #', 60),
                                    AppTableColumn('Route', 150),
                                    AppTableColumn('Departure', 100),
                                    AppTableColumn('Tickets', 130),
                                    AppTableColumn('Grand Total', 110),
                                  ],
                                  rows: r.tripDetails.map((t) {
                                    return [
                                      Text('${t.tripNo}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                      Text(t.route, style: const TextStyle(fontSize: 12.5)),
                                      Text(t.departure, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                      Text(t.ticketsRange, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                      Text(fmtPeso(t.grandTotal), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    ];
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ---- Trip Expenses ----
                        FadeInUp(
                          delayMs: 200,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Trip Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                const SizedBox(height: 12),
                                ...r.expenses.entries.map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 7),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text(e.key, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                                        Text(fmtPeso(e.value), style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w700)),
                                      ]),
                                    )),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    const Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                                    Text(fmtPeso(r.totalExpenses), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.danger)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );

                    final right = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---- Financial Summary ----
                        FadeInUp(
                          delayMs: 120,
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                const SizedBox(height: 10),
                                _detailRow('Gross Income', fmtPeso(r.grossIncome), color: AppColors.success),
                                _detailRow('Less Expenses', '-${fmtPeso(r.totalExpenses)}', color: AppColors.danger),
                                const Divider(height: 22),
                                
                                // Breakdown of deductions
                                _detailRow('Driver Commission', '-${fmtPeso(r.driverCommission)}', color: AppColors.warning),
                                _detailRow('Conductor Commission', '-${fmtPeso(r.conductorCommission)}', color: AppColors.warning),
                                _detailRow('Bonus', '-${fmtPeso(r.bonus)}', color: AppColors.warning), // Added Bonus
                                _detailRow('Diesel', '-${fmtPeso(r.diesel)}', color: AppColors.warning), // Added Diesel
                                _detailRow('Toll Fee', '-${fmtPeso(1000.0)}', color: AppColors.warning), // Added Flat Toll
                                _detailRow('Cash Deposit', '-${fmtPeso(r.cashDeposit)}', color: AppColors.warning), // Moved here as a deduction
                                
                                const Divider(height: 22),
                                _detailRow('Total Less', '-${fmtPeso(r.totalLess)}', bold: true),
                                _detailRow('Net Collection', '-${fmtPeso(r.netCollection)}', color: AppColors.danger),
                                const SizedBox(height: 10),
                                
                                // Highlighted Total Revenue
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08), 
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                    children: [
                                      const Text('Total Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.primary)),
                                      Text(fmtPeso(r.totalRevenue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ---- Submitted ----
                        FadeInUp(
                          delayMs: 180,
                          child: AppCard(
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              const Text('Submitted', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                              Text(fmtDateTime(r.submitted), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        if (r.status == RemittanceStatus.pending) ...[
                          const SizedBox(height: 14),
                          FadeInUp(
                            delayMs: 240,
                            child: Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.danger),
                                  label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 13)),
                                  onPressed: () {
                                    final messenger = ScaffoldMessenger.of(context);
                                    store.setRemittanceStatus(r.id, RemittanceStatus.rejected);
                                    Navigator.of(context).pop();
                                    messenger.showSnackBar(buildSnack('Remittance rejected', SnackType.warning));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_rounded, size: 17),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                                  onPressed: () {
                                    final messenger = ScaffoldMessenger.of(context);
                                    store.setRemittanceStatus(r.id, RemittanceStatus.approved);
                                    Navigator.of(context).pop();
                                    messenger.showSnackBar(buildSnack('Remittance approved', SnackType.success));
                                  },
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ],
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: left),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: right),
                        ],
                      );
                    }
                    return Column(children: [left, const SizedBox(height: 14), right]);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _personnelBlock(String label, String value, String? sub) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          if (sub != null) Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}