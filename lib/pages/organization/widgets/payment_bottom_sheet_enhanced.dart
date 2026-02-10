import 'package:flutter/material.dart';
import '../models/match_player.dart';

/// Enhanced Payment Bottom Sheet with full payment flow
/// Supports: Wallet, Cash-to-Wallet, Cash, Online
class PaymentBottomSheet extends StatefulWidget {
  final MatchPlayer player;
  final num matchFee;
  final String matchName;
  final bool isArabic;
  final Function(String paymentMethod, {num? amount}) onPaymentMethodSelected;

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
  final TextEditingController _amountController = TextEditingController();
  bool _showAmountInput = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.matchFee.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = widget.isArabic;

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with wallet balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ar ? 'ادفع' : 'Pay'} ${widget.matchFee} ${ar ? 'د.ل' : 'PFJ'}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.player.walletCredit} ${ar ? 'د.ل' : 'PFJ'}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.matchName,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          Text(
            widget.player.name,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 24),

          // Payment Methods
          Text(
            ar ? 'اختر طريقة الدفع' : 'Select payment method',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Wallet Option
          _buildPaymentMethodButton(
            context,
            icon: Icons.account_balance_wallet,
            label: ar ? 'المحفظة' : 'Wallet',
            subtitle: widget.player.walletCredit >= widget.matchFee
                ? (ar ? 'رصيد كافي' : 'Sufficient balance')
                : (ar ? 'رصيد غير كافي' : 'Insufficient balance'),
            method: 'wallet',
            isEnabled: widget.player.walletCredit >= widget.matchFee,
            isPrimary: true,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Cash-to-Wallet Option
          _buildPaymentMethodButton(
            context,
            icon: Icons.attach_money,
            label: ar ? 'نقدي إلى المحفظة' : 'Cash-to-Wallet',
            subtitle: ar
                ? 'إضافة نقدي للمحفظة ثم الدفع'
                : 'Add cash to wallet then pay',
            method: 'cash_to_wallet',
            isEnabled: true,
            isPrimary: false,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Cash Option
          _buildPaymentMethodButton(
            context,
            icon: Icons.money,
            label: ar ? 'نقدي' : 'Cash',
            subtitle: ar ? 'تسجيل كدفع نقدي' : 'Record as cash payment',
            method: 'cash',
            isEnabled: true,
            isPrimary: false,
            theme: theme,
          ),
          const SizedBox(height: 12),

          // Online Option
          _buildPaymentMethodButton(
            context,
            icon: Icons.credit_card,
            label: ar ? 'عبر الإنترنت' : 'Online',
            subtitle: ar
                ? 'بطاقة ائتمان أو محفظة إلكترونية'
                : 'Credit card or e-wallet',
            method: 'online',
            isEnabled: true,
            isPrimary: false,
            theme: theme,
          ),

          // Amount Input (for wallet/cash-to-wallet)
          if (_showAmountInput) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              ar ? 'أدخل المبلغ' : 'Enter amount',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: ar ? 'د.ل' : 'PFJ',
                suffixStyle: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white60,
                ),
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = num.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ar
                              ? 'الرجاء إدخال مبلغ صحيح'
                              : 'Please enter a valid amount',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  widget.onPaymentMethodSelected(
                    _selectedMethod!,
                    amount: amount,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  ar ? 'تأكيد الدفع' : 'Confirm Payment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Cancel
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                ar ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required String method,
    required bool isEnabled,
    required bool isPrimary,
    required ThemeData theme,
  }) {
    final isSelected = _selectedMethod == method;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  if (method == 'wallet' || method == 'cash_to_wallet') {
                    setState(() {
                      _selectedMethod = method;
                      _showAmountInput = true;
                    });
                  } else {
                    Navigator.pop(context);
                    widget.onPaymentMethodSelected(method);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : (isPrimary ? theme.colorScheme.primary : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isPrimary && !isSelected
                        ? Colors.white
                        : (isSelected
                              ? theme.colorScheme.primary
                              : Colors.black87),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPrimary && !isSelected
                                ? Colors.white
                                : (isSelected ? Colors.white : Colors.black),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPrimary && !isSelected
                                ? Colors.white70
                                : (isSelected
                                      ? Colors.white60
                                      : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
