import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/app_store.dart';
import '../../services/auth_service.dart';
import '../../services/csv_export_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';
import '../auth/login_screen.dart';
import '../category/categories_screen.dart';
import '../onboarding/create_join_ledger_screen.dart';
import '../ledger/invite_member_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _ledgerActionLoading = false;
  String? _loadingLedgerId;
  bool _csvExportLoading = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final user = appStore.currentUser;
        final ledger = appStore.currentLedger;
        final activeLedgerId = ledger?.id;
        final ledgers = appStore.ledgers;

        return Scaffold(
          appBar: AppBar(title: const Text('Akun')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.mutedSurface,
                    child: Text(
                      user?.initials ?? '?',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Pengguna',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (ledgers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Buku kas',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...List<Widget>.generate(ledgers.length, (index) {
                  final l = ledgers[index];
                  final isActive = l.id == activeLedgerId;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.menu_book_outlined,
                          color: isActive ? AppColors.accent : null,
                        ),
                        title: Text(l.name),
                        subtitle: Text('${l.memberIds.length} anggota'),
                        trailing:
                            _ledgerActionLoading && _loadingLedgerId == l.id
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : isActive
                                    ? const Icon(Icons.check_circle_outline,
                                        color: AppColors.accent)
                                    : const Icon(Icons.chevron_right),
                        onTap: isActive
                            ? null
                            : _ledgerActionLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _ledgerActionLoading = true;
                                      _loadingLedgerId = l.id;
                                    });
                                    try {
                                      await appStore.switchLedger(l.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Buku kas aktif diperbarui',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AuthService.messageFor(e),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _ledgerActionLoading = false;
                                          _loadingLedgerId = null;
                                        });
                                      }
                                    }
                                  },
                      ),
                      if (index < ledgers.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                  label: 'Buat / Gabung buku kas',
                  icon: Icons.add_circle_outlined,
                  onPressed: _ledgerActionLoading
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(
                            CreateJoinLedgerScreen.routeName,
                          );
                        },
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Belum ada buku kas',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: 'Buat / Gabung buku kas',
                  icon: Icons.add_circle_outlined,
                  onPressed: _ledgerActionLoading
                      ? null
                      : () {
                          Navigator.of(context).pushNamed(
                            CreateJoinLedgerScreen.routeName,
                          );
                        },
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pengaturan',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add_outlined),
                title: const Text('Undang anggota'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(InviteMemberScreen.routeName);
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined),
                title: const Text('Kelola kategori'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(CategoriesScreen.routeName);
                },
              ),
              if (appStore.currentLedger != null) ...[
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Export CSV'),
                  subtitle: Text(
                    'Semua transaksi buku kas aktif',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  trailing: _csvExportLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _csvExportLoading
                      ? null
                      : () async {
                          setState(() => _csvExportLoading = true);
                          try {
                            final txs = appStore.transactions;
                            if (txs.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Belum ada transaksi untuk diekspor'),
                                ),
                              );
                              return;
                            }

                            final csv =
                                CsvExportService.buildAllTimeTransactionsCsv(txs);
                            final ledgerName =
                                appStore.currentLedger?.name ?? 'Buku kas';
                            await SharePlus.instance.share(
                              ShareParams(
                                text: csv,
                                subject: 'SiMoney - CSV $ledgerName',
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthService.messageFor(e)),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _csvExportLoading = false);
                            }
                          }
                        },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.logout,
                  color: AppColors.destructive,
                ),
                title: Text(
                  'Keluar',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  await AuthService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginScreen.routeName,
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
