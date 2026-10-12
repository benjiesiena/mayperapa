import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onFinished;

  const OnboardingScreen({super.key, this.onFinished});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Currency
  String _selectedCurrency = 'PHP';

  // Step 2: Balances
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _eWalletController = TextEditingController();
  String _selectedEWallet = 'GCash';

  // Step 3: PIN
  final TextEditingController _pinController = TextEditingController();
  bool _setupPin = false;
  bool _completing = false;

  static const _supportedCurrencies = [
    {'code': 'PHP', 'symbol': '₱', 'name': 'Philippine Peso'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _cashController.dispose();
    _eWalletController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevPage() {
    HapticFeedback.selectionClick();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _completing = true);
    HapticFeedback.mediumImpact();

    final cashAmount = double.tryParse(_cashController.text.trim());
    final eWalletAmount = double.tryParse(_eWalletController.text.trim());
    final pin = _setupPin && _pinController.text.length == 4 ? _pinController.text : null;

    try {
      await ref.read(onboardingCompletedProvider.notifier).completeOnboarding(
            currencyCode: _selectedCurrency,
            initialCash: cashAmount,
            initialEWallet: eWalletAmount,
            eWalletName: _selectedEWallet,
            pin: pin,
          );

      if (mounted) setState(() => _completing = false);
      widget.onFinished?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete onboarding: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back & step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _prevPage,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? palette.primary : palette.border,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1Currency(context),
                  _buildStep2StartingBalances(context),
                  _buildStep3MayaAndSecurity(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Currency Selection
  // ---------------------------------------------------------------------------
  Widget _buildStep1Currency(BuildContext context) {
    final palette = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to MayPeraPa',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your private, on-device financial companion. Select your default currency:',
            style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: _supportedCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final curr = _supportedCurrencies[index];
                final isSelected = curr['code'] == _selectedCurrency;

                return TactileBounce(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCurrency = curr['code']!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.primary.withValues(alpha: 0.1) : palette.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? palette.primary : palette.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            curr['symbol']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                curr['name']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Text(
                                curr['code']!,
                                style: TextStyle(fontSize: 12, color: palette.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: palette.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TactileBounce(
              onTap: _nextPage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Starting Balances & Wallets
  // ---------------------------------------------------------------------------
  Widget _buildStep2StartingBalances(BuildContext context) {
    final palette = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starting Balances',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your current balances so Maya can provide accurate insights from day one.',
            style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cash in Hand
                  Text(
                    'PHYSICAL CASH',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _cashController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cash in Hand',
                      hintText: 'e.g. 1500',
                      prefixText: '$_selectedCurrency ',
                      filled: true,
                      fillColor: palette.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Digital Wallet Selector
                  Text(
                    'DIGITAL WALLET',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: ['GCash', 'Maya', 'ShopeePay'].map((name) {
                      final isSelected = name == _selectedEWallet;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedEWallet = name),
                          selectedColor: palette.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? palette.primary : palette.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _eWalletController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '$_selectedEWallet Balance',
                      hintText: 'e.g. 5000',
                      prefixText: '$_selectedCurrency ',
                      filled: true,
                      fillColor: palette.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You can always add more bank accounts and credit cards later.',
                    style: TextStyle(fontSize: 12, color: palette.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _nextPage,
                  child: Text('Skip for now', style: TextStyle(color: palette.textSecondary)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TactileBounce(
                  onTap: _nextPage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Maya & Security PIN
  // ---------------------------------------------------------------------------
  Widget _buildStep3MayaAndSecurity(BuildContext context) {
    final palette = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet Maya',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your on-device financial copilot and privacy guard.',
            style: TextStyle(fontSize: 14, color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Maya Introduction Card (Solid tailored surface, 1px border)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: palette.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.auto_awesome, color: palette.primary, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maya Financial Co-Pilot',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Local & Privacy First',
                                  style: TextStyle(fontSize: 11, color: palette.positive, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'I run completely on your device. I help analyze spending trends, calculate affordability, and plan budgets without your financial data ever leaving your hands.',
                          style: TextStyle(fontSize: 13, color: palette.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Optional PIN Setup
                  Text(
                    'SECURITY SETUP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Protect app with 4-Digit PIN',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: palette.textPrimary),
                    ),
                    subtitle: Text(
                      'Require PIN upon opening MayPeraPa',
                      style: TextStyle(fontSize: 12, color: palette.textSecondary),
                    ),
                    value: _setupPin,
                    onChanged: (val) => setState(() => _setupPin = val ?? false),
                    activeColor: palette.primary,
                  ),
                  if (_setupPin) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: 'Enter 4-Digit PIN',
                        hintText: '••••',
                        filled: true,
                        fillColor: palette.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TactileBounce(
              onTap: _completing ? null : _finishOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: _completing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Launch MayPeraPa',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
