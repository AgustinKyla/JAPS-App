// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../theme/app_theme.dart';
import '../models/models.dart';

enum SnackType { success, error, info, warning }

SnackBar buildSnack(String message, SnackType type) {
  Color color;
  IconData icon;
  switch (type) {
    case SnackType.success:
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
      break;
    case SnackType.error:
      color = AppColors.danger;
      icon = Icons.error_rounded;
      break;
    case SnackType.warning:
      color = AppColors.warning;
      icon = Icons.warning_rounded;
      break;
    case SnackType.info:
      color = AppColors.primary;
      icon = Icons.info_rounded;
      break;
  }
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: color,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Color remStatusColor(RemittanceStatus s) {
  switch (s) {
    case RemittanceStatus.pending:
      return AppColors.warning;
    case RemittanceStatus.approved:
      return AppColors.success;
    case RemittanceStatus.rejected:
      return AppColors.danger;
  }
}

Color busStatusColor(BusStatus s) {
  switch (s) {
    case BusStatus.active:
      return AppColors.success;
    case BusStatus.maintenance:
      return AppColors.warning;
    case BusStatus.inactive:
      return AppColors.textMuted;
  }
}

Color userStatusColor(UserStatus s) => s == UserStatus.active ? AppColors.success : AppColors.textMuted;

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add_rounded, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const PageHeader({super.key, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 560;
      final titleCol = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      );
      if (!narrow) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleCol),
            ?action,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleCol,
          if (action != null) ...[const SizedBox(height: 12), SizedBox(width: double.infinity, child: action!)],
        ],
      );
    });
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.textMuted),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
        ),
      ),
    );
  }
}

class FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final double width;
  const FilterDropdown({super.key, required this.value, required this.items, required this.labelOf, required this.onChanged, this.width = 170});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class AppTableColumn {
  final String label;
  final double width;
  const AppTableColumn(this.label, this.width);
}

class AppDataTable extends StatelessWidget {
  final List<AppTableColumn> columns;
  final List<List<Widget>> rows;
  const AppDataTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final minTotalWidth = columns.fold<double>(0, (a, c) => a + c.width);
      final availableWidth = constraints.maxWidth;
      final fitsWithoutScroll = availableWidth.isFinite && availableWidth >= minTotalWidth;

      final widths = <double>[];
      if (fitsWithoutScroll) {
        final lastWidth = columns.last.width;
        final flexWidth = minTotalWidth - lastWidth;
        final extraWidth = availableWidth - minTotalWidth;
        for (int i = 0; i < columns.length; i++) {
          if (i == columns.length - 1) {
            widths.add(lastWidth);
          } else {
            final share = flexWidth > 0 ? columns[i].width / flexWidth : 0.0;
            widths.add(columns[i].width + extraWidth * share);
          }
        }
      } else {
        widths.addAll(columns.map((c) => c.width));
      }
      final tableWidth = fitsWithoutScroll ? availableWidth : minTotalWidth;

      final table = SizedBox(
        width: tableWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 1.3))),
              child: Row(
                children: [
                  for (int i = 0; i < columns.length; i++)
                    SizedBox(
                      width: widths[i],
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          columns[i].label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('No records to show.', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              )
            else
              for (int i = 0; i < rows.length; i++)
                _AppTableRow(cells: rows[i], widths: widths, isLast: i == rows.length - 1),
          ],
        ),
      );

      if (fitsWithoutScroll) return table;
      return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
    });
  }
}

class _AppTableRow extends StatefulWidget {
  final List<Widget> cells;
  final List<double> widths;
  final bool isLast;
  const _AppTableRow({required this.cells, required this.widths, required this.isLast});

  @override
  State<_AppTableRow> createState() => _AppTableRowState();
}

class _AppTableRowState extends State<_AppTableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _hover ? AppColors.bg : Colors.transparent,
          border: widget.isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.cells.length && i < widget.widths.length; i++)
              SizedBox(
                width: widget.widths[i],
                child: Padding(padding: const EdgeInsets.only(right: 10), child: widget.cells[i]),
              ),
          ],
        ),
      ),
    );
  }
}

// Confirm delete dialog
Future<bool> confirmDelete(BuildContext context, {required String title, required String message}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
      ]),
      content: Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, elevation: 0),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// Generic form dialog shell
Future<T?> showFormDialog<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget Function(BuildContext) bodyBuilder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: AppColors.primary, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 6),
                const Divider(),
                const SizedBox(height: 10),
                Builder(builder: bodyBuilder),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? hintText;
  final bool readOnly;
  final VoidCallback? onTap;


  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.hintText,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            obscureText: obscureText,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  const AppDropdownField({super.key, required this.label, required this.value, required this.items, required this.labelOf, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Animated entrance wrapper for cards/lists
class FadeInUp extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const FadeInUp({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: Curves.easeOut,
      builder: (context, v, c) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: c),
        );
      },
      child: child,
    );
  }
}