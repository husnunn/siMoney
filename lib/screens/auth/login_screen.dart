import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primary_button.dart';
import '../onboarding/create_join_ledger_screen.dart';
import '../shell/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AuthService.messageFor(error))),
    );
  }

  void _goAfterAuth() {
    final dest = appStore.hasLedger
        ? MainShell.routeName
        : CreateJoinLedgerScreen.routeName;
    Navigator.of(context).pushReplacementNamed(dest);
  }

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      _goAfterAuth();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/icon/logo-simoney.png',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'SiMoney',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Catat keuangan bersama dengan sederhana.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.outline),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: _loading
                    ? 'Menghubungkan Google…'
                    : 'Lanjutkan dengan Google',
                onPressed: _loading ? null : _googleSignIn,
                isLoading: _loading,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Dengan masuk, kamu menyetujui penggunaan akun Google untuk autentikasi.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
