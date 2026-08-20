import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_store.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';

class InviteMemberScreen extends StatelessWidget {
  const InviteMemberScreen({super.key});

  static const routeName = '/invite';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final code = appStore.currentLedger?.inviteCode ?? 'SIMONEY-XXX';
    final members = <AppUser>[
      for (final id in appStore.currentLedger?.memberIds ?? const <String>[])
        ?appStore.userById(id),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Undang anggota')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bagikan kode ini agar orang lain bisa bergabung ke buku kas.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kode undangan',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      code,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Salin kode',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode disalin')),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Bagikan tautan',
                icon: Icons.share_outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('simoney.app/join/$code (mock)'),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Anggota saat ini', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final isOwner =
                        user.id == appStore.currentLedger?.ownerId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.mutedSurface,
                        child: Text(
                          user.initials,
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: isOwner
                          ? Text(
                              'Owner',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
