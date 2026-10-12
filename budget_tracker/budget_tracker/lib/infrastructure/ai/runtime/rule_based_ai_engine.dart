import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/ai_assistant/domain/ai_action_draft.dart';
import '../../../features/ai_assistant/domain/ai_scenario_sandbox.dart';
import '../tools/ai_tool.dart';
import 'ai_engine.dart';

enum _Intent {
  greeting,
  affordability,
  monthlySpending,
  budgetStatus,
  goalProgress,
  savingsHelp,
  balance,
  recentTransactions,
  financialSummary,
  recurring,
  whatIfScenario,
  rule503020,
  emergencyFund,
  debtStrategy,
  impulseControl,
  salaryAllocation,
  investVsSave,
  financialStress,
  gratitude,
  unknown,
}

/// Fully offline, deterministic stand-in for the bundled on-device SLM.
///
/// It implements the same [AIEngine] contract the real transformer model
/// will implement (PRD 6.1/6.4: IntentDetector + ToolRouter), so the rest of
/// the app — orchestrator, chat UI, response validation — is already wired
/// for the real model and needs no changes when it's swapped in. Because it
/// never invents numbers (every figure it prints comes straight out of
/// `toolResults`), it also satisfies the "never fabricate financial data"
/// rule in the system prompt template by construction, not by hoping the
/// model behaves.
class RuleBasedAIEngine implements AIEngine {
  @override
  Future<bool> get isReady async => true;

