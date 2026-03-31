import 'package:flutter/material.dart';
import '../models/match_player.dart';

class PaymentBottomSheet extends StatefulWidget {
  final MatchPlayer player;
  final num matchFee;
  final String matchName;
  final bool isArabic;
  final Function(
    String method, {
    num? amount,
    num? cashPaid,
    num? walletAdded,
    num? matchUsed,
  })
  onPaymentMethodSelected;

  const PaymentBottomSheet({
    super.key,
    required this.player,
    required this.matchFee,
    required this.matchName,
    required this.isArabic,
    required this.onPaymentMethodSelected,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  String? _selectedMethod;

  // Controllers for cash_to_wallet
  final TextEditingController _cashPaidController = TextEditingController();
  final TextEditingController _matchUsedController = TextEditingController();
  final TextEditingController _walletAddedController = TextEditingController();

  // Focus nodes to track which field is being edited
  final FocusNode _cashPaidFocus = FocusNode();
  final FocusNode _matchUsedFocus = FocusNode();
  final FocusNode _walletAddedFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with defaults
    _matchUsedController.text = widget.matchFee.toString();
    _cashPaidController.text = widget.matchFee.toString();
    _walletAddedController.text = '0';

    // Add listeners for calculations
    _cashPaidController.addListener(_onCashPaidChanged);
    _matchUsedController.addListener(_onMatchUsedChanged);
    _walletAddedController.addListener(_onWalletAddedChanged);
  }

  @override
  void dispose() {
    _cashPaidController.dispose();
    _matchUsedController.dispose();
    _walletAddedController.dispose();
    _cashPaidFocus.dispose();
    _matchUsedFocus.dispose();
    _walletAddedFocus.dispose();
    super.dispose();
  }

  // Logic: Cash Paid changed -> Update Wallet Added
  void _onCashPaidChanged() {
    if (_cashPaidFocus.hasFocus) {
      final cashPaid = double.tryParse(_cashPaidController.text) ?? 0;
      final matchUsed = double.tryParse(_matchUsedController.text) ?? 0;
      final walletAdded = cashPaid - matchUsed;
      _updateController(_walletAddedController, walletAdded);
      setState(() {});
    }
  }

  // Logic: Match Used changed -> Update Wallet Added (keeping Cash Paid constant)
  void _onMatchUsedChanged() {
    if (_matchUsedFocus.hasFocus) {
      final cashPaid = double.tryParse(_cashPaidController.text) ?? 0;
      final matchUsed = double.tryParse(_matchUsedController.text) ?? 0;
      final walletAdded = cashPaid - matchUsed;
      _updateController(_walletAddedController, walletAdded);
      setState(() {});
    }
  }

  // Logic: Wallet Added changed -> Update Cash Paid (keeping Match Used constant)
  void _onWalletAddedChanged() {
    if (_walletAddedFocus.hasFocus) {
      final matchUsed = double.tryParse(_matchUsedController.text) ?? 0;
      final walletAdded = double.tryParse(_walletAddedController.text) ?? 0;
      final cashPaid = matchUsed + walletAdded;
      _updateController(_cashPaidController, cashPaid);
      setState(() {});
    }
  }

  void _updateController(TextEditingController controller, double value) {
    final text = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    if (controller.text != text) {
      controller.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = widget.isArabic;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ar ? 'دفع الرسوم' : 'Pay Fees',
                style: theme.textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.player.walletCredit} ${ar ? 'د.ل' : 'PFJ'}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Methods
          _buildMethodTile(
            'wallet',
            ar ? 'المحفظة' : 'Wallet',
            Icons.account_balance_wallet,
          ),
          _buildMethodTile('cash', ar ? 'نقدي' : 'Cash', Icons.money),
          _buildMethodTile(
            'online',
            ar ? 'اونلاين' : 'Online',
            Icons.credit_card,
          ),
          _buildMethodTile(
            'cash_to_wallet',
            ar ? 'نقدي + شحن محفظة' : 'Cash-to-Wallet',
            Icons.add_card,
          ),

          const SizedBox(height: 24),

          // Input Section based on selection
          if (_selectedMethod == 'cash_to_wallet')
            _buildCashToWalletInputs(ar, theme)
          else if (_selectedMethod != null)
            _buildStandardPaymentButton(ar, theme),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMethod = method;
            // Reset values when switching to cash_to_wallet
            if (method == 'cash_to_wallet') {
              _matchUsedController.text = widget.matchFee.toString();
              _cashPaidController.text = widget.matchFee.toString();
              _walletAddedController.text = '0';
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.cardColor,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashToWalletInputs(bool ar, ThemeData theme) {
    final cashPaid = double.tryParse(_cashPaidController.text) ?? 0;
    final matchUsed = double.tryParse(_matchUsedController.text) ?? 0;
    final walletAdded = double.tryParse(_walletAddedController.text) ?? 0;

    // Validation: Cash Paid must be positive, Match Used must be non-negative.
    // walletAdded can be negative (if paying part of match from existing wallet).
    final isValid = cashPaid > 0 && matchUsed >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Cash Paid
        TextField(
          controller: _cashPaidController,
          focusNode: _cashPaidFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ar ? 'المبلغ النقدي المدفوع' : 'Total Cash Paid',
            suffixText: ar ? 'د.ل' : 'PFJ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Used for Match
        TextField(
          controller: _matchUsedController,
          focusNode: _matchUsedFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ar ? 'مخصوم للمباراة' : 'Used for Match',
            suffixText: ar ? 'د.ل' : 'PFJ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        // 3. Added to Wallet (Now Editable)
        TextField(
          controller: _walletAddedController,
          focusNode: _walletAddedFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ar ? 'يضاف للمحفظة' : 'Added to Wallet',
            suffixText: ar ? 'د.ل' : 'PFJ',
            prefixIcon: const Icon(
              Icons.add_circle_outline,
              color: Colors.green,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid
                ? () {
                    Navigator.pop(context);
                    widget.onPaymentMethodSelected(
                      'cash_to_wallet',
                      cashPaid: cashPaid,
                      walletAdded: walletAdded,
                      matchUsed: matchUsed,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(ar ? 'تأكيد العملية' : 'Confirm Transaction'),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardPaymentButton(bool ar, ThemeData theme) {
    // For standard methods, we also allow manual amount entry if needed,
    // but defaulting to match fee is standard.
    // To strictly follow "Manual input for every method", we can add an input here too,
    // or just assume the user accepts the match fee.
    // Given the context of "Manual input", let's add a simple amount field for standard payments too.

    final TextEditingController standardAmountCtrl = TextEditingController(
      text: widget.matchFee.toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: standardAmountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ar ? 'المبلغ' : 'Amount',
            suffixText: ar ? 'د.أ' : 'JOD',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(standardAmountCtrl.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                widget.onPaymentMethodSelected(
                  _selectedMethod!,
                  amount: amount,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(ar ? 'تأكيد الدفع' : 'Confirm Payment'),
          ),
        ),
      ],
    );
  }
}
