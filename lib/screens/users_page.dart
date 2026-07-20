// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../data/data_store.dart';
import '../widgets/common_widgets.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String _search = '';
  UserRole? _roleFilter;
  UserStatus? _statusFilter;

  void _openUserForm(BuildContext context, DataStore store, {AppUser? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final passwordCtrl = TextEditingController();
    UserRole role = existing?.role ?? UserRole.driver;
    UserStatus status = existing?.status ?? UserStatus.active;
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showFormDialog(
      context: context,
      title: existing == null ? 'Add User' : 'Edit User',
      icon: Icons.person_add_alt_1_rounded,
      bodyBuilder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Full Name', controller: nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                AppTextField(
                  label: 'Username',
                  controller: usernameCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final dup = store.users.any((u) => u.username.toLowerCase() == v.trim().toLowerCase() && u.id != existing?.id);
                    if (dup) return 'Username already taken';
                    return null;
                  },
                ),
                AppTextField(
                  label: existing == null ? 'Password' : 'New Password',
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  hintText: existing == null ? 'Set this user\'s login password' : 'Leave blank to keep current password',
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setLocal(() => obscurePassword = !obscurePassword),
                  ),
                  validator: (v) {
                    if (existing == null && (v == null || v.isEmpty)) return 'Required';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                AppDropdownField<UserRole>(label: 'Role', value: role, items: UserRole.values, labelOf: (v) => v.label, onChanged: (v) => setLocal(() => role = v ?? role)),
                AppDropdownField<UserStatus>(label: 'Status', value: status, items: UserStatus.values, labelOf: (v) => v.label, onChanged: (v) => setLocal(() => status = v ?? status)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      if (existing == null) {
                        store.addUser(AppUser(
                          id: '',
                          employeeId: '',
                          name: nameCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          password: passwordCtrl.text,
                          role: role,
                          status: status,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(buildSnack('User added successfully', SnackType.success));
                      } else {
                        existing.name = nameCtrl.text.trim();
                        existing.username = usernameCtrl.text.trim();
                        if (passwordCtrl.text.isNotEmpty) existing.password = passwordCtrl.text;
                        existing.role = role;
                        existing.status = status;
                        store.updateUser(existing);
                        ScaffoldMessenger.of(context).showSnackBar(buildSnack('User updated successfully', SnackType.success));
                      }
                      Navigator.pop(context);
                    },
                    child: Text(existing == null ? 'Add User' : 'Save Changes'),
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
        final list = store.users.where((u) {
          final matchesSearch = _search.isEmpty || u.name.toLowerCase().contains(_search.toLowerCase()) || u.username.toLowerCase().contains(_search.toLowerCase()) || u.employeeId.toLowerCase().contains(_search.toLowerCase());
          final matchesRole = _roleFilter == null || u.role == _roleFilter;
          final matchesStatus = _statusFilter == null || u.status == _statusFilter;
          return matchesSearch && matchesRole && matchesStatus;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: 'Users', subtitle: 'Manage secretary, audit teller, conductor and driver accounts', action: PrimaryButton(label: 'Add User', onPressed: () => _openUserForm(context, store))),
              const SizedBox(height: 16),
              FadeInUp(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        SearchField(hint: 'Search name, username, employee ID', onChanged: (v) => setState(() => _search = v)),
                        FilterDropdown<UserRole?>(value: _roleFilter, items: [null, ...UserRole.values], labelOf: (v) => v == null ? 'All Roles' : v.label, onChanged: (v) => setState(() => _roleFilter = v)),
                        FilterDropdown<UserStatus?>(value: _statusFilter, items: [null, ...UserStatus.values], labelOf: (v) => v == null ? 'All Status' : v.label, onChanged: (v) => setState(() => _statusFilter = v)),
                        Text('${list.length} result${list.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ]),
                      const SizedBox(height: 16),
                      if (list.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No users found.', style: TextStyle(color: AppColors.textMuted))))
                      else
                        LayoutBuilder(builder: (context, c) {
                          if (c.maxWidth < 760) {
                            return Column(
                              children: list.asMap().entries.map((e) {
                                final u = e.value;
                                return FadeInUp(
                                  delayMs: e.key * 40,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          StatusChip(label: u.status.label, color: userStatusColor(u.status)),
                                        ]),
                                        Text('${u.employeeId} \u2022 @${u.username}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                                        const SizedBox(height: 4),
                                        StatusChip(label: u.role.label, color: AppColors.primary),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _openUserForm(context, store, existing: u)),
                                          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger), onPressed: () => _deleteUser(context, store, u)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          return AppDataTable(
                            columns: const [
                              AppTableColumn('Employee ID', 110),
                              AppTableColumn('Name', 160),
                              AppTableColumn('Username', 140),
                              AppTableColumn('Role', 120),
                              AppTableColumn('Status', 100),
                              AppTableColumn('Actions', 90),
                            ],
                            rows: list.map((u) {
                              return [
                                Text(u.employeeId, style: const TextStyle(fontSize: 12.5)),
                                Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                Text('@${u.username}', style: const TextStyle(fontSize: 12.5)),
                                StatusChip(label: u.role.label, color: AppColors.primary),
                                StatusChip(label: u.status.label, color: userStatusColor(u.status)),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.edit_outlined, size: 17), onPressed: () => _openUserForm(context, store, existing: u)),
                                  const SizedBox(width: 14),
                                  IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger), onPressed: () => _deleteUser(context, store, u)),
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

  void _deleteUser(BuildContext context, DataStore store, AppUser u) async {
    final ok = await confirmDelete(context, title: 'Delete User?', message: 'Delete ${u.name} (${u.employeeId})? This action cannot be undone.');
    if (ok) {
      store.deleteUser(u.id);
      ScaffoldMessenger.of(context).showSnackBar(buildSnack('${u.name} was deleted', SnackType.error));
    }
  }
}