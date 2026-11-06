import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/category/categories_screen.dart';
import 'screens/ledger/invite_member_screen.dart';
import 'screens/onboarding/create_join_ledger_screen.dart';
import 'screens/savings/add_contribution_screen.dart';
import 'screens/savings/add_edit_savings_goal_screen.dart';
import 'screens/savings/savings_goal_detail_screen.dart';
import 'screens/shell/main_shell.dart';
import 'screens/transaction/add_edit_transaction_screen.dart';
import 'screens/transaction/transaction_detail_screen.dart';
import 'services/auth_service.dart';
import 'state/app_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.ensureGoogleSignInInitialized();
  runApp(const SiMoneyApp());
}

class SiMoneyApp extends StatelessWidget {
  const SiMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiMoney',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: SplashScreen.routeName,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case SplashScreen.routeName:
            page = const SplashScreen();
          case LoginScreen.routeName:
            page = const LoginScreen();
          case CreateJoinLedgerScreen.routeName:
            page = const CreateJoinLedgerScreen();
          case MainShell.routeName:
            page = const MainShell();
          case InviteMemberScreen.routeName:
            page = const InviteMemberScreen();
          case CategoriesScreen.routeName:
            page = const CategoriesScreen();
          case AnalyticsScreen.routeName:
            final args = settings.arguments;
            page = AnalyticsScreen(
              type: args is TransactionType ? args : TransactionType.expense,
            );
          case AddEditTransactionScreen.routeName:
            final args = settings.arguments;
            if (args is String) {
              page = AddEditTransactionScreen(transactionId: args);
            } else if (args is TransactionType) {
              page = AddEditTransactionScreen(initialType: args);
            } else {
              page = const AddEditTransactionScreen();
            }
          case TransactionDetailScreen.routeName:
            page = TransactionDetailScreen(
              transactionId: settings.arguments as String? ?? '',
            );
          case AddEditSavingsGoalScreen.routeName:
            final args = settings.arguments;
            page = AddEditSavingsGoalScreen(
              goalId: args is String ? args : null,
            );
          case SavingsGoalDetailScreen.routeName:
            page = SavingsGoalDetailScreen(
              goalId: settings.arguments as String? ?? '',
            );
          case AddContributionScreen.routeName:
            final args = settings.arguments;
            if (args is AddContributionArgs) {
              page = AddContributionScreen(
                goalId: args.goalId,
                initialType: args.type,
              );
            } else {
              page = const LoginScreen();
            }
          default:
            page = const LoginScreen();
        }

        return PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final user = AuthService.instance.currentFirebaseUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      return;
    }

    try {
      await AuthService.instance.bootstrapSession();
      if (!mounted) return;
      final dest = appStore.hasLedger
          ? MainShell.routeName
          : CreateJoinLedgerScreen.routeName;
      Navigator.of(context).pushReplacementNamed(dest);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/logo-simoney.png',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 16),
            Text(
              'SiMoney',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keuangan bersama, sederhana.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
