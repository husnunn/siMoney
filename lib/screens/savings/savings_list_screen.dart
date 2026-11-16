import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../state/app_store.dart';
import 'add_edit_savings_goal_screen.dart';
import 'tabs/final_goals_tab.dart';
import 'tabs/periodic_goals_tab.dart';

/// Savings home. Two tabs share one set of goals: "Target Akhir" (reach a
/// total amount) and "Target Berkala" (save a fixed amount every period).
class SavingsListScreen extends StatefulWidget {
  const SavingsListScreen({super.key});

  @override
  State<SavingsListScreen> createState() => _SavingsListScreenState();
}

class _SavingsListScreenState extends State<SavingsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _onFinalTab => _tabs.index == 0;

  void _toggleBalance() => setState(() => _balanceHidden = !_balanceHidden);

  void _addGoal() {
    Navigator.of(context).pushNamed(
      AddEditSavingsGoalScreen.routeName,
      arguments:
          _onFinalTab ? SavingsGoalKind.target : SavingsGoalKind.periodic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Target Akhir'),
            Tab(text: 'Target Berkala'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_savings',
        onPressed: _addGoal,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(_onFinalTab ? 'Target akhir' : 'Target berkala'),
      ),
      body: ListenableBuilder(
        listenable: appStore,
        builder: (context, _) {
          return TabBarView(
            controller: _tabs,
            children: [
              FinalGoalsTab(
                balanceHidden: _balanceHidden,
                onToggleBalance: _toggleBalance,
              ),
              PeriodicGoalsTab(
                balanceHidden: _balanceHidden,
                onToggleBalance: _toggleBalance,
              ),
            ],
          );
        },
      ),
    );
  }
}
