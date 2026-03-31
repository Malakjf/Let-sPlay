import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/language.dart';
import 'organization/models/match_player.dart';

class OrganizationExpensesScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic> match;
  final List<MatchPlayer> players;

  const OrganizationExpensesScreen({
    super.key,
    required this.ctrl,
    required this.match,
    required this.players,
  });

  @override
  State<OrganizationExpensesScreen> createState() =>
      _OrganizationExpensesScreenState();
}

class _OrganizationExpensesScreenState
    extends State<OrganizationExpensesScreen> {
  bool _isExporting = false;

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    final ar = widget.ctrl.isArabic;

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];

      // Headers
      List<CellValue> headers = [
        TextCellValue(ar ? 'اسم اللاعب' : 'Player Name'),
        TextCellValue(ar ? 'المبلغ' : 'Amount'),
        TextCellValue(ar ? 'طريقة الدفع' : 'Payment Method'),
        TextCellValue(ar ? 'التاريخ' : 'Date'),
      ];
      sheet.appendRow(headers);

      // Data
      final payments = widget.match['payments'] as Map<String, dynamic>? ?? {};

      for (var entry in payments.entries) {
        final playerId = entry.key;
        final paymentData = entry.value as Map<String, dynamic>;

        final player = widget.players.cast<MatchPlayer?>().firstWhere(
          (p) => p?.id == playerId,
          orElse: () => null,
        );

        final playerName = player?.name ?? (ar ? 'غير معروف' : 'Unknown');
        final amount = paymentData['amount'] ?? 0;
        final method = paymentData['method'] ?? '';
        final timestamp = paymentData['timestamp'] ?? '';

        // Format method
        String methodText = method;
        if (method == 'wallet') {
          methodText = ar ? 'محفظة' : 'Wallet';
        } else if (method == 'cash') {
          methodText = ar ? 'نقدي' : 'Cash';
        } else if (method == 'online') {
          methodText = ar ? 'اونلاين' : 'Online';
        } else if (method == 'cash_to_wallet') {
          methodText = ar ? 'نقدي للمحفظة' : 'Cash to Wallet';
        }

        List<CellValue> row = [
          TextCellValue(playerName),
          DoubleCellValue((amount is num) ? amount.toDouble() : 0.0),
          TextCellValue(methodText),
          TextCellValue(timestamp.toString().split('T')[0]),
        ];
        sheet.appendRow(row);
      }

      final fileBytes = excel.save();
      if (fileBytes == null) return;

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/match_expenses.xlsx';
      final file = File(path);
      await file.writeAsBytes(fileBytes);

      if (!mounted) return;

      await Share.shareXFiles([
        XFile(path),
      ], text: ar ? 'تقرير المصاريف' : 'Expenses Report');
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'فشل التصدير' : 'Export failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);
    final payments = widget.match['payments'] as Map<String, dynamic>? ?? {};
    final recharges =
        widget.match['walletRecharges'] as Map<String, dynamic>? ?? {};

    // Calculate total
    double total = 0;
    payments.forEach((_, data) {
      total += (data['amount'] as num?)?.toDouble() ?? 0;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'المصاريف' : 'Expenses'),
        actions: [
          if (payments.isNotEmpty)
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download),
              onPressed: _isExporting ? null : _exportToExcel,
              tooltip: ar ? 'تصدير اكسل' : 'Export Excel',
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'إجمالي المصاريف' : 'Total Expenses',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${total.toStringAsFixed(2)} ${ar ? 'د.ل' : 'PFJ'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: payments.isEmpty
                ? Center(
                    child: Text(
                      ar ? 'لا توجد مصاريف مسجلة' : 'No expenses recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final playerId = payments.keys.elementAt(index);
                      final data = payments[playerId] as Map<String, dynamic>;
                      final player = widget.players
                          .cast<MatchPlayer?>()
                          .firstWhere(
                            (p) => p?.id == playerId,
                            orElse: () => null,
                          );

                      String subtitle = data['method'];
                      if (data['method'] == 'cash_to_wallet' &&
                          recharges.containsKey(playerId)) {
                        final r = recharges[playerId];
                        subtitle = ar
                            ? 'نقدي: ${r['cashPaid']} | محفظة: +${r['walletAdded']} | مباراة: ${r['usedForMatch']}'
                            : 'Cash: ${r['cashPaid']} | Wallet: +${r['walletAdded']} | Match: ${r['usedForMatch']}';
                      } else {
                        subtitle = data['method'] == 'wallet'
                            ? (ar ? 'محفظة' : 'Wallet')
                            : data['method'] == 'cash'
                            ? (ar ? 'نقدي' : 'Cash')
                            : data['method'] == 'online'
                            ? (ar ? 'اونلاين' : 'Online')
                            : data['method'];
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (player?.avatarUrl != null &&
                                    player!.avatarUrl!.isNotEmpty &&
                                    (player.avatarUrl!.startsWith('http') ||
                                        player.avatarUrl!.startsWith('https')))
                                ? NetworkImage(player.avatarUrl!)
                                : null,
                            child:
                                (player?.avatarUrl == null ||
                                    player!.avatarUrl!.isEmpty ||
                                    !(player.avatarUrl!.startsWith('http') ||
                                        player.avatarUrl!.startsWith('https')))
                                ? Text(
                                    (player?.name != null &&
                                            player!.name.isNotEmpty)
                                        ? player.name[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(
                            player?.name ?? (ar ? 'غير معروف' : 'Unknown'),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${data['amount']} ${ar ? 'د.ل' : 'PFJ'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