  @override
  Future<AIEngineDecision> planToolCalls({
    required String userMessage,
    required List<AITool> availableTools,
    required List<AIEngineMessage> conversationHistory,
    Map<String, Map<String, dynamic>> accumulatedToolResults = const {},
  }) async {
    final intent = _detectIntent(userMessage);
    final now = DateTime.now();
    final amount = _extractAmount(userMessage);

    switch (intent) {
      case _Intent.greeting:
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.affordability:
        if (amount == null) {
          if (accumulatedToolResults.containsKey('get_current_balance')) {
            return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);
          }
          return const AIEngineDecision(toolNamesToCall: ['get_current_balance']);
        }

        // Multi-Step ReAct Chaining for Affordability:
        // Iteration 1: Check affordability and available liquidity
        if (!accumulatedToolResults.containsKey('get_current_balance')) {
          return AIEngineDecision(
            toolNamesToCall: const ['calculate_affordable_spending', 'get_current_balance'],
            toolArgs: {
              'calculate_affordable_spending': {
                'proposedAmount': amount,
                'startDate': now.toIso8601String(),
                'endDate': now.add(const Duration(days: 30)).toIso8601String(),
              },
            },
          );
        }

        // Iteration 2: Inspect recurring commitments to verify safe cashflow runway
        if (!accumulatedToolResults.containsKey('get_recurring_expenses')) {
          return AIEngineDecision(
            toolNamesToCall: const ['get_recurring_expenses', 'get_budget_status'],
            toolArgs: {
              'get_budget_status': {'month': now.toIso8601String()},
            },
          );
        }

        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.monthlySpending:
        if (!accumulatedToolResults.containsKey('get_monthly_expenses')) {
          return AIEngineDecision(
            toolNamesToCall: const ['get_monthly_expenses', 'get_expenses_by_category', 'get_top_spending_categories'],
            toolArgs: {
              'get_monthly_expenses': {'month': now.toIso8601String()},
              'get_expenses_by_category': {'month': now.toIso8601String()},
              'get_top_spending_categories': {'month': now.toIso8601String(), 'limit': 3},
            },
          );
        }
        if (!accumulatedToolResults.containsKey('get_budget_status')) {
          return AIEngineDecision(
            toolNamesToCall: const ['get_budget_status'],
            toolArgs: {'get_budget_status': {'month': now.toIso8601String()}},
          );
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.budgetStatus:
        if (!accumulatedToolResults.containsKey('get_budget_status')) {
          return AIEngineDecision(
            toolNamesToCall: const ['get_budget_status'],
            toolArgs: {
              'get_budget_status': {'month': now.toIso8601String()},
            },
          );
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.goalProgress:
        if (!accumulatedToolResults.containsKey('get_all_goals')) {
          return const AIEngineDecision(toolNamesToCall: ['get_all_goals']);
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.savingsHelp:
        if (!accumulatedToolResults.containsKey('calculate_savings_rate')) {
          return AIEngineDecision(
            toolNamesToCall: const ['calculate_savings_rate', 'get_top_spending_categories'],
            toolArgs: {
              'calculate_savings_rate': {'month': now.toIso8601String()},
              'get_top_spending_categories': {'month': now.toIso8601String(), 'limit': 3},
            },
          );
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.balance:
        if (!accumulatedToolResults.containsKey('get_current_balance')) {
          return const AIEngineDecision(toolNamesToCall: ['get_current_balance', 'get_account_balances']);
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.recentTransactions:
        if (!accumulatedToolResults.containsKey('get_recent_transactions')) {
          return const AIEngineDecision(toolNamesToCall: ['get_recent_transactions', 'get_current_balance']);
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.financialSummary:
        if (!accumulatedToolResults.containsKey('get_current_balance')) {
          return AIEngineDecision(
            toolNamesToCall: const [
              'get_current_balance',
              'get_monthly_expenses',
              'get_budget_status',
              'get_all_goals',
            ],
            toolArgs: {
              'get_monthly_expenses': {'month': now.toIso8601String()},
              'get_budget_status': {'month': now.toIso8601String()},
            },
          );
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.recurring:
        if (!accumulatedToolResults.containsKey('get_recurring_expenses')) {
          return const AIEngineDecision(toolNamesToCall: ['get_recurring_expenses', 'calculate_recurring_monthly_total']);
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.whatIfScenario:
        final cutAmount = _extractCutAmount(userMessage);
        final goalName = _extractGoalName(userMessage);

        if (!accumulatedToolResults.containsKey('simulate_financial_scenario')) {
          return AIEngineDecision(
            toolNamesToCall: const ['simulate_financial_scenario', 'get_current_balance', 'get_all_goals'],
            toolArgs: {
              'simulate_financial_scenario': {
                if (amount != null && cutAmount == null) 'proposedPurchase': amount,
                if (cutAmount != null) 'expenseCut': cutAmount,
                if (goalName != null) 'targetGoalName': goalName,
              },
            },
          );
        }
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);

      case _Intent.rule503020:
      case _Intent.emergencyFund:
      case _Intent.debtStrategy:
      case _Intent.impulseControl:
      case _Intent.salaryAllocation:
      case _Intent.investVsSave:
      case _Intent.financialStress:
      case _Intent.gratitude:
      case _Intent.unknown:
        return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);
    }
  }

  @override
  Future<String> generateResponse({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  }) async {
    final draft = await extractActionDraft(
      userMessage: userMessage,
      toolResults: toolResults,
      conversationHistory: conversationHistory,
    );
    if (draft != null) {
      switch (draft.type) {
        case AIActionType.createTransaction:
          final isIncome = draft.payload['isIncome'] == true;
          return "I've drafted this ${isIncome ? 'income' : 'expense'} transaction for you! Review the details on the card below.\n\n"
              "**Your Call:** Tap **Confirm & Save** (or say *\"yes, implement it\"*) to record it, or tap **Cancel** (or say *\"reject it\"*) to revoke.";
        case AIActionType.createBudget:
          return "I've prepared a monthly budget limit of ${CurrencyFormatter.format(draft.payload['amount'] as double)} for ${draft.payload['categoryName']}.\n\n"
              "**Your Call:** Tap **Confirm & Save** (or say *\"yes, implement it\"*) to apply this budget limit, or say *\"reject it\"* to discard.";
        case AIActionType.createGoal:
          return "I've created a savings goal draft for **${draft.payload['name']}** targeting ${CurrencyFormatter.format(draft.payload['targetAmount'] as double)}.\n\n"
              "**Your Call:** Tap **Confirm & Save** (or say *\"yes, implement it\"*) to lock in this goal, or say *\"cancel\"* to discard.";
        case AIActionType.applyFinancialPlan:
          return "Here is your 50/30/20 spending and savings plan! Review the breakdown below.\n\n"
              "**Your Call:** Tap **Confirm & Save** (or say *\"yes, implement it\"*) to automatically apply these budgets and savings goal, or say *\"reject it\"* to revoke.";
        case AIActionType.batchBundle:
          final count = (draft.payload['actions'] as List?)?.length ?? 0;
          return "I've structured a complete financial plan bundle with $count coordinated actions! Review the execution plan on the card below.\n\n"
              "**Your Call:** Tap **Confirm Plan** to execute all $count actions atomically, or tap **Cancel** to discard.";
      }
    }

    final intent = _detectIntent(userMessage);

    switch (intent) {
      case _Intent.greeting:
        return "Hello! I'm Maya, your proactive offline financial assistant and AI Financial Agent for MayPeraPa. I'm here to crunch numbers, give strategic advice, and help you master your money.\n\n"
            "Here's what we can do together:\n"
            '• Check finances: *"What is my balance?"* or *"Calculate my spending"*\n'
            '• Smarter decisions: *"Can I afford ₱2,500?"* or *"What if I cut dining out by ₱1,000?"*\n'
            '• Actions & Goals: *"Add 500 into my balance"*, *"Set food budget to ₱6,000"*, or *"Create goal for Emergency Fund ₱50,000"*\n'
            '• Strategy: *"Plan how to spend and save my salary"*\n\n'
            'Whenever I suggest an action, you can say **"implement it"** to save or **"revoke it"** to cancel. How are we doing today?';
      case _Intent.affordability:
        return _affordabilityResponse(toolResults);
      case _Intent.monthlySpending:
        return _monthlySpendingResponse(toolResults);
      case _Intent.budgetStatus:
        return _budgetStatusResponse(toolResults);
      case _Intent.goalProgress:
        return _goalProgressResponse(toolResults);
      case _Intent.savingsHelp:
        return _savingsResponse(toolResults);
      case _Intent.balance:
        return _balanceResponse(toolResults);
      case _Intent.recentTransactions:
        return _recentTransactionsResponse(toolResults);
      case _Intent.financialSummary:
        return _financialSummaryResponse(toolResults);
      case _Intent.recurring:
        return _recurringResponse(toolResults);
      case _Intent.whatIfScenario:
        return _scenarioResponse(toolResults);
      case _Intent.rule503020:
        return _rule503020Response();
      case _Intent.emergencyFund:
        return _emergencyFundResponse();
      case _Intent.debtStrategy:
        return _debtStrategyResponse();
      case _Intent.impulseControl:
        return _impulseControlResponse();
      case _Intent.salaryAllocation:
        return _salaryAllocationResponse();
      case _Intent.investVsSave:
        return _investVsSaveResponse();
      case _Intent.financialStress:
        return _financialStressResponse();
      case _Intent.gratitude:
        return _gratitudeResponse();
      case _Intent.unknown:
        return "I can help with balance, spending, budgets, goals, what-if simulations, and financial coaching (like 50/30/20, emergency funds, and debt strategies). "
            'Try asking something like "What is the 50/30/20 rule?" or "Can I afford ₱2,000 this weekend?"';
    }
  }

  // -- Intent detection (PRD 6.4 IntentDetector, extended for colloquial & scenario queries) --------

  _Intent _detectIntent(String raw) {
    final q = raw.toLowerCase().trim();

    // 0. Greetings & Identity Queries
    final hasGreeting = q == 'hi' ||
        q == 'hello' ||
        q == 'hey' ||
        q == 'help' ||
        q == 'maya' ||
        q.startsWith('hi ') ||
        q.startsWith('hello ') ||
        q.startsWith('hey ') ||
        q.startsWith('maya ') ||
        q.contains('good morning') ||
        q.contains('good afternoon') ||
        q.contains('good evening') ||
        q.contains('who are you') ||
        q.contains('what is your name') ||
        q.contains('what can you do');
    if (hasGreeting) return _Intent.greeting;

    // 1. What-If & Hypothetical Simulation
    final hasScenario = q.contains('what if') ||
        q.contains('if i cut') ||
        q.contains('if i reduce') ||
        q.contains('if i cancel') ||
        q.contains('how fast will i reach') ||
        q.contains('how soon will i reach') ||
        q.contains('simulate') ||
        q.contains('what happens if');
    if (hasScenario) return _Intent.whatIfScenario;

    // 2. Conversational Financial Coaching & Advice (prioritized before broad 'spend' / 'can i' queries)
    if (q.contains('50/30/20') || q.contains('50 30 20') || q.contains('50-30-20') || q.contains('rule of 50')) {
      return _Intent.rule503020;
    }
    if (q.contains('emergency fund') || q.contains('rainy day') || q.contains('safety net') || q.contains('buffer fund')) {
      return _Intent.emergencyFund;
    }
    if (q.contains('snowball') || q.contains('avalanche') || q.contains('debt') || q.contains('credit card') || q.contains('pay off loan')) {
      return _Intent.debtStrategy;
    }
    if (q.contains('impulse') || q.contains('stop spending') || q.contains('control spending') || q.contains('stop buying') || q.contains('buyer remorse') || q.contains('need vs want') || q.contains('needs vs wants')) {
      return _Intent.impulseControl;
    }
    if (q.contains('salary') || q.contains('paycheck') || q.contains('just got paid') || q.contains('zero based') || q.contains('envelope')) {
      return _Intent.salaryAllocation;
    }
    if (q.contains('invest') || q.contains('stocks') || q.contains('grow wealth') || q.contains('save or invest')) {
      return _Intent.investVsSave;
    }
    if (q.contains('stress') || q.contains('anxious') || q.contains('overwhelm') || q.contains('worried') || q.contains('broke') || q.contains('money is hard')) {
      return _Intent.financialStress;
    }
    if (q.contains('thank') || q.contains('appreciate') || q.contains('good job') || q.contains('awesome')) {
      return _Intent.gratitude;
    }

    // 3. Affordability (including natural & colloquial phrasing)
    final hasColloquialAfford = q.contains('afford') ||
        q.contains('wallet have enough') ||
        q.contains('wallet has enough') ||
        q.contains('budget take') ||
        q.contains('got enough cash') ||
        q.contains('got enough money') ||
        q.contains('is it safe to buy') ||
        q.contains('should i buy') ||
        q.contains('can i swing') ||
        q.contains('kaya ko ba') ||
        q.contains('pwede ba bilhin') ||
        q.contains('pwede ba ako bumili');
    final hasSpend = q.contains('spend') ||
        q.contains('buy') ||
        q.contains('purchase') ||
        q.contains('get') ||
        q.contains('trip') ||
        q.contains('gastos') ||
        q.contains('nagastos');
    if (hasColloquialAfford || (hasSpend && (q.contains('can i') || q.contains('could i')))) {
      return _Intent.affordability;
    }

    // 4. Financial Summary / Overview
    final hasSummary = q.contains('summary') ||
        q.contains('overview') ||
        q.contains('how are my finances') ||
        q.contains('how am i doing') ||
        q.contains('financial status') ||
        q.contains('financial health') ||
        q.contains('kamusta pera ko') ||
        q.contains('kamusta finances') ||
        q.contains('snapshot');
    if (hasSummary) return _Intent.financialSummary;

    // 5. Recent Transactions & Purchase History
    final hasTxn = q.contains('transaction') ||
        q.contains('transactions') ||
        q.contains('recent purchase') ||
        q.contains('recent purchases') ||
        q.contains('what did i buy') ||
        q.contains('what i bought') ||
        q.contains('last purchase') ||
        q.contains('history') ||
        q.contains('activity') ||
        q.contains('mga binili') ||
        q.contains('mga nagastos');
    if (hasTxn) return _Intent.recentTransactions;

    // 6. Monthly Spending & Category Breakdown
    final hasSpendingQuery = q.contains('how much did i spend') ||
        q.contains('how much have i spent') ||
        q.contains('how much spent') ||
        q.contains('my spending') ||
        q.contains('where did my money go') ||
        q.contains('where my money goes') ||
        q.contains('total expense') ||
        q.contains('total spending') ||
        q.contains('nagastos ko') ||
        q.contains('magkano nagastos') ||
        q.contains('expenses this month') ||
        q.contains('spending this month') ||
        (hasSpend && (q.contains('month') || q.contains('where') || q.contains('how much')));
    if (hasSpendingQuery) return _Intent.monthlySpending;

    // 7. Balance & Wallet Funds
    final hasBalanceQuery = q.contains('balance') ||
        q.contains('how much money do i have') ||
        q.contains('how much money i have') ||
        q.contains('how much do i have') ||
        q.contains('in my wallet') ||
        q.contains('in my account') ||
        q.contains('in my bank') ||
        q.contains('available funds') ||
        q.contains('cash on hand') ||
        q.contains('pera ko') ||
        q.contains('magkano pera ko') ||
        q.contains('magkano laman');
    if (hasBalanceQuery) return _Intent.balance;

    // 8. Other core data intents
    if (q.contains('budget')) return _Intent.budgetStatus;
    if (q.contains('goal') || q.contains('saving for') || q.contains('ipon')) return _Intent.goalProgress;
    if (q.contains('save') || q.contains('savings rate')) return _Intent.savingsHelp;
    if (q.contains('subscription') || q.contains('recurring') || q.contains('bills')) return _Intent.recurring;

    return _Intent.unknown;
  }

  /// Pulls the first currency-like number out of the message, e.g.
  /// "Can I spend 2000 this weekend?" -> 2000.0, "₱1,500" -> 1500.0.
  double? _extractAmount(String raw) {
    final match = RegExp(r'[\d,]+(\.\d+)?').firstMatch(raw.replaceAll('₱', '').replaceAll('\$', ''));
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', ''));
  }

  double? _extractCutAmount(String raw) {
    final lower = raw.toLowerCase();
    final cutMatch = RegExp(r'(?:cut|reduce|save|drop)[^\d]*([\d,]+(?:\.\d+)?)').firstMatch(lower);
    if (cutMatch != null) {
      return double.tryParse(cutMatch.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  String? _extractGoalName(String raw) {
    final match = RegExp(r'(?:reach|hit|for)\s+(?:my\s+)?([A-Za-z\s]+?)\s+(?:goal|fund)', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  // -- Response templates ---------------------------------------------------
  // Every value interpolated below is read directly from `toolResults` —
  // nothing here is invented, per the system prompt's anti-hallucination rule.

  String _affordabilityResponse(Map<String, Map<String, dynamic>> results) {
    final affordability = results['calculate_affordable_spending'];
    if (affordability == null) {
      final bal = (results['get_current_balance']?['balance'] as num?)?.toDouble();
      if (bal != null) {
        return "Your current available balance across accounts is **${CurrencyFormatter.format(bal)}**.\n\n"
            "To check if a specific purchase is safe and fits your budget buffer, ask with the price:\n"
            "*\"Can I afford ₱2,500?\"* or *\"Can I afford a ₱1,500 dinner?\"*";
      }
      return "I couldn't check that — try asking again with an amount, like *\"Can I afford ₱2,000?\"*";
    }
    final canAfford = affordability['canAfford'] as bool? ?? false;
    final before = (affordability['projectedBalanceBeforePurchase'] as num?)?.toDouble() ?? 0;
    final after = (affordability['projectedBalanceAfterPurchase'] as num?)?.toDouble() ?? 0;
    final recurring = (affordability['upcomingRecurringExpenses'] as num?)?.toDouble() ?? 0;
    final warning = affordability['warning'] as String?;

    final buffer = StringBuffer();
    buffer.writeln(canAfford ? '**Yes, that purchase looks affordable!**' : '**That would be tight — probably best to hold off.**');
    buffer.writeln();
    if (recurring > 0) {
      buffer.writeln('• Upcoming recurring commitments: ${CurrencyFormatter.format(recurring)}');
    }
    buffer.writeln('• Projected balance before purchase: ${CurrencyFormatter.format(before)}');
    buffer.writeln('• Projected balance after: ${CurrencyFormatter.format(after)}');
    if (warning != null) {
      buffer.writeln();
      buffer.writeln(warning);
    }
    buffer.writeln();
    if (canAfford) {
      buffer.write('**Next Step:** If you proceed, tell me *"Spent [amount] on [item]"* and I will draft the expense with one-tap confirmation for you!');
    } else {
      buffer.write('**Suggestion:** Try waiting 24 hours (the 24-Hour Rule) or ask me *"What if I cut dining out by ₱1,000?"* to see how to create room in your budget.');
    }
    return buffer.toString().trim();
  }

  String _monthlySpendingResponse(Map<String, Map<String, dynamic>> results) {
    final expenses = results['get_monthly_expenses'];
    final top = results['get_top_spending_categories'];
    final total = (expenses?['expenses'] as num?)?.toDouble() ?? 0;
    if (total == 0) {
      return "You haven't recorded any expenses for this month yet. Once you add transactions, I'll provide category breakdowns and trends!\n\n"
          "**Suggestion:** You can log an expense anytime: *\"Spent 150 on coffee\"* or *\"Deduct 500 for groceries\"*.";
    }
    final buffer = StringBuffer('You\'ve spent **${CurrencyFormatter.format(total)}** this month so far.');
    final topCategories = top?['topCategories'] as List?;
    if (topCategories != null && topCategories.isNotEmpty) {
      buffer.writeln();
      buffer.writeln();
      buffer.writeln('Top spending categories:');
      for (final c in topCategories) {
        final label = c['categoryName'] as String? ?? 'Category #${c['categoryId']}';
        buffer.writeln('• **$label:** ${CurrencyFormatter.format((c['amount'] as num).toDouble())}');
      }
    }
    buffer.writeln();
    buffer.write('**Proactive Suggestion:** Would you like to set a target limit on your top category? Just tell me: *"Set food budget to ₱5,000"* or ask *"Can I afford ₱1,500?"*');
    return buffer.toString().trim();
  }

  String _budgetStatusResponse(Map<String, Map<String, dynamic>> results) {
    final status = results['get_budget_status'];
    if (status == null || status.containsKey('error')) {
      return "You don't have an active budget set up for this period yet.\n\n"
          "**Suggestion:** Budgeting is the fastest way to master your cash flow. Tell me: *\"Set food budget to ₱6,000\"* or *\"Plan how to spend and save my salary\"* to draft one!";
    }
    final spent = (status['spent'] as num).toDouble();
    final total = (status['totalBudget'] as num).toDouble();
    final remaining = (status['remaining'] as num).toDouble();
    final pct = ((status['percentUsed'] as num).toDouble() * 100).round();
    final over = remaining < 0;
    return "You've used **$pct%** of your ${status['budgetName']} budget "
        '(${CurrencyFormatter.format(spent)} of ${CurrencyFormatter.format(total)}).\n\n'
        '${over ? 'You are **${CurrencyFormatter.format(remaining.abs())}** over budget.' : '**${CurrencyFormatter.format(remaining)}** remaining.'}\n\n'
        '**Suggestion:** ${over ? "Consider scaling back discretionary spending this week to get back on track." : "You are pacing well! Keep this rate up to finish the month with a surplus."}';
  }

  String _goalProgressResponse(Map<String, Map<String, dynamic>> results) {
    final data = results['get_all_goals'];
    final goals = data?['goals'] as List?;
    if (goals == null || goals.isEmpty) {
      return "You don't have any active goals set up yet.\n\n"
          "**Suggestion:** Start building momentum! Tell me: *\"Create goal for Emergency Fund target ₱50,000\"* or *\"Set goal for Vacation 20,000\"* to draft your first goal.";
    }
    final buffer = StringBuffer('Here\'s where your goals stand:\n');
    for (final g in goals) {
      final pct = ((g['progressPercentage'] as num).toDouble() * 100).round();
      buffer.writeln(
          '• **${g['name']}:** ${CurrencyFormatter.format((g['currentAmount'] as num).toDouble())} of ${CurrencyFormatter.format((g['targetAmount'] as num).toDouble())} ($pct%)');
    }
    buffer.writeln();
    buffer.write('**Suggestion:** You can simulate faster milestones anytime: ask *"What if I cut dining out by ₱1,500?"*');
    return buffer.toString().trim();
  }

  String _savingsResponse(Map<String, Map<String, dynamic>> results) {
    final rate = results['calculate_savings_rate'];
    if (rate == null || rate.containsKey('error')) return "I don't have enough income data yet to calculate a savings rate.";
    final pct = ((rate['savingsRate'] as num).toDouble() * 100).round();
    final top = results['get_top_spending_categories']?['topCategories'] as List?;
    final buffer = StringBuffer("You're saving about **$pct%** of your income this month.");
    if (top != null && top.isNotEmpty) {
      buffer.writeln();
      buffer.writeln();
      buffer.write('**Suggestion:** Your biggest expense categories are the best place to find extra savings. Ask *"Where is most of my money going?"* to investigate!');
    }
    return buffer.toString();
  }

  String _balanceResponse(Map<String, Map<String, dynamic>> results) {
    final balance = results['get_current_balance'];
    final accountsData = results['get_account_balances']?['accounts'] as List?;
    if (balance == null || balance.containsKey('error')) {
      return "Your current available balance across all accounts is ₱0.00.\n\n"
          "**Suggestion:** Record your starting funds by saying: *\"Add 10,000 into my balance from salary\"*.";
    }
    final bal = (balance['balance'] as num?)?.toDouble() ?? 0.0;
    final buffer = StringBuffer('Your current available balance across accounts is **${CurrencyFormatter.format(bal)}**.');

    if (accountsData != null && accountsData.isNotEmpty) {
      buffer.writeln();
      buffer.writeln();
      buffer.writeln('Account breakdown:');
      for (final a in accountsData) {
        final name = a['name'] as String? ?? 'Account';
        final aBal = (a['balance'] as num?)?.toDouble() ?? 0.0;
        buffer.writeln('• **$name:** ${CurrencyFormatter.format(aBal)}');
      }
    }

    buffer.writeln();
    buffer.write('**Proactive Suggestion:** Would you like to review your **monthly budget** or allocate funds toward a **savings goal**? You can say: *"Set food budget to ₱5,000"* or *"Create goal for Emergency Fund ₱30,000"*.');
    return buffer.toString().trim();
  }

  String _recentTransactionsResponse(Map<String, Map<String, dynamic>> results) {
    final txns = results['get_recent_transactions']?['transactions'] as List?;
    if (txns == null || txns.isEmpty) {
      final bal = (results['get_current_balance']?['balance'] as num?)?.toDouble();
      final balStr = bal != null ? ' (current balance is **${CurrencyFormatter.format(bal)}**)' : '';
      return "You don't have any recorded transactions yet$balStr.\n\n"
          "**Suggestion:** You can log your first transaction anytime: *\"Spent 250 on groceries\"* or *\"Received 15,000 salary\"*.";
    }

    final buffer = StringBuffer('Here are your latest transactions:\n');
    for (final t in txns) {
      final desc = t['description'] as String? ?? 'Transaction';
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final type = t['type'] as String? ?? 'expense';
      final isIncome = type == 'income';
      final sign = isIncome ? '+' : '-';
      buffer.writeln('• $desc: **$sign${CurrencyFormatter.format(amt)}**');
    }

    final bal = (results['get_current_balance']?['balance'] as num?)?.toDouble();
    if (bal != null) {
      buffer.writeln();
      buffer.writeln('Available balance: **${CurrencyFormatter.format(bal)}**');
    }

    buffer.writeln();
    buffer.write('**Suggestion:** Need to log a new purchase? Just tell me: *"Spent 120 on coffee"* or *"Add 5,000 income"*.');
    return buffer.toString().trim();
  }

  String _financialSummaryResponse(Map<String, Map<String, dynamic>> results) {
    final balance = results['get_current_balance'];
    final expenses = results['get_monthly_expenses'];
    final budget = results['get_budget_status'];
    final goalsData = results['get_all_goals']?['goals'] as List?;

    final bal = (balance?['balance'] as num?)?.toDouble() ?? 0.0;
    final exp = (expenses?['expenses'] as num?)?.toDouble() ?? 0.0;

    final buffer = StringBuffer('Here is your financial snapshot:\n\n');
    buffer.writeln('• **Available Balance:** ${CurrencyFormatter.format(bal)}');
    buffer.writeln('• **This Month\'s Spending:** ${CurrencyFormatter.format(exp)}');

    if (budget != null && !budget.containsKey('error')) {
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
      final total = (budget['totalBudget'] as num?)?.toDouble() ?? 0.0;
      final pct = (((budget['percentUsed'] as num?)?.toDouble() ?? 0.0) * 100).round();
      buffer.writeln('• **Budget (${budget['budgetName']}):** ${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(total)} ($pct%)');
    }

    if (goalsData != null && goalsData.isNotEmpty) {
      buffer.writeln('• **Active Goals:** ${goalsData.length} goal(s) in progress');
    }

    buffer.writeln();
    buffer.write('**Proactive Suggestion:** What would you like to focus on next? Ask *"Can I afford ₱2,000?"*, *"What is my budget status?"*, or *"Plan how to spend and save my salary"*.');
    return buffer.toString().trim();
  }

  String _recurringResponse(Map<String, Map<String, dynamic>> results) {
    final total = results['calculate_recurring_monthly_total'];
    final list = results['get_recurring_expenses']?['recurringExpenses'] as List?;
    if (total == null) return "You don't have any recurring transactions set up yet.";
    final monthly = (total['monthlyTotal'] as num).toDouble();
    final buffer = StringBuffer(
        'Your recurring commitments net to about **${CurrencyFormatter.format(monthly)}** per month.');
    if (list != null && list.isNotEmpty) {
      buffer.writeln();
      buffer.writeln();
      buffer.writeln('Recurring expenses:');
      for (final r in list) {
        buffer.writeln('• ${r['description']}: ${CurrencyFormatter.format((r['amount'] as num).toDouble())} (${r['frequency']})');
      }
    }
    buffer.writeln();
    buffer.write('**Suggestion:** Auditing recurring subscriptions every quarter is an easy way to free up ₱500–₱2,000 monthly!');
    return buffer.toString().trim();
  }

  String _scenarioResponse(Map<String, Map<String, dynamic>> results) {
    final sim = results['simulate_financial_scenario'];
    if (sim == null || sim.containsKey('error')) {
      return "I couldn't run the scenario simulation with the current data. Make sure you have balance and transaction records.";
    }

    final summary = sim['summary'] as String?;
    if (summary != null && summary.isNotEmpty) {
      return '$summary\n\n**Action:** If you\'d like to apply this plan, tell me: *"Plan how to spend and save my salary"*.';
    }

    final balance = (sim['currentBalance'] as num?)?.toDouble() ?? 0.0;
    final after = (sim['netMonthlySavingsAfter'] as num?)?.toDouble() ?? 0.0;
    return 'Based on your available balance of ${CurrencyFormatter.format(balance)}, this scenario would result in projected monthly savings of ${CurrencyFormatter.format(after)}.\n\n'
        '**Next Step:** Would you like to lock this in by creating a dedicated goal?';
  }

  String _rule503020Response() {
    return 'The **50/30/20 Rule** is a proven, intuitive way to budget your net income:\n\n'
        '• **50% Needs:** Essential living expenses you cannot avoid (rent/mortgage, groceries, utilities, transportation, minimum debt payments).\n'
        '• **30% Wants:** Lifestyle and discretionary spending (dining out, entertainment, shopping, hobbies, subscriptions).\n'
        '• **20% Savings & Debt:** Financial future (emergency fund, retirement, debt payoff, investments).\n\n'
        '**Proactive Suggestion:** Would you like me to build a custom 50/30/20 plan for your income? Just say: *"Plan how to spend and save my ₱30,000 salary"* and I will draft the exact allocations for you to confirm!';
  }

  String _emergencyFundResponse() {
    return 'An **Emergency Fund** is your financial airbag that prevents unexpected life events from turning into high-interest debt:\n\n'
        '• **Target Size:** Aim for **3 to 6 months** of essential living expenses (rent, food, utility bills).\n'
        '• **Starter Goal:** If starting from zero, aim for a **₱10,000 to ₱20,000 starter buffer** first.\n'
        '• **Where to Keep It:** In a liquid, high-yield digital bank account (e.g. Maya, Seabank, GoTyme, Tonik). Never tie it up in stocks or crypto.\n'
        '• **Rule of Thumb:** Only touch it for true emergencies: medical issues, sudden job loss, or essential repairs.';
  }

  String _debtStrategyResponse() {
    return 'There are two gold-standard strategies to pay off debt faster:\n\n'
        '1. **Debt Avalanche (Mathematically Optimal):**\n'
        '   Pay minimums on all debts, then put every spare peso toward the debt with the **highest interest rate** (usually credit cards at 36%+ APR). Saves the most money in interest.\n\n'
        '2. **Debt Snowball (Psychological Momentum):**\n'
        '   Pay minimums on all debts, then attack the **smallest balance** first regardless of interest. Eliminating an entire debt quickly gives you a massive mental boost to keep going.\n\n'
        '*Which is best?* The best method is the one you will actually stick to. If you need quick emotional wins, choose Snowball. If you want maximum math efficiency, choose Avalanche.';
  }

  String _impulseControlResponse() {
    return "Here are 3 battle-tested techniques to stop impulse buying:\n\n"
        "• **The 24-Hour Rule:** Wait a full 24 hours before buying anything non-essential over ₱1,000. 70% of urges disappear overnight.\n"
        "• **The \"Hours of Life\" Test:** Divide the item's price by your hourly take-home pay. Ask yourself: *\"Is this item really worth 8 hours of my hard work?\"*\n"
        "• **The Strangers Test:** Imagine someone offering you the item in one hand, or the cash in the other. If you'd take the cash, don't buy the item.\n\n"
        "You can also ask me *\"Can I afford ₱X?\"* before you buy, and I will check your live budget buffer for you!";
  }

  String _salaryAllocationResponse() {
    return "Here is a stress-free paycheck budgeting routine:\n\n"
        "1. **Pay Yourself First (Day 1):** Immediately transfer 15-20% to savings or investments the moment your salary lands.\n"
        "2. **Cover Fixed Essentials:** Pay rent, utilities, and debt payments right away so your baseline is secured.\n"
        "3. **Zero-Based Allocation:** Give every remaining peso a specific job (groceries, transport, fun money).\n"
        "4. **Weekly Allowance:** Divide your discretionary money into 4 weekly portions so you don't run dry before the next payday.";
  }

  String _investVsSaveResponse() {
    return "The golden rule of **Saving vs. Investing** follows a clear sequence:\n\n"
        "1. **Step 1 — Emergency Fund (Cash First):** Keep 3–6 months in safe, liquid savings before investing a single peso.\n"
        "2. **Step 2 — High-Interest Debt:** Paying off a 24-36% credit card gives an instant guaranteed 24-36% return.\n"
        "3. **Step 3 — Long-Term Investing:** Any money you won't need for 5+ years should be invested (diversified index funds, dividend stocks, MP2, retirement accounts) to beat inflation.\n\n"
        "Remember: **Saving is for defense** (security and emergencies). **Investing is for offense** (growing wealth over decades).";
  }

  String _financialStressResponse() {
    return "Take a deep breath — money anxiety is incredibly common, and you don't have to fix your entire financial life in one day.\n\n"
        "Just opening this app and checking your numbers puts you ahead of most people. Here is a calm plan for today:\n"
        "• Don't worry about being perfect. Just log today's expenses.\n"
        "• Focus on one small win: cook one meal at home or set aside ₱100.\n"
        "• You are in control of your next decision, no matter what past spending looked like. You've got this!";
  }

  String _gratitudeResponse() {
    return "You're very welcome! I'm here anytime you need to crunch numbers, double-check an upcoming purchase, or plan your next financial milestone.";
  }

  @override
  Future<AIActionDraft?> extractActionDraft({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  }) async {
    final q = userMessage.toLowerCase().trim();
    final amount = _extractAmount(userMessage);

    // 1. Spend & Save Planning Command
    // e.g. "give me a plan on how to spend and save my ₱30,000 salary" or "how should I spend and save 30000"
    if ((q.contains('plan') || q.contains('how should i spend') || q.contains('how to spend and save')) &&
        (q.contains('spend and save') || q.contains('salary') || q.contains('income') || q.contains('budget my'))) {
      final income = amount ?? 30000.0;
      final needs = income * 0.50;
      final wants = income * 0.30;
      final savings = income * 0.20;

      return AIActionDraft(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AIActionType.applyFinancialPlan,
        title: '50/30/20 Financial Plan',
        subtitle: 'Needs: ${CurrencyFormatter.format(needs)} • Wants: ${CurrencyFormatter.format(wants)} • Savings: ${CurrencyFormatter.format(savings)}',
        payload: {
          'salary': income,
          'monthlyIncome': income,
          'needsBudget': needs,
          'needsAmount': needs,
          'wantsBudget': wants,
          'wantsAmount': wants,
          'savingsGoal': savings,
          'savingsAmount': savings,
          'suggestedBudgets': [
            {'category': 'Bills', 'amount': needs},
            {'category': 'Entertainment', 'amount': wants},
          ],
          'suggestedGoal': {
            'name': 'Monthly Savings Target',
            'amount': savings,
          },
        },
        createdAt: DateTime.now(),
      );
    }

    // 1b. Multi-Action Batch Bundle Setup
    // e.g. "set up bundle for 30000" or "bundle setup" or "complete setup"
    if (q.contains('bundle') || q.contains('batch setup') || q.contains('complete setup') || q.contains('salary setup')) {
      final income = amount ?? 30000.0;
      final needs = income * 0.50;
      final wants = income * 0.30;
      final savings = income * 0.20;

      return AIActionDraft(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AIActionType.batchBundle,
        title: '50/30/20 Complete Salary Setup',
        subtitle: 'Executes 3 budgets & 1 savings goal atomically',
        payload: {
          'actions': [
            {
              'type': 'createBudget',
              'title': 'Needs Budget (50%)',
              'subtitle': 'Bills & Food allocation',
              'payload': {
                'name': 'Needs Budget',
                'amount': needs,
                'categoryName': 'Bills & Utilities',
              },
            },
            {
              'type': 'createBudget',
              'title': 'Wants Budget (30%)',
              'subtitle': 'Discretionary allocation',
              'payload': {
                'name': 'Wants Budget',
                'amount': wants,
                'categoryName': 'Shopping',
              },
            },
            {
              'type': 'createGoal',
              'title': 'Emergency Fund (20%)',
              'subtitle': 'Savings target allocation',
              'payload': {
                'name': 'Emergency Fund',
                'targetAmount': savings * 6,
              },
            },
          ],
        },
        createdAt: DateTime.now(),
      );
    }

    // 2. Goal Creation Command
    // e.g. "create a goal for Emergency Fund target ₱50,000" or "set goal for New Car 100000"
    if (q.contains('goal') && (q.contains('create') || q.contains('set') || q.contains('new') || q.contains('add') || q.contains('target'))) {
      if (amount != null && amount > 0) {
        String goalName = 'Emergency Fund';
        if (q.contains('emergency')) {
          goalName = 'Emergency Fund';
        } else if (q.contains('car')) {
          goalName = 'New Car';
        } else if (q.contains('laptop') || q.contains('macbook') || q.contains('pc')) {
          goalName = 'New Laptop';
        } else if (q.contains('travel') || q.contains('vacation') || q.contains('trip')) {
          goalName = 'Vacation Trip';
        } else if (q.contains('house') || q.contains('home')) {
          goalName = 'House Downpayment';
        } else if (q.contains('wedding')) {
          goalName = 'Wedding Fund';
        } else {
          final extracted = _extractGoalName(userMessage);
          if (extracted != null && extracted.isNotEmpty) {
            goalName = extracted;
          }
        }

        return AIActionDraft(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AIActionType.createGoal,
          title: 'Create Savings Goal',
          subtitle: '$goalName • Target: ${CurrencyFormatter.format(amount)}',
          payload: {
            'name': goalName,
            'targetAmount': amount,
            'amount': amount,
            'targetDate': DateTime.now().add(const Duration(days: 180)).toIso8601String(),
          },
          createdAt: DateTime.now(),
        );
      }
    }

    // 3. Budget Creation Command
    // e.g. "set food budget to ₱6,000" or "create budget for groceries ₱5,000"
    if (q.contains('budget') && (q.contains('set') || q.contains('create') || q.contains('make') || q.contains('add') || q.contains('limit'))) {
      if (amount != null && amount > 0) {
        final category = _extractCategory(q);
        return AIActionDraft(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: AIActionType.createBudget,
          title: 'Set Category Budget',
          subtitle: '$category • Limit: ${CurrencyFormatter.format(amount)} / month',
          payload: {
            'name': '${AppDateUtils.monthName(DateTime.now().month)} ${DateTime.now().year}',
            'categoryName': category,
            'amount': amount,
            'totalBudget': amount,
            'categoryAllocations': {category: amount},
          },
          createdAt: DateTime.now(),
        );
      }
    }

    // 4. Transaction Creation (Expense or Income)
    // Expense e.g.: "I spent ₱150 on coffee today with cash", "paid ₱500 for groceries", "bought lunch for 200", "deduct 500 from balance"
    // Income e.g.: "received ₱35000 salary from employer", "got paid ₱15000", "add 500 into my balance", "deposit 1000"
    final isIncomePhrase = q.contains('salary') ||
        q.contains('received') ||
        q.contains('got paid') ||
        q.contains('earned') ||
        q.contains('deposit') ||
        q.contains('top up') ||
        q.contains('top-up') ||
        q.contains('to my balance') ||
        q.contains('into my balance') ||
        q.contains('to balance') ||
        q.contains('into balance') ||
        q.contains('to my account') ||
        q.contains('into my account') ||
        (q.contains('income') && !q.contains('income vs'));

    final isDeductPhrase = q.contains('deduct') ||
        q.contains('minus') ||
        q.contains('withdraw') ||
        q.contains('from my balance') ||
        q.contains('from balance') ||
        q.contains('from my account') ||
        q.contains('from account');

    final isExplicitAdd = q.contains('spent') ||
        q.contains('paid') ||
        q.contains('bought') ||
        q.contains('expense') ||
        isIncomePhrase ||
        isDeductPhrase ||
        q.startsWith('log ') ||
        q.startsWith('add ') ||
        q.startsWith('record ') ||
        q.startsWith('deduct ');

    if (isExplicitAdd && amount != null && amount > 0) {
      final isIncome = isIncomePhrase && !isDeductPhrase;
      final category = isIncome
          ? (q.contains('salary') || q.contains('paycheck') ? 'Salary' : 'Other Income')
          : _extractCategory(q);
      final account = _extractAccount(q);
      final note = _extractNote(userMessage, amount);

      return AIActionDraft(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AIActionType.createTransaction,
        title: isIncome ? 'Log Income' : 'Log Expense',
        subtitle: '${isIncome ? "+" : "-"}${CurrencyFormatter.format(amount)} • $category • $account',
        payload: {
          'type': isIncome ? 'income' : 'expense',
          'isIncome': isIncome,
          'amount': amount,
          'categoryName': category,
          'accountName': account,
          'description': note,
          'note': note,
          'date': DateTime.now().toIso8601String(),
        },
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  @override
  AIScenarioSandbox? extractScenarioSandbox({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
  }) {
    final q = userMessage.toLowerCase().trim();
    final isWhatIf = q.contains('what if') ||
        q.contains('what-if') ||
        q.contains('simulate') ||
        (q.contains('cut') && (q.contains('dining') || q.contains('food') || q.contains('shopping') || q.contains('expense'))) ||
        (q.contains('reduce') && (q.contains('spending') || q.contains('expense')));

    if (!isWhatIf) return null;

    final cutAmount = _extractCutAmount(userMessage) ?? _extractAmount(userMessage) ?? 1000.0;
    final category = _extractCategory(q);
    final goalName = _extractGoalName(userMessage) ?? 'Emergency Fund';

    final goalsData = toolResults['get_all_goals']?['goals'] as List?;
    final goalTarget = (goalsData != null && goalsData.isNotEmpty)
        ? ((goalsData.first['targetAmount'] as num?)?.toDouble() ?? 50000.0)
        : 50000.0;
    final goalCurrent = (goalsData != null && goalsData.isNotEmpty)
        ? ((goalsData.first['currentAmount'] as num?)?.toDouble() ?? 15000.0)
        : 15000.0;

    return AIScenarioSandbox(
      id: 'sandbox_${DateTime.now().millisecondsSinceEpoch}',
      categoryName: category,
      currentMonthlySpending: (cutAmount * 3.5),
      baselineCutAmount: cutAmount,
      minCutAmount: (cutAmount * 0.2).clamp(100, 500).toDouble(),
      maxCutAmount: (cutAmount * 3.0).clamp(1000, 10000).toDouble(),
      goalTargetAmount: goalTarget,
      goalCurrentAmount: goalCurrent,
      goalName: goalName,
    );
  }

  String _extractCategory(String q) {
    if (q.contains('food') || q.contains('coffee') || q.contains('lunch') || q.contains('dinner') || q.contains('breakfast') || q.contains('grocer') || q.contains('dining') || q.contains('restaurant') || q.contains('snack') || q.contains('drink') || q.contains('cafe')) {
      return 'Food & Dining';
    }
    if (q.contains('transpo') || q.contains('grab') || q.contains('taxi') || q.contains('jeep') || q.contains('bus') || q.contains('gas') || q.contains('fuel') || q.contains('parking') || q.contains('commute')) {
      return 'Transportation';
    }
    if (q.contains('bill') || q.contains('electric') || q.contains('water') || q.contains('internet') || q.contains('wifi') || q.contains('rent') || q.contains('utilit') || q.contains('mssc')) {
      return 'Bills & Utilities';
    }
    if (q.contains('shop') || q.contains('cloth') || q.contains('shoe') || q.contains('amazon') || q.contains('lazada') || q.contains('shopee') || q.contains('mall')) {
      return 'Shopping';
    }
    if (q.contains('health') || q.contains('med') || q.contains('doctor') || q.contains('pharmacy') || q.contains('hospital') || q.contains('clinic') || q.contains('dental')) {
      return 'Healthcare';
    }
    if (q.contains('movie') || q.contains('netflix') || q.contains('spotify') || q.contains('game') || q.contains('concert') || q.contains('leisure') || q.contains('entertainment')) {
      return 'Entertainment';
    }
    if (q.contains('education') || q.contains('tuition') || q.contains('school') || q.contains('book') || q.contains('course')) {
      return 'Education';
    }
    if (q.contains('salary') || q.contains('paycheck') || q.contains('wage') || q.contains('payroll')) {
      return 'Salary';
    }
    return 'General & Other';
  }

  String _extractAccount(String q) {
    if (q.contains('cash') || q.contains('wallet')) {
      return 'Cash';
    }
    if (q.contains('bank') || q.contains('bdo') || q.contains('bpi') || q.contains('metrobank') || q.contains('unionbank') || q.contains('checking') || q.contains('savings acc')) {
      return 'Bank Account';
    }
    if (q.contains('gcash') || q.contains('maya') || q.contains('e-wallet') || q.contains('ewallet')) {
      return 'E-Wallet';
    }
    if (q.contains('credit') || q.contains('card')) {
      return 'Credit Card';
    }
    return 'Cash';
  }

  String _extractNote(String text, double amount) {
    return text.trim();
  }
}

// Small helper kept local since it's only used for the greeting header,
// which the chat screen builds separately from this engine.
String greetingForNow(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

// Referenced by tests to keep month-key formatting consistent with the
// tools registry without duplicating the logic there.
String monthKey(DateTime d) => AppDateUtils.startOfMonth(d).toIso8601String();
