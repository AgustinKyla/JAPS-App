// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  String _search = '';

  void _openRouteForm(BuildContext context, DataStore store, {BusRoute? existing}) {
    final originCtrl = TextEditingController(text: existing?.origin ?? '');
    final destCtrl = TextEditingController(text: existing?.destination ?? '');
    final distCtrl = TextEditingController(text: existing?.distanceKm.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showFormDialog(
      context: context,
      title: existing == null ? 'Add Route' : 'Edit Route',
      icon: Icons.alt_route_rounded,
      bodyBuilder: (ctx) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(label: 'Origin', controller: originCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              AppTextField(label: 'Destination', controller: destCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
              AppTextField(
                label: 'Distance (km)',
                controller: distCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter a valid distance';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (existing == null) {
                      store.addRoute(BusRoute(id: '', origin: originCtrl.text.trim(), destination: destCtrl.text.trim(), distanceKm: double.parse(distCtrl.text.trim())));
                      ScaffoldMessenger.of(context).showSnackBar(buildSnack('Route added successfully', SnackType.success));
                    } else {
                      existing.origin = originCtrl.text.trim();
                      existing.destination = destCtrl.text.trim();
                      existing.distanceKm = double.parse(distCtrl.text.trim());
                      store.updateRoute(existing);
                      ScaffoldMessenger.of(context).showSnackBar(buildSnack('Route updated successfully', SnackType.success));
                    }
                    Navigator.pop(context);
                  },
                  child: Text(existing == null ? 'Add Route' : 'Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final list = store.routes.where((r) => _search.isEmpty || r.origin.toLowerCase().contains(_search.toLowerCase()) || r.destination.toLowerCase().contains(_search.toLowerCase())).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: 'Routes', subtitle: 'Manage bus routes and distances', action: PrimaryButton(label: 'Add Route', onPressed: () => _openRouteForm(context, store))),
              const SizedBox(height: 16),
              FadeInUp(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchField(hint: 'Search origin or destination', onChanged: (v) => setState(() => _search = v)),
                      const SizedBox(height: 16),
                      if (list.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No routes found.', style: TextStyle(color: AppColors.textMuted))))
                      else
                        LayoutBuilder(builder: (context, c) {
                          if (c.maxWidth < 640) {
                            return Column(
                              children: list.asMap().entries.map((e) {
                                final r = e.value;
                                return FadeInUp(
                                  delayMs: e.key * 40,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                    child: Row(children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('${r.distanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openRouteForm(context, store, existing: r)),
                                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger), onPressed: () => _deleteRoute(context, store, r)),
                                    ]),
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          return AppDataTable(
                            columns: const [
                              AppTableColumn('Origin', 180),
                              AppTableColumn('Destination', 180),
                              AppTableColumn('Distance (km)', 130),
                              AppTableColumn('Actions', 90),
                            ],
                            rows: list.map((r) {
                              return [
                                Text(r.origin, style: const TextStyle(fontSize: 12.5)),
                                Text(r.destination, style: const TextStyle(fontSize: 12.5)),
                                Text(r.distanceKm.toStringAsFixed(2), style: const TextStyle(fontSize: 12.5)),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit_outlined, size: 17), onPressed: () => _openRouteForm(context, store, existing: r)),
                                  const SizedBox(width: 14),
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger), onPressed: () => _deleteRoute(context, store, r)),
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

  void _deleteRoute(BuildContext context, DataStore store, BusRoute r) async {
    final ok = await confirmDelete(context, title: 'Delete Route?', message: 'Delete route "${r.label}"? Buses assigned to this route will not be updated automatically.');
    if (ok) {
      store.deleteRoute(r.id);
      ScaffoldMessenger.of(context).showSnackBar(buildSnack('Route deleted', SnackType.error));
    }
  }
}
