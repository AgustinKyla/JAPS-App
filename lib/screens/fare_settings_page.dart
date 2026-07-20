import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class FareSettingsPage extends StatefulWidget {
  const FareSettingsPage({super.key});

  @override
  State<FareSettingsPage> createState() => _FareSettingsPageState();
}

class _FareSettingsPageState extends State<FareSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _minFareCtrl;
  late TextEditingController _baseDistCtrl;
  late TextEditingController _rateCtrl;
  late Map<String, TextEditingController> _categoryCtrls;
  final _previewDistCtrl = TextEditingController(text: '10');
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _previewDistCtrl.addListener(() => setState(() {}));
  }

  void _initControllers(FareSettings f) {
    if (_init) return;
    _minFareCtrl = TextEditingController(text: f.minimumFare.toStringAsFixed(2));
    _baseDistCtrl = TextEditingController(text: f.baseDistanceKm.toStringAsFixed(2));
    _rateCtrl = TextEditingController(text: f.ratePerKm.toStringAsFixed(4));
    _categoryCtrls = {for (var e in f.categoryRates.entries) e.key: TextEditingController(text: e.value.toStringAsFixed(2))};
    _init = true;
  }

  @override
  void dispose() {
    _previewDistCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DataScope.of(context);
    _initControllers(store.fareSettings);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'Fare Settings', subtitle: 'Configure global minimum fare, per-km rate, and category multipliers'),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 900;
                final formCard = FadeInUp(
                  child: AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Base Fare Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          const Text('Used by conductors to compute ticket price', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          Wrap(spacing: 14, runSpacing: 0, children: [
                            SizedBox(width: 200, child: AppTextField(label: 'Minimum Fare (\u20B1)', controller: _minFareCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numValidator)),
                            SizedBox(width: 200, child: AppTextField(label: 'Base Distance (km)', controller: _baseDistCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numValidator)),
                            SizedBox(width: 200, child: AppTextField(label: 'Rate per km (\u20B1)', controller: _rateCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numValidator)),
                          ]),
                          const SizedBox(height: 10),
                          const Text('Category Rates (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          const Text('Enter percentage of base fare per passenger type: 100 = full price, 20 = 80% discount', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          const SizedBox(height: 12),
                          ..._categoryCtrls.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(children: [
                                  SizedBox(width: 140, child: Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  Expanded(child: AppTextField(label: '', controller: e.value, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _numValidator)),
                                ]),
                              )),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Save Settings'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                              onPressed: () => _save(context, store),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final sideCard = FadeInUp(
                  delayMs: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [Icon(Icons.info_outline_rounded, size: 17, color: AppColors.primary), SizedBox(width: 6), Text('How it works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))]),
                            const SizedBox(height: 10),
                            const Text('Base Fare Formula', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            const Text('If distance \u2264 base_distance_km: min_fare\nelse: min_fare + (distance - base_distance_km) \u00D7 rate_per_km', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            const Text('Final Fare', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            const Text('base_fare \u00D7 (category_rate / 100)', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [Icon(Icons.calculate_outlined, size: 17, color: AppColors.primary), SizedBox(width: 6), Text('Fare Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))]),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Test distance (km)',
                              controller: _previewDistCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            ),
                            ...store.fareSettings.categoryRates.keys.map((cat) {
                              final dist = double.tryParse(_previewDistCtrl.text) ?? 0;
                              final fare = store.fareSettings.fareFor(cat, dist);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text(cat, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                  Text(fmtPeso(fare), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                ]),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: formCard), const SizedBox(width: 16), Expanded(flex: 2, child: sideCard)]);
                }
                return Column(children: [formCard, const SizedBox(height: 16), sideCard]);
              }),
            ],
          ),
        );
      },
    );
  }

  String? _numValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (double.tryParse(v) == null) return 'Invalid number';
    return null;
  }

  void _save(BuildContext context, DataStore store) {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(buildSnack('Please fix the errors before saving', SnackType.error));
      return;
    }
    final updated = FareSettings(
      minimumFare: double.parse(_minFareCtrl.text),
      baseDistanceKm: double.parse(_baseDistCtrl.text),
      ratePerKm: double.parse(_rateCtrl.text),
      categoryRates: {for (var e in _categoryCtrls.entries) e.key: double.parse(e.value.text)},
      effectiveDate: DateTime.now(),
    );
    store.updateFareSettings(updated);
    ScaffoldMessenger.of(context).showSnackBar(buildSnack('Fare settings saved successfully', SnackType.success));
  }
}

