import 'package:flutter_test/flutter_test.dart';
import 'package:simoney/models/models.dart';
import 'package:simoney/services/savings_repository.dart';
import 'package:simoney/state/app_store.dart';
import 'package:simoney/state/savings_calculator.dart';

/// Records writes instead of talking to Firestore.
class _FakeSavingsRepository extends SavingsRepository {
  final List<SavingsGoal> updatedGoals = [];
  final List<int> depositedAmounts = [];
  SavingsGoal? addedDraft;

  @override
  Future<String> addGoal({
    required String ledgerId,
    required SavingsGoal draft,
  }) async {
    addedDraft = draft;
    return 'new-goal';
  }

  @override
  Future<void> updateGoal({
    required String ledgerId,
    required SavingsGoal goal,
  }) async {
    updatedGoals.add(goal);
  }

  @override
  Future<String> addContribution({
    required String ledgerId,
    required String goalId,
    required int amount,
    required DateTime date,
    required String note,
    required ContributionType type,
    required ContributionSource source,
    required String createdBy,
    required String createdByName,
  }) async {
    depositedAmounts.add(amount);
    return 'new-contribution';
  }
}

DateTime _daysFromToday(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

SavingsGoal _targetGoal({
  int target = 1000000,
  DateTime? deadline,
  bool adjust = false,
  double? rate,
  DateTime? priceDate,
}) {
  return SavingsGoal(
    id: 'g1',
    name: 'Target',
    targetAmount: target,
    targetDate: deadline,
    status: SavingsGoalStatus.active,
    createdAt: _daysFromToday(-400),
    createdBy: 'u1',
    adjustForInflation: adjust,
    inflationRate: rate,
    priceDate: priceDate,
  );
}

SavingsGoal _periodicGoal() {
  return SavingsGoal(
    id: 'p1',
    name: 'Celengan',
    targetAmount: 0,
    status: SavingsGoalStatus.active,
    createdAt: _daysFromToday(-30),
    createdBy: 'u1',
    kind: SavingsGoalKind.periodic,
    periodicAmount: 120000,
    periodUnit: PeriodUnit.week,
    startDate: _daysFromToday(-30),
  );
}

void main() {
  late _FakeSavingsRepository repo;
  late AppStore store;

  setUp(() {
    repo = _FakeSavingsRepository();
    store = AppStore(savingsRepository: repo)
      ..currentUser = const AppUser(id: 'u1', name: 'Rani', email: 'rani@example.com')
      ..currentLedger = const Ledger(
        id: 'l1',
        name: 'Kas',
        ownerId: 'u1',
        memberIds: ['u1'],
        inviteCode: 'ABC123',
      );
    addTearDown(store.dispose);
  });

  Future<void> deposit(String goalId, int amount) {
    return store.addSavingsContribution(
      goalId: goalId,
      amount: amount,
      date: DateTime.now(),
      note: '',
      type: ContributionType.deposit,
      source: ContributionSource.external,
    );
  }

  group('completion', () {
    test('a periodic goal never completes, however much is saved', () async {
      store.savingsGoals = [_periodicGoal()];
      await deposit('p1', 120000);
      await deposit('p1', 99999999);
      expect(repo.updatedGoals, isEmpty);
    });

    test('a plain target completes when its amount is reached', () async {
      store.savingsGoals = [_targetGoal()];
      await deposit('g1', 999999);
      expect(repo.updatedGoals, isEmpty);

      repo.depositedAmounts.clear();
      await deposit('g1', 1000000);
      expect(repo.updatedGoals.single.status, SavingsGoalStatus.completed);
    });

    test('an inflation-adjusted target needs today\'s higher price', () async {
      // Priced exactly one year ago at 10% a year: it costs 1.100.000 today.
      store.savingsGoals = [
        _targetGoal(
          deadline: _daysFromToday(730),
          adjust: true,
          rate: 10,
          priceDate: _daysFromToday(-365),
        ),
      ];

      await deposit('g1', 1050000);
      expect(repo.updatedGoals, isEmpty, reason: 'still below the current price');

      await deposit('g1', 1100000);
      expect(repo.updatedGoals.single.status, SavingsGoalStatus.completed);
    });
  });

  group('addSavingsGoal', () {
    test('stores a periodic goal without a target amount or deadline', () async {
      await store.addSavingsGoal(
        name: '  Celengan mingguan ',
        kind: SavingsGoalKind.periodic,
        targetAmount: 999, // ignored for periodic goals
        periodicAmount: 120000,
        periodUnit: PeriodUnit.week,
        adjustForInflation: true,
        expectedReturn: 4.5,
      );
      final draft = repo.addedDraft!;
      expect(draft.name, 'Celengan mingguan');
      expect(draft.isPeriodic, isTrue);
      expect(draft.targetAmount, 0);
      expect(draft.targetDate, isNull);
      expect(draft.periodicAmount, 120000);
      expect(draft.periodUnit, PeriodUnit.week);
      expect(draft.startDate, isNotNull);
      expect(draft.priceDate, isNull);
      expect(draft.expectedReturn, 4.5);
      expect(draft.createdBy, 'u1');
    });

    test('stores a target goal with today as its price date', () async {
      await store.addSavingsGoal(
        name: 'DP Rumah',
        targetAmount: 150000000,
        targetDate: _daysFromToday(1096),
        adjustForInflation: true,
      );
      final draft = repo.addedDraft!;
      final today = _daysFromToday(0);
      expect(draft.kind, SavingsGoalKind.target);
      expect(draft.targetAmount, 150000000);
      expect(draft.periodicAmount, isNull);
      expect(draft.priceDate, today);
      expect(draft.adjustForInflation, isTrue);
      expect(draft.inflationRate, isNull, reason: 'automatic');
    });

    test('rejects invalid input', () async {
      expect(
        () => store.addSavingsGoal(
          name: 'x',
          kind: SavingsGoalKind.periodic,
          periodUnit: PeriodUnit.week,
        ),
        throwsA(isA<SavingsValidationException>()),
      );
      expect(
        () => store.addSavingsGoal(
          name: 'x',
          kind: SavingsGoalKind.periodic,
          periodicAmount: 1000,
        ),
        throwsA(isA<SavingsValidationException>()),
      );
      expect(
        () => store.addSavingsGoal(name: 'x', targetAmount: 0),
        throwsA(isA<SavingsValidationException>()),
      );
      expect(
        () => store.addSavingsGoal(name: 'x', targetAmount: 100, expectedReturn: 150),
        throwsA(isA<SavingsValidationException>()),
      );
      expect(repo.addedDraft, isNull);
    });
  });

  group('grouping', () {
    test('splits goals by kind and totals what each kind has saved', () {
      store.savingsGoals = [_targetGoal(), _periodicGoal()];
      store.savingsContributions = [
        SavingsContribution(
          id: 'c1',
          goalId: 'g1',
          amount: 300000,
          date: DateTime.now(),
          note: '',
          type: ContributionType.deposit,
          source: ContributionSource.external,
          createdBy: 'u1',
          createdByName: 'Rani',
        ),
        SavingsContribution(
          id: 'c2',
          goalId: 'p1',
          amount: 120000,
          date: DateTime.now(),
          note: '',
          type: ContributionType.deposit,
          source: ContributionSource.external,
          createdBy: 'u1',
          createdByName: 'Rani',
        ),
      ];
      expect(store.finalGoals.map((g) => g.id), ['g1']);
      expect(store.periodicGoals.map((g) => g.id), ['p1']);
      expect(store.savedAcross(store.finalGoals), 300000);
      expect(store.savedAcross(store.periodicGoals), 120000);
      expect(store.totalSavings, 420000);
    });
  });
}
