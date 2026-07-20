// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  String _search = '';
  BusStatus? _statusFilter;

  void _openBusForm(BuildContext context, DataStore store, {Bus? existing}) {
    // Prerequisite lists needed for the form's dropdowns.
    final drivers = store.users.where((u) => u.role == UserRole.driver).toList();
    final conductors = store.users.where((u) => u.role == UserRole.conductor).toList();

    if (store.routes.isEmpty || drivers.isEmpty || conductors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        buildSnack('Add routes, drivers and conductors first', SnackType.warning),
      );
      return;
    }

    final busNoItems = store.buses.map((b) => b.busNo).toList();
    final bool isEditing = existing != null;

    final busNoCtrl = TextEditingController(text: existing?.busNo ?? '');
    final plateCtrl = TextEditingController(text: existing?.plateNumber ?? '');
    final capacityCtrl = TextEditingController(text: existing?.capacity.toString() ?? '');
    AppUser selectedDriver = drivers.firstWhere(
      (d) => d.id == existing?.assignedDriverId,
      orElse: () => drivers.first,
    );
    AppUser selectedConductor = conductors.firstWhere(
      (c) => c.id == existing?.assignedConductorId,
      orElse: () => conductors.first,
    );
    String route = (existing != null && store.routes.any((r) => r.label == existing.defaultRoute))
        ? existing.defaultRoute
        : store.routes.first.label;
    BusStatus status = existing?.status ?? BusStatus.active;
    final formKey = GlobalKey<FormState>();

    // These live outside the StatefulBuilder so they survive rebuilds
    // (declaring them inside the builder was resetting the form every
    // time a field changed, which is what caused the Add/Edit crash).
    String? selectedBusNo = existing?.busNo;
    String plateNumber = existing?.plateNumber ?? '';
    if (isEditing && (selectedBusNo == null || !busNoItems.contains(selectedBusNo))) {
      selectedBusNo = busNoItems.first;
      busNoCtrl.text = selectedBusNo;
      plateNumber = store.buses.firstWhere((b) => b.busNo == selectedBusNo).plateNumber;
      plateCtrl.text = plateNumber;
    }

    showFormDialog(
      context: context,
      title: existing == null ? 'Add Bus' : 'Edit Bus',
      icon: Icons.directions_bus_rounded,
      bodyBuilder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing) ...[
                  AppDropdownField<String>(
                    label: 'Bus Number',
                    value: selectedBusNo!,
                    items: busNoItems,
                    labelOf: (v) => v,
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() {
                        selectedBusNo = v;
                        busNoCtrl.text = v; // Update controller
                        final selectedBus = store.buses.firstWhere((b) => b.busNo == v);
                        plateNumber = selectedBus.plateNumber;
                        plateCtrl.text = plateNumber; // Update controller
                      });
                    },
                  ),
                  AppTextField(
                    label: 'Plate Number',
                    controller: plateCtrl,
                    readOnly: true,
                  ),
                ] else ...[
                  // No buses exist yet, so there's nothing to pick from -
                  AppTextField(
                    label: 'Bus Number',
                    controller: busNoCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  AppTextField(
                    label: 'Plate Number',
                    controller: plateCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
                AppTextField(
                  label: 'Capacity',
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                AppDropdownField<AppUser>(
                  label: 'Driver',
                  value: selectedDriver,
                  items: drivers,
                  labelOf: (u) => u.name,
                  onChanged: (v) => setLocal(() => selectedDriver = v ?? selectedDriver),
                ),

                // Assigned Conductor Dropdown
                AppDropdownField<AppUser>(
                  label: 'Conductor',
                  value: selectedConductor,
                  items: conductors,
                  labelOf: (u) => u.name,
                  onChanged: (v) => setLocal(() => selectedConductor = v ?? selectedConductor),
                ),
                AppDropdownField<String>(
                    label: 'Default Route',
                    value: store.routes.any((r) => r.label == route) ? route : store.routes.first.label,
                    items: store.routes.map((r) => r.label).toList(),
                    labelOf: (v) => v,
                    onChanged: (v) => setLocal(() => route = v ?? route),
                  ),  
                AppDropdownField<BusStatus>(
                  label: 'Status',
                  value: status,
                  items: BusStatus.values,
                  labelOf: (v) => v.label,
                  onChanged: (v) => setLocal(() => status = v ?? status),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      if (existing == null) {
                        store.addBus(Bus(
                          id: '',
                          busNo: busNoCtrl.text.trim(), 
                          plateNumber: plateCtrl.text.trim(),
                          capacity: int.parse(capacityCtrl.text.trim()),
                          assignedDriverId: selectedDriver.id,
                          assignedDriverName: selectedDriver.name,
                          assignedConductorId: selectedConductor.id,
                          assignedConductorName: selectedConductor.name,
                          defaultRoute: route,
                          status: status,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(buildSnack('Bus added successfully', SnackType.success));
                      } else {
                        existing.busNo = busNoCtrl.text.trim();
                        existing.plateNumber = plateCtrl.text.trim();
                        existing.capacity = int.parse(capacityCtrl.text.trim());
                        existing.assignedDriverId = selectedDriver.id;
                        existing.assignedDriverName = selectedDriver.name;
                        existing.assignedConductorId = selectedConductor.id;
                        existing.assignedConductorName = selectedConductor.name;
                        existing.defaultRoute = route;
                        existing.status = status;
                        store.updateBus(existing);
                        ScaffoldMessenger.of(context).showSnackBar(buildSnack('Bus updated successfully', SnackType.success));
                      }
                      Navigator.pop(context);
                    },
                    child: Text(existing == null ? 'Add Bus' : 'Save Changes'),
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
        var list = store.buses.where((b) {
          final matchesSearch = _search.isEmpty || b.busNo.toLowerCase().contains(_search.toLowerCase()) || b.plateNumber.toLowerCase().contains(_search.toLowerCase());
          final matchesStatus = _statusFilter == null || b.status == _statusFilter;
          return matchesSearch && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Bus Management',
                subtitle: 'Manage fleet and crew assignments',
                action: PrimaryButton(label: 'Add Bus', onPressed: () => _openBusForm(context, store)),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        SearchField(hint: 'Search bus or plate number', onChanged: (v) => setState(() => _search = v)),
                        FilterDropdown<BusStatus?>(
                          value: _statusFilter,
                          items: [null, ...BusStatus.values],
                          labelOf: (v) => v == null ? 'All Statuses' : v.label,
                          onChanged: (v) => setState(() => _statusFilter = v),
                        ),
                        Text('${list.length} result${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                      const SizedBox(height: 16),
                      if (list.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No buses found.', style: TextStyle(color: AppColors.textMuted))))
                      else
                        LayoutBuilder(builder: (context, c) {
                          if (c.maxWidth < 760) {
                            return Column(children: list.asMap().entries.map((e) => FadeInUp(delayMs: e.key * 40, child: _BusCard(bus: e.value, onEdit: () => _openBusForm(context, store, existing: e.value), onDelete: () => _deleteBus(context, store, e.value)))).toList());
                          }
                          return AppDataTable(
                            columns: const [
                              AppTableColumn('Bus No.', 80),
                              AppTableColumn('Plate Number', 120),
                              AppTableColumn('Capacity', 90),
                              AppTableColumn('Assigned Driver', 150),
                              AppTableColumn('Assigned Conductor', 160),
                              AppTableColumn('Default Route', 160),
                              AppTableColumn('Status', 110),
                              AppTableColumn('Actions', 90),
                            ],
                            rows: list.map((b) {
                              return [
                                Text(b.busNo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                Text(b.plateNumber, style: const TextStyle(fontSize: 12.5)),
                                Text('${b.capacity}', style: const TextStyle(fontSize: 12.5)),
                                Text(b.assignedDriverName, style: const TextStyle(fontSize: 12.5)),
                                Text(b.assignedConductorName, style: const TextStyle(fontSize: 12.5)),
                                Text(b.defaultRoute, style: const TextStyle(fontSize: 12.5)),
                                StatusChip(label: b.status.label, color: busStatusColor(b.status)),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit_outlined, size: 17), onPressed: () => _openBusForm(context, store, existing: b)),
                                  const SizedBox(width: 14),
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger), onPressed: () => _deleteBus(context, store, b)),
                                ]),
                              ];
                            }).toList(),
                          );
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

  void _deleteBus(BuildContext context, DataStore store, Bus b) async {
    final ok = await confirmDelete(context, title: 'Delete Bus ${b.busNo}?', message: 'This will permanently remove this bus record. This action cannot be undone.');
    if (ok) {
      store.deleteBus(b.id);
      ScaffoldMessenger.of(context).showSnackBar(buildSnack('Bus ${b.busNo} deleted', SnackType.error));
    }
  }
}

class _BusCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _BusCard({required this.bus, required this.onEdit, required this.onDelete});

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
            Text('Bus ${bus.busNo} \u2022 ${bus.plateNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            StatusChip(label: bus.status.label, color: busStatusColor(bus.status)),
          ]),
          const SizedBox(height: 6),
          Text('Capacity: ${bus.capacity} \u2022 Route: ${bus.defaultRoute}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          Text('Driver: ${bus.assignedDriverName}', style: const TextStyle(fontSize: 12.5)),
          Text('Conductor: ${bus.assignedConductorName}', style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 8),
          Row(children: [
            TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
            TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger), label: const Text('Delete', style: TextStyle(color: AppColors.danger))),
          ]),
        ],
      ),
    );
  }
}