import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';
import '../shell/main_shell.dart';

class CreateJoinLedgerScreen extends StatefulWidget {
  const CreateJoinLedgerScreen({super.key});

  static const routeName = '/create-join-ledger';

  @override
  State<CreateJoinLedgerScreen> createState() => _CreateJoinLedgerScreenState();
}

class _CreateJoinLedgerScreenState extends State<CreateJoinLedgerScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _joinMode = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_joinMode) {
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Masukkan kode undangan')),
          );
          return;
        }
        await appStore.joinLedger(code);
      } else {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Masukkan nama buku kas')),
          );
          return;
        }
        await appStore.createLedger(name);
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        MainShell.routeName,
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.messageFor(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                _joinMode ? 'Gabung buku kas' : 'Buat buku kas',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _joinMode
                    ? 'Masukkan kode undangan dari pemilik buku kas.'
                    : 'Satu tempat untuk mencatat pemasukan dan pengeluaran bersama.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Buat baru'),
                    icon: Icon(Icons.add_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Gabung'),
                    icon: Icon(Icons.group_add_outlined),
                  ),
                ],
                selected: {_joinMode},
                onSelectionChanged: _loading
                    ? null
                    : (s) {
                        setState(() => _joinMode = s.first);
                      },
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.onPrimary;
                    }
                    return AppColors.onSurface;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return AppColors.surfaceContainer;
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_joinMode) ...[
                Text('Kode undangan', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _codeController,
                  enabled: !_loading,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'SIMONEY-XXX',
                  ),
                ),
              ] else ...[
                Text('Nama buku kas', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  enabled: !_loading,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Kas Keluarga',
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: _joinMode ? 'Gabung' : 'Buat buku kas',
                onPressed: _loading ? null : _submit,
                isLoading: _loading,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
