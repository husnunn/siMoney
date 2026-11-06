import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/csv_export_action.dart';
import '../../widgets/avatar_monogram.dart';
import '../../widgets/bordered_list_card.dart';
import '../../widgets/glow_hero_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
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

  Future<void> _switchLedger(String ledgerId) async {
    setState(() {
      _ledgerActionLoading = true;
      _loadingLedgerId = ledgerId;
    });
    try {
      await appStore.switchLedger(ledgerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buku kas aktif diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.messageFor(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _ledgerActionLoading = false;
          _loadingLedgerId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appStore,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final user = appStore.currentUser;
        final ledger = appStore.currentLedger;
        final ledgers = appStore.ledgers;
        final isOwner = ledger != null && user != null && ledger.ownerId == user.id;

        return Scaffold(
          appBar: AppBar(title: const Text('Akun')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _ProfileHeroSection(
                userName: user?.name ?? 'Pengguna',
                userEmail: user?.email ?? '',
                userInitials: user?.initials ?? '?',
                ledgerMemberCount: ledger?.memberIds.length ?? 0,
                ledgersCount: ledgers.length,
                isOwner: isOwner,
                showRoleBadge: ledger != null,
              ),
              _LedgerListSection(
                ledgers: ledgers,
                activeLedgerId: ledger?.id,
                ledgerActionLoading: _ledgerActionLoading,
                loadingLedgerId: _loadingLedgerId,
                onSwitchLedger: _switchLedger,
                onCreateOrJoin: () => Navigator.of(context)
                    .pushNamed(CreateJoinLedgerScreen.routeName),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Pengaturan'),
              const SizedBox(height: AppSpacing.sm),
              _SettingsSection(
                hasLedger: appStore.currentLedger != null,
                csvExportLoading: _csvExportLoading,
                onInviteMember: () => Navigator.of(context)
                    .pushNamed(InviteMemberScreen.routeName),
                onManageCategories: () => Navigator.of(context)
                    .pushNamed(CategoriesScreen.routeName),
                onExportCsv: () => exportTransactionsCsv(
                  context,
                  setLoading: (loading) {
                    if (mounted) {
                      setState(() => _csvExportLoading = loading);
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Keluar',
                  style: textTheme.titleMedium?.copyWith(color: AppColors.error),
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

class _ProfileHeroSection extends StatelessWidget {
  const _ProfileHeroSection({
    required this.userName,
    required this.userEmail,
    required this.userInitials,
    required this.ledgerMemberCount,
    required this.ledgersCount,
    required this.isOwner,
    required this.showRoleBadge,
  });

  final String userName;
  final String userEmail;
  final String userInitials;
  final int ledgerMemberCount;
  final int ledgersCount;
  final bool isOwner;
  final bool showRoleBadge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlowHeroCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarMonogram(initials: userInitials, radius: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(userEmail, style: textTheme.bodySmall),
                    if (showRoleBadge) ...[
                      const SizedBox(height: 4),
                      _RoleBadge(isOwner: isOwner),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickStat(
                  label: 'Buku kas aktif',
                  value: '$ledgersCount',
                ),
              ),
              Expanded(
                child: _QuickStat(
                  label: 'Kolaborator',
                  value: '$ledgerMemberCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerListSection extends StatelessWidget {
  const _LedgerListSection({
    required this.ledgers,
    required this.activeLedgerId,
    required this.ledgerActionLoading,
    required this.loadingLedgerId,
    required this.onSwitchLedger,
    required this.onCreateOrJoin,
  });

  final List<Ledger> ledgers;
  final String? activeLedgerId;
  final bool ledgerActionLoading;
  final String? loadingLedgerId;
  final Future<void> Function(String ledgerId) onSwitchLedger;
  final VoidCallback onCreateOrJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (ledgers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Belum ada buku kas', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Buat / Gabung buku kas',
            icon: Icons.add_circle_outlined,
            onPressed: ledgerActionLoading ? null : onCreateOrJoin,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Buku Kas'),
        const SizedBox(height: AppSpacing.sm),
        BorderedListCard(
          children: List<Widget>.generate(ledgers.length, (index) {
            final l = ledgers[index];
            final isActive = l.id == activeLedgerId;
            final row = ListTile(
              contentPadding: EdgeInsets.only(
                left: isActive ? AppSpacing.md - 4 : AppSpacing.md,
                right: AppSpacing.md,
              ),
              tileColor: isActive ? AppColors.surfaceContainerHigh : null,
              leading: Icon(
                Icons.menu_book_outlined,
                color: isActive ? AppColors.primary : null,
              ),
              title: Text(l.name),
              subtitle: Text('${l.memberIds.length} anggota'),
              trailing: ledgerActionLoading && loadingLedgerId == l.id
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : isActive
                      ? const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                        )
                      : const Icon(Icons.chevron_right),
              onTap: isActive || ledgerActionLoading
                  ? null
                  : () => onSwitchLedger(l.id),
            );
            if (!isActive) return row;
            return Row(
              children: [
                Container(width: 4, color: AppColors.primary),
                Expanded(child: row),
              ],
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Buat / Gabung buku kas',
          icon: Icons.add_circle_outlined,
          onPressed: ledgerActionLoading ? null : onCreateOrJoin,
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.hasLedger,
    required this.csvExportLoading,
    required this.onInviteMember,
    required this.onManageCategories,
    required this.onExportCsv,
  });

  final bool hasLedger;
  final bool csvExportLoading;
  final VoidCallback onInviteMember;
  final VoidCallback onManageCategories;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BorderedListCard(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: const Icon(Icons.person_add_outlined),
          title: const Text('Undang anggota'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onInviteMember,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          leading: const Icon(Icons.category_outlined),
          title: const Text('Kelola kategori'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onManageCategories,
        ),
        if (hasLedger)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            leading: const Icon(Icons.share_outlined),
            title: const Text('Export CSV'),
            subtitle: Text(
              'Semua transaksi buku kas aktif',
              style: textTheme.bodySmall,
            ),
            trailing: csvExportLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.ios_share),
            onTap: csvExportLoading ? null : onExportCsv,
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isOwner ? 'Pemilik' : 'Anggota',
        style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: textTheme.titleLarge),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}
