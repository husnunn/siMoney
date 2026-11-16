import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simoney/models/models.dart';
import 'package:simoney/screens/savings/add_edit_savings_goal_screen.dart';
import 'package:simoney/screens/savings/savings_goal_detail_screen.dart';
import 'package:simoney/screens/savings/savings_list_screen.dart';
import 'package:simoney/state/app_store.dart';
import 'package:simoney/theme/app_colors.dart';

// Behaviour tests for the savings screens. They use the default test font, so
// they run on a wide surface and assert on content and interaction rather
// than on pixel layout.

ThemeData _theme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  TextStyle s(TextStyle? b, double size, FontWeight w) =>
      (b ?? const TextStyle()).copyWith(fontSize: size, fontWeight: w);
  final t = base.textTheme;
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: t.copyWith(
      displayLarge: s(t.displayLarge, 32, FontWeight.w700),
      displaySmall: s(t.displaySmall, 28, FontWeight.w700),
      titleLarge: s(t.titleLarge, 24, FontWeight.w700),
      titleMedium: s(t.titleMedium, 18, FontWeight.w600),
      titleSmall: s(t.titleSmall, 16, FontWeight.w600),
      bodyMedium: s(t.bodyMedium, 14, FontWeight.w400),
      bodySmall: s(t.bodySmall, 12, FontWeight.w400),
      labelLarge: s(t.labelLarge, 14, FontWeight.w600),
      labelMedium: s(t.labelMedium, 12, FontWeight.w600),
      labelSmall: s(t.labelSmall, 11, FontWeight.w700),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget home, {double height = 6000}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(1400, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: _theme(), home: home));
  await tester.pump(const Duration(milliseconds: 400));
}

DateTime _daysFromToday(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

SavingsGoal _target() => SavingsGoal(
      id: 'g1',
      name: 'DP Rumah',
      targetAmount: 150000000,
      targetDate: _daysFromToday(1096),
      status: SavingsGoalStatus.active,
      createdAt: _daysFromToday(-10),
      createdBy: 'u1',
      adjustForInflation: true,
      priceDate: _daysFromToday(-10),
    );

SavingsGoal _periodic() => SavingsGoal(
      id: 'p1',
      name: 'Celengan mingguan',
      targetAmount: 0,
      status: SavingsGoalStatus.active,
      createdAt: _daysFromToday(-21),
      createdBy: 'u1',
      kind: SavingsGoalKind.periodic,
      periodicAmount: 120000,
      periodUnit: PeriodUnit.week,
      startDate: _daysFromToday(-21),
    );

SavingsContribution _deposit(String id, String goalId, int amount, int daysAgo) {
  return SavingsContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    date: _daysFromToday(-daysAgo),
    note: '',
    type: ContributionType.deposit,
    source: ContributionSource.external,
    createdBy: 'u1',
    createdByName: 'Rani',
  );
}

