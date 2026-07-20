// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (picked != null) {
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(picked, alwaysUse24HourFormat: false);
    controller.text = formattedTime;
  }
}
  void _openScheduleForm(
    BuildContext context,
    DataStore store, {
    ScheduleTrip? existing,
  }) {
    DateTime date = existing?.date ?? DateTime.now();

    // Safeguards to prevent errors if lists are empty
    String bus =
        existing?.bus ??
        (store.buses.isNotEmpty ? store.buses.first.busNo : '');
    String route =
        existing?.route ??
        (store.routes.isNotEmpty ? store.routes.first.label : '');

    final drivers = store.users.where((u) => u.role == UserRole.driver).toList();
    final conductors = store.users.where((u) => u.role == UserRole.conductor).toList();

    final timeCtrl = TextEditingController(text: existing?.departureTime ?? '');
    final formKey = GlobalKey<FormState>();
    // Preserve the trip's current status (e.g. "completed") when editing -
    // otherwise saving an edit would silently reset it to "scheduled".
    final String status = existing?.status ?? 'scheduled';

    if (store.buses.isEmpty ||
        store.routes.isEmpty ||
        drivers.isEmpty ||
        conductors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildSnack(
          'Add buses, routes, drivers and conductors first',
          SnackType.warning,
        ),
      );
      return;
    }

    AppUser selectedDriver = drivers.firstWhere(
      (d) => d.id == existing?.driverId,
      orElse: () => drivers.first,
    );
    AppUser selectedConductor = conductors.firstWhere(
      (c) => c.id == existing?.conductorId,
      orElse: () => conductors.first,
    );

    showFormDialog(
      context: context,
      title: existing == null ? 'Schedule Trip' : 'Edit Trip',
      icon: Icons.event_note_rounded,
      bodyBuilder: (ctx) {
      return StatefulBuilder(builder: (ctx, setLocal) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DATE PICKER (Restored)
              const Text('Date', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2035));
                  if (picked != null) setLocal(() => date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                  child: Row(children: [Text(fmtDate(date), style: const TextStyle(fontSize: 13)), const Spacer(), const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textMuted)]),
                ),
              ),
              const SizedBox(height: 14),

              // 2. DROPDOWNS
              // Each value falls back to the first available item whenever the
              // saved value no longer matches anything in the current list
              // (e.g. a bus/route/driver/conductor was renamed or removed) -
              // this is what was causing "Edit Trip" to crash.
              AppDropdownField<String>(
                label: 'Bus',
                value: store.buses.any((b) => b.busNo == bus) ? bus : store.buses.first.busNo,
                items: store.buses.map((b) => b.busNo).toList(),
                labelOf: (v) => 'Bus $v',
                onChanged: (v) => setLocal(() => bus = v ?? bus),
              ),
              AppDropdownField<String>(
                label: 'Route',
                value: store.routes.any((r) => r.label == route) ? route : store.routes.first.label,
                items: store.routes.map((r) => r.label).toSet().toList(),
                labelOf: (v) => v,
                onChanged: (v) => setLocal(() => route = v ?? route),
              ),
              AppDropdownField<AppUser>(
                label: 'Driver',
                value: selectedDriver,
                items: drivers,
                labelOf: (u) => u.name,
                onChanged: (v) => setLocal(() => selectedDriver = v ?? selectedDriver),
              ),
              AppDropdownField<AppUser>(
                label: 'Conductor',
                value: selectedConductor,
                items: conductors,
                labelOf: (u) => u.name,
                onChanged: (v) => setLocal(() => selectedConductor = v ?? selectedConductor),
              ),

              // DEPARTURE TIME FIELD
              AppTextField(
                label: 'Departure Time',
                controller: timeCtrl,
                readOnly: true, // This makes it un-typeable, forcing the user to tap it
                onTap: () => _selectTime(ctx, timeCtrl), // This triggers the picker
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // SUBMIT BUTTON (with your custom styling)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Use your custom color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () { 
                    if (!formKey.currentState!.validate()) return;
                    final newTrip = ScheduleTrip(
                      id: existing?.id ?? '', // Keeps existing ID if editing, empty if new
                      date: date,
                      bus: bus,
                      route: route,
                      driverId: selectedDriver.id,
                      driver: selectedDriver.name,
                      conductorId: selectedConductor.id,
                      conductor: selectedConductor.name,
                      departureTime: timeCtrl.text.trim(),
                      status: status, // preserves "completed" instead of resetting it
                    );

                    // 3. Save to Firestore via DataStore
                    if (existing == null) {
                      store.addSchedule(newTrip);
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildSnack('Trip scheduled successfully', SnackType.success)
                      );
                    } else {
                      store.updateSchedule(newTrip);
                      ScaffoldMessenger.of(context).showSnackBar(
                        buildSnack('Trip updated successfully', SnackType.success)
                      );
                    }

                    // 4. Close the dialog
                    Navigator.pop(context);
                  },
                  child: Text(existing == null ? 'Schedule Trip' : 'Save Changes'),
                ),
              ),
            ],
          ),
        );
      });
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final list = store.schedules.where((s) {
          final d = DateTime(s.date.year, s.date.month, s.date.day);
          final from = DateTime(_from.year, _from.month, _from.day);
          final to = DateTime(_to.year, _to.month, _to.day);
          return !d.isBefore(from) && !d.isAfter(to);
        }).toList()..sort((a, b) => a.date.compareTo(b.date));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Schedules',
                subtitle: 'Plan and manage trip schedules for any date',
                action: PrimaryButton(
                  label: 'Schedule Trip',
                  onPressed: () => _openScheduleForm(context, store),
                ),
              ),
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
                          _dateBox('FROM', _from, () => _pickDate(true)),
                          _dateBox('TO', _to, () => _pickDate(false)),
                          Text(
                            '${list.length} trip${list.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_rounded,
                                  size: 44,
                                  color: AppColors.textMuted.withOpacity(0.5),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'No trips scheduled for this date range.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, c) {
                            if (c.maxWidth < 760) {
                              return Column(
                                children: list.asMap().entries.map((e) {
                                  final s = e.value;
                                  return FadeInUp(
                                    delayMs: e.key * 40,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                fmtDate(s.date),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                s.departureTime,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Bus ${s.bus} \u2022 ${s.route}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          Text(
                                            'Driver: ${s.driver} \u2022 Conductor: ${s.conductor}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    _openScheduleForm(
                                                      context,
                                                      store,
                                                      existing: s,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AppColors.danger,
                                                ),
                                                onPressed: () =>
                                                    _deleteSchedule(
                                                      context,
                                                      store,
                                                      s,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                            return AppDataTable(
                              columns: const [
                                AppTableColumn('Date', 110),
                                AppTableColumn('Bus', 60),
                                AppTableColumn('Route', 170),
                                AppTableColumn('Driver', 140),
                                AppTableColumn('Conductor', 140),
                                AppTableColumn('Departure', 100),
                                AppTableColumn('Actions', 90),
                              ],
                              rows: list.map((s) {
                                return [
                                  Text(
                                    fmtDate(s.date),
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  Text(
                                    s.bus,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  Text(
                                    s.route,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  Text(
                                    s.driver,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  Text(
                                    s.conductor,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  Text(
                                    s.departureTime,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 17,
                                        ),
                                        onPressed: () => _openScheduleForm(
                                          context,
                                          store,
                                          existing: s,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 17,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () =>
                                            _deleteSchedule(context, store, s),
                                      ),
                                    ],
                                  ),
                                ];
                              }).toList(),
                            );
                          },
                        ),
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

  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label  ',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              fmtDate(date),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSchedule(
    BuildContext context,
    DataStore store,
    ScheduleTrip s,
  ) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete Trip?',
      message: 'Delete the ${s.departureTime} trip on ${fmtDate(s.date)}?',
    );
    if (ok) {
      store.deleteSchedule(s.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(buildSnack('Trip removed from schedule', SnackType.error));
    }
  }
}