void main() {
  setUp(() {
    appStore.savingsGoals = [_target(), _periodic()];
    appStore.savingsContributions = [
      _deposit('c1', 'g1', 2000000, 3),
      _deposit('c2', 'p1', 120000, 1),
      _deposit('c3', 'p1', 120000, 8),
    ];
  });

  tearDown(() {
    appStore.savingsGoals = [];
    appStore.savingsContributions = [];
  });

  group('savings list', () {
    testWidgets('has two tabs and the add button follows the active tab', (tester) async {
      await _pump(tester, const SavingsListScreen(), height: 1200);

      expect(find.text('Target Akhir'), findsOneWidget);
      expect(find.text('Target Berkala'), findsOneWidget);
      expect(find.text('Target akhir'), findsOneWidget, reason: 'add button label');
      expect(find.text('DP Rumah'), findsWidgets);
      expect(find.text('Celengan mingguan'), findsNothing);

      await tester.tap(find.text('Target Berkala'));
      await tester.pumpAndSettle();

      expect(find.text('Target berkala'), findsOneWidget, reason: 'add button label');
      expect(find.text('Celengan mingguan'), findsWidgets);
      expect(find.text('DP Rumah'), findsNothing);
      expect(find.text('Rp120.000 per minggu'), findsOneWidget);
    });

    testWidgets('shows an explanation when there are no periodic goals', (tester) async {
      appStore.savingsGoals = [_target()];
      await _pump(tester, const SavingsListScreen(), height: 1200);
      await tester.tap(find.text('Target Berkala'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada target berkala'), findsOneWidget);
    });
  });

  group('new goal form', () {
    testWidgets('periodic form computes every period live', (tester) async {
      await _pump(
        tester,
        const AddEditSavingsGoalScreen(initialKind: SavingsGoalKind.periodic),
        height: 2400,
      );

      expect(
        find.textContaining('Isi nominal per periode'),
        findsOneWidget,
        reason: 'hint before an amount is typed',
      );

      // fields: name, amount, expected return
      await tester.enterText(find.byType(TextField).at(1), '120000');
      await tester.pump();

      // 120.000 per week (default unit) = 17.143/day, 521.429/month, 6.257.143/year
      expect(find.text('Rp17.140'), findsOneWidget);
      expect(find.text('Rp120.000'), findsOneWidget);
      expect(find.text('Rp521.400'), findsOneWidget);
      expect(find.text('Rp6.257.100'), findsOneWidget);

      await tester.tap(find.text('Per bulan'));
      await tester.pump();

      // The same 120.000, now per month: 12 months a year.
      expect(find.text('Rp1.440.000'), findsOneWidget);
    });

    testWidgets('a new goal can start as either kind', (tester) async {
      await _pump(tester, const AddEditSavingsGoalScreen(), height: 2400);
      expect(find.text('Target akhir baru'), findsOneWidget);
      expect(find.text('Menabung setiap'), findsNothing);

      await tester.tap(find.text('Target Berkala'));
      await tester.pump();
      expect(find.text('Target berkala baru'), findsOneWidget);
      expect(find.text('Menabung setiap'), findsOneWidget);
    });

    testWidgets('editing an existing goal does not offer a kind switch', (tester) async {
      await _pump(tester, const AddEditSavingsGoalScreen(goalId: 'p1'), height: 2400);
      expect(find.text('Edit target'), findsOneWidget);
      expect(find.text('Target Akhir'), findsNothing);
      expect(find.text('Menabung setiap'), findsOneWidget);
    });

    testWidgets('editing a target shows its plan to the deadline', (tester) async {
      await _pump(tester, const AddEditSavingsGoalScreen(goalId: 'g1'), height: 2600);
      expect(find.textContaining('kamu perlu menabung'), findsOneWidget);
      expect(find.textContaining('karena inflasi'), findsWidgets);
    });
  });

  group('goal detail', () {
    testWidgets('a target shows plan, chart, tenors and the reach calculator', (tester) async {
      await _pump(tester, const SavingsGoalDetailScreen(goalId: 'g1'));
      expect(find.text('Target Akhir'), findsOneWidget);
      expect(find.text('Rencana Setoran'), findsOneWidget);
      expect(find.text('Proyeksi Saldo vs Harga Target'), findsOneWidget);
      expect(find.text('Kalau Tenornya Berbeda'), findsOneWidget);
      expect(find.text('Kapan Tercapai?'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      // one row per tenor
      for (final y in [1, 2, 3, 4, 5, 10]) {
        expect(find.text('$y tahun'), findsOneWidget);
      }
    });

    testWidgets('a periodic goal shows equivalents, projections and consistency',
        (tester) async {
      await _pump(tester, const SavingsGoalDetailScreen(goalId: 'p1'));
      expect(find.text('Target Berkala'), findsOneWidget);
      expect(find.text('Rp120.000 per minggu'), findsWidgets);
      expect(find.text('Setara Dengan'), findsOneWidget);
      expect(find.text('Proyeksi Tabungan'), findsOneWidget);
      expect(find.text('Konsistensi'), findsOneWidget);
      expect(find.text('Dalam 1 tahun'), findsOneWidget);
      expect(find.text('Dalam 10 tahun'), findsOneWidget);
      // The one-tap deposit button carries the fixed amount.
      expect(find.text('Setor Rp120 rb'), findsOneWidget);
      // No chart, tenor table or reach calculator for a goal without an end.
      expect(find.text('Kapan Tercapai?'), findsNothing);
      expect(find.text('Kalau Tenornya Berbeda'), findsNothing);
    });

    testWidgets('a target without a deadline asks for one', (tester) async {
      appStore.savingsGoals = [
        SavingsGoal(
          id: 'g9',
          name: 'Tanpa tenggat',
          targetAmount: 5000000,
          status: SavingsGoalStatus.active,
          createdAt: _daysFromToday(-5),
          createdBy: 'u1',
        ),
      ];
      await _pump(tester, const SavingsGoalDetailScreen(goalId: 'g9'));
      expect(find.textContaining('Tambahkan tenggat'), findsOneWidget);
      expect(find.text('Rencana Setoran'), findsNothing);
    });

    testWidgets('an unknown goal shows a message instead of crashing', (tester) async {
      await _pump(tester, const SavingsGoalDetailScreen(goalId: 'missing'), height: 800);
      expect(find.text('Target tidak ditemukan'), findsOneWidget);
    });
  });
}
