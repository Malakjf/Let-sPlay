import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../services/language.dart';
import '../../services/firebase_service.dart';
import '../../widgets/LogoButton.dart' show LogoButton;

/// Management Reports Page - Read-only financial reports
/// Aggregates data from Organization expenses, Match players, and Payments
class ReportsScreen extends StatefulWidget {
  final LocaleController ctrl;
  const ReportsScreen({super.key, required this.ctrl});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _selectedMatchId;

  // Aggregated report data
  double _totalCollected = 0;
  double _totalExpenses = 0;
  double _netBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
    _loadCurrentUserPermission();
  }

  Future<void> _loadCurrentUserPermission() async {
    try {
      await _firebaseService.getCurrentUserRole();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading user permission: $e');
    }
  }

  Future<void> _loadReportData() async {
    try {
      final matches = await _firebaseService.getMatches();

      // Calculate totals
      double totalCollected = 0;
      double totalExpenses = 0;

      for (var match in matches) {
        // Calculate collected from payments
        final payments = match['payments'] as Map<String, dynamic>? ?? {};
        for (var payment in payments.values) {
          if (payment is Map) {
            totalCollected += (payment['amount'] as num?)?.toDouble() ?? 0;
          }
        }

        // Calculate expenses
        final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
        totalExpenses += (expenses['referee'] as num?)?.toDouble() ?? 0;
        totalExpenses += (expenses['organizer'] as num?)?.toDouble() ?? 0;
        totalExpenses += (expenses['pitch'] as num?)?.toDouble() ?? 0;
        totalExpenses += (expenses['water'] as num?)?.toDouble() ?? 0;
        totalExpenses += (expenses['other'] as num?)?.toDouble() ?? 0;
      }

      setState(() {
        _matches = matches;
        _totalCollected = totalCollected;
        _totalExpenses = totalExpenses;
        _netBalance = totalCollected - totalExpenses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading report data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text(
                ar ? 'التقارير المالية' : 'Financial Reports',
                style: theme.textTheme.titleMedium,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: ar ? 'نسخ التقرير' : 'Copy Report',
                  onPressed: () => _copyReportToClipboard(ar),
                ),
                IconButton(
                  icon: const Icon(Icons.table_chart),
                  tooltip: ar ? 'تصدير Excel' : 'Export Excel',
                  onPressed: _isExporting
                      ? null
                      : () => _exportAllReportsExcel(ar),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: ar ? 'تصدير PDF' : 'Export PDF',
                  onPressed: _isExporting
                      ? null
                      : () => _exportAllReportsPDF(ar),
                ),
                const LogoButton(),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Summary Cards
                      _buildSummaryCards(ar, theme),
                      const Divider(height: 1, color: Colors.white10),
                      // Matches List
                      Expanded(
                        child: _matches.isEmpty
                            ? Center(
                                child: Text(
                                  ar
                                      ? 'لا توجد تقارير'
                                      : 'No reports available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white60,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _matches.length,
                                itemBuilder: (context, index) {
                                  final match = _matches[index];
                                  final matchId = match['id'] as String?;
                                  final isExpanded =
                                      _selectedMatchId == matchId;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildMatchReportCard(
                                      match,
                                      isExpanded,
                                      ar,
                                      theme,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(bool ar, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              ar ? 'إجمالي المحصّل' : 'Total Collected',
              _totalCollected,
              Colors.green,
              Icons.arrow_upward,
              ar,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              ar ? 'إجمالي المصاريف' : 'Total Expenses',
              _totalExpenses,
              Colors.orange,
              Icons.arrow_downward,
              ar,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              ar ? 'الرصيد الصافي' : 'Net Balance',
              _netBalance,
              _netBalance >= 0 ? Colors.blue : Colors.red,
              Icons.account_balance_wallet,
              ar,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    double amount,
    Color color,
    IconData icon,
    bool ar,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${amount.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchReportCard(
    Map<String, dynamic> match,
    bool isExpanded,
    bool ar,
    ThemeData theme,
  ) {
    final matchId = match['id'] as String?;
    final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
    final payments = match['payments'] as Map<String, dynamic>? ?? {};

    // Calculate match totals
    double matchExpenses = 0;
    matchExpenses += (expenses['referee'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['organizer'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['pitch'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['water'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['other'] as num?)?.toDouble() ?? 0;

    double matchCollected = 0;
    for (var payment in payments.values) {
      if (payment is Map) {
        matchCollected += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final matchBalance = matchCollected - matchExpenses;

    return Container(
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedMatchId = isExpanded ? null : matchId;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.summarize,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['name'] ?? match['title'] ?? 'Match',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${match['date'] ?? ''} • ${match['field'] ?? ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${matchBalance >= 0 ? '+' : ''}${matchBalance.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: matchBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () =>
                                _copyMatchReportToClipboard(match, ar),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf, size: 20),
                            onPressed: () => _exportMatchReportPDF(match, ar),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white60,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            _buildMatchReportDetails(match, ar, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchReportDetails(
    Map<String, dynamic> match,
    bool ar,
    ThemeData theme,
  ) {
    final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
    final payments = match['payments'] as Map<String, dynamic>? ?? {};
    final players = match['players'] as List? ?? [];
    final recharges = match['walletRecharges'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Players & Payments Section
          Text(
            ar ? 'اللاعبون والمدفوعات' : 'PLAYERS & PAYMENTS',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Text(
              ar ? 'لا يوجد لاعبين' : 'No players',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white30,
              ),
            )
          else
            ...players.map((playerId) {
              final playerPayment =
                  payments[playerId.toString()] as Map<String, dynamic>? ?? {};
              final amount = (playerPayment['amount'] as num?)?.toDouble() ?? 0;
              final method = playerPayment['method'] as String? ?? 'unpaid';
              final isPaid = amount > 0;

              return FutureBuilder(
                future: _firebaseService.getUserData(playerId.toString()),
                builder: (context, snapshot) {
                  final playerName =
                      snapshot.data?['name'] ??
                      snapshot.data?['username'] ??
                      'Player';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.2),
                          child: Text(
                            playerName.isNotEmpty
                                ? playerName[0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (method != 'unpaid')
                                if (method == 'cash_to_wallet' &&
                                    recharges.containsKey(playerId.toString()))
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPaymentMethodLabel(method, ar),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: _getPaymentMethodColor(
                                                method,
                                              ),
                                              fontSize: 10,
                                            ),
                                      ),
                                      Text(
                                        ar
                                            ? 'نقدي: ${recharges[playerId.toString()]['cashPaid']} | مباراة: ${recharges[playerId.toString()]['usedForMatch']} | محفظة: ${recharges[playerId.toString()]['walletAdded']}'
                                            : 'Cash: ${recharges[playerId.toString()]['cashPaid']} | Match: ${recharges[playerId.toString()]['usedForMatch']} | Wallet: ${recharges[playerId.toString()]['walletAdded']}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.grey,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    _getPaymentMethodLabel(method, ar),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _getPaymentMethodColor(method),
                                      fontSize: 10,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPaid
                                ? '${amount.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}'
                                : (ar ? 'غير مدفوع' : 'Unpaid'),
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),

          const SizedBox(height: 24),

          // Expenses Section
          Text(
            ar ? 'المصاريف' : 'EXPENSES',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildExpenseReadOnlyRow(
            Icons.sports,
            ar ? 'الحكم' : 'Referee',
            expenses['referee'],
            ar,
            theme,
          ),
          _buildExpenseReadOnlyRow(
            Icons.person,
            ar ? 'المنظم' : 'Organizer',
            expenses['organizer'],
            ar,
            theme,
          ),
          _buildExpenseReadOnlyRow(
            Icons.stadium,
            ar ? 'الملعب' : 'Pitch',
            expenses['pitch'],
            ar,
            theme,
          ),
          _buildExpenseReadOnlyRow(
            Icons.water_drop,
            ar ? 'الماء' : 'Water',
            expenses['water'],
            ar,
            theme,
          ),
          _buildExpenseReadOnlyRow(
            Icons.list,
            ar ? 'أخرى' : 'Other',
            expenses['other'],
            ar,
            theme,
          ),

          if (expenses['comments'] != null &&
              expenses['comments'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              ar ? 'ملاحظات' : 'Notes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                expenses['comments'].toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseReadOnlyRow(
    IconData icon,
    String label,
    dynamic amount,
    bool ar,
    ThemeData theme,
  ) {
    final value = (amount as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '${value.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: value > 0 ? Colors.orange : Colors.white30,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method, bool ar) {
    switch (method) {
      case 'wallet':
        return ar ? 'محفظة' : 'Wallet';
      case 'cash':
        return ar ? 'نقدي' : 'Cash';
      case 'cash_to_wallet':
        return ar ? 'نقدي → محفظة' : 'Cash → Wallet';
      case 'online':
        return ar ? 'أونلاين' : 'Online';
      default:
        return method;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'wallet':
        return Colors.blue;
      case 'cash':
        return Colors.amber;
      case 'cash_to_wallet':
        return Colors.teal;
      case 'online':
        return Colors.purple;
      default:
        return Colors.white60;
    }
  }

  void _copyReportToClipboard(bool ar) {
    final buffer = StringBuffer();
    buffer.writeln('=== ${ar ? 'التقرير المالي' : 'FINANCIAL REPORT'} ===');
    buffer.writeln(
      '${ar ? 'التاريخ' : 'Date'}: ${DateTime.now().toString().split('.')[0]}',
    );
    buffer.writeln('');
    buffer.writeln('${ar ? 'الملخص' : 'SUMMARY'}:');
    buffer.writeln(
      '${ar ? 'إجمالي المحصّل' : 'Total Collected'}: ${_totalCollected.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );
    buffer.writeln(
      '${ar ? 'إجمالي المصاريف' : 'Total Expenses'}: ${_totalExpenses.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );
    buffer.writeln(
      '${ar ? 'الرصيد الصافي' : 'Net Balance'}: ${_netBalance.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );
    buffer.writeln('');
    buffer.writeln('${ar ? 'المباريات' : 'MATCHES'}: ${_matches.length}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ar ? 'تم نسخ التقرير' : 'Report copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyMatchReportToClipboard(Map<String, dynamic> match, bool ar) {
    final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
    final payments = match['payments'] as Map<String, dynamic>? ?? {};
    final players = match['players'] as List? ?? [];

    double matchExpenses = 0;
    matchExpenses += (expenses['referee'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['organizer'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['pitch'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['water'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['other'] as num?)?.toDouble() ?? 0;

    double matchCollected = 0;
    for (var payment in payments.values) {
      if (payment is Map) {
        matchCollected += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('=== ${match['name'] ?? 'Match'} ===');
    buffer.writeln('${match['date'] ?? ''} • ${match['field'] ?? ''}');
    buffer.writeln('');
    buffer.writeln('${ar ? 'اللاعبون' : 'Players'}: ${players.length}');
    buffer.writeln(
      '${ar ? 'المحصّل' : 'Collected'}: ${matchCollected.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );
    buffer.writeln(
      '${ar ? 'المصاريف' : 'Expenses'}: ${matchExpenses.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );
    buffer.writeln(
      '${ar ? 'الصافي' : 'Net'}: ${(matchCollected - matchExpenses).toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
    );

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ar ? 'تم نسخ تقرير المباراة' : 'Match report copied'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportMatchReportPDF(
    Map<String, dynamic> match,
    bool ar,
  ) async {
    try {
      final pdf = pw.Document();

      // Fetch player names for this match
      final playersList = match['players'] as List? ?? [];
      final Map<String, String> userMap = {};

      for (var pid in playersList) {
        final data = await _firebaseService.getUserData(pid.toString());
        userMap[pid.toString()] = data['name'] ?? data['username'] ?? 'Player';
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    match['name'] ?? 'Match Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textDirection: ar
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfMatchSection(match, userMap, ar),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, stack) {
      debugPrint('❌ PDF export failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAllReportsExcel(bool ar) async {
    try {
      // Show loading indicator (if using setState, set _isExporting = true)
      if (mounted) setState(() => _isExporting = true);

      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Financial Report'];

      // Add header
      sheet.appendRow([
        excel_pkg.TextCellValue(
          ar
              ? 'التقرير المالي - جميع المباريات'
              : 'Financial Report - All Matches',
        ),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(
          '${ar ? 'تاريخ الإنشاء' : 'Generated'}: ${DateTime.now().toString().split('.')[0]}',
        ),
      ]);
      sheet.appendRow([]); // Empty row

      // Overall Summary
      sheet.appendRow([
        excel_pkg.TextCellValue(ar ? 'الملخص العام' : 'OVERALL SUMMARY'),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(ar ? 'إجمالي المحصّل' : 'Total Collected'),
        excel_pkg.TextCellValue('${_totalCollected.toStringAsFixed(2)} JOD'),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(ar ? 'إجمالي المصاريف' : 'Total Expenses'),
        excel_pkg.TextCellValue('${_totalExpenses.toStringAsFixed(2)} JOD'),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(ar ? 'الرصيد الصافي' : 'Net Balance'),
        excel_pkg.TextCellValue('${_netBalance.toStringAsFixed(2)} JOD'),
      ]);
      sheet.appendRow([]); // Empty row

      // Matches header
      sheet.appendRow([
        excel_pkg.TextCellValue(
          '${ar ? 'المباريات' : 'MATCHES'} (${_matches.length})',
        ),
      ]);
      sheet.appendRow([
        excel_pkg.TextCellValue(ar ? 'اسم المباراة' : 'Match Name'),
        excel_pkg.TextCellValue(ar ? 'التاريخ' : 'Date'),
        excel_pkg.TextCellValue(ar ? 'الملعب' : 'Field'),
        excel_pkg.TextCellValue(ar ? 'المصاريف' : 'Expenses'),
        excel_pkg.TextCellValue(ar ? 'المحصّل' : 'Collected'),
        excel_pkg.TextCellValue(ar ? 'الصافي' : 'Net'),
      ]);

      // Add match data
      for (var match in _matches) {
        final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
        double matchExpenses = 0;
        matchExpenses += (expenses['referee'] as num?)?.toDouble() ?? 0;
        matchExpenses += (expenses['organizer'] as num?)?.toDouble() ?? 0;
        matchExpenses += (expenses['pitch'] as num?)?.toDouble() ?? 0;
        matchExpenses += (expenses['water'] as num?)?.toDouble() ?? 0;
        matchExpenses += (expenses['other'] as num?)?.toDouble() ?? 0;

        // Calculate collected for this match
        final payments = match['payments'] as Map<String, dynamic>? ?? {};
        double matchCollected = 0;
        for (var payment in payments.values) {
          if (payment is Map) {
            matchCollected += (payment['amount'] as num?)?.toDouble() ?? 0;
          }
        }

        sheet.appendRow([
          excel_pkg.TextCellValue(match['name'] ?? 'Match'),
          excel_pkg.TextCellValue(match['date'] ?? ''),
          excel_pkg.TextCellValue(match['field'] ?? ''),
          excel_pkg.TextCellValue('${matchExpenses.toStringAsFixed(2)} JOD'),
          excel_pkg.TextCellValue('${matchCollected.toStringAsFixed(2)} JOD'),
          excel_pkg.TextCellValue(
            '${(matchCollected - matchExpenses).toStringAsFixed(2)} JOD',
          ),
        ]);
      }

      // Save and share
      final directory = await getTemporaryDirectory();
      final fileName =
          'financial_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: ar ? 'التقرير المالي' : 'Financial Report');
      debugPrint('Excel file exported and shared: ${file.path}');
    } catch (e, stack) {
      debugPrint('❌ Excel export failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Excel export failed: $e')));
      }
    } finally {
      // Hide loading indicator
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportAllReportsPDF(bool ar) async {
    try {
      if (mounted) setState(() => _isExporting = true);

      final pdf = pw.Document();

      // Load logo
      final logoImage = await rootBundle.load('assets/images/logo.png');
      final logoBytes = logoImage.buffer.asUint8List();

      // Fetch all users for names
      final users = await _firebaseService.getAllUsers(limit: 1000);
      final Map<String, String> userMap = {
        for (var u in users)
          u['uid'].toString(): (u['name'] ?? u['username'] ?? 'Player')
              .toString(),
      };

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  children: [
                    pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        ar
                            ? 'التقرير المالي - جميع المباريات'
                            : 'Financial Report - All Matches',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textDirection: ar
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Generated: ${DateTime.now().toString().split('.')[0]}'),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  children: [
                    pw.Text(
                      ar ? 'الملخص العام' : 'OVERALL SUMMARY',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                      textDirection: ar
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                    ),
                    pw.SizedBox(height: 10),
                    _buildPdfSummaryRow(
                      ar ? 'إجمالي المحصّل' : 'Total Collected',
                      _totalCollected,
                      ar,
                    ),
                    _buildPdfSummaryRow(
                      ar ? 'إجمالي المصاريف' : 'Total Expenses',
                      _totalExpenses,
                      ar,
                    ),
                    pw.Divider(),
                    _buildPdfSummaryRow(
                      ar ? 'الرصيد الصافي' : 'Net Balance',
                      _netBalance,
                      ar,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${ar ? 'المباريات' : 'MATCHES'} (${_matches.length})',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
                textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.SizedBox(height: 10),
              ..._matches.map((match) {
                return _buildPdfMatchSection(match, userMap, ar);
              }),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e, stack) {
      debugPrint('❌ PDF export failed: $e');
      debugPrint(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildPdfSummaryRow(
    String label,
    double amount,
    bool ar, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.Text(
          '${amount.toStringAsFixed(2)} ${ar ? 'د.أ' : 'JOD'}',
          style: isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      ],
    );
  }

  pw.Widget _buildPdfMatchSection(
    Map<String, dynamic> match,
    Map<String, String> userMap,
    bool ar,
  ) {
    final expenses = match['expenses'] as Map<String, dynamic>? ?? {};
    final payments = match['payments'] as Map<String, dynamic>? ?? {};
    final players = match['players'] as List? ?? [];
    final recharges = match['walletRecharges'] as Map<String, dynamic>? ?? {};

    // Calculate totals
    double matchExpenses = 0;
    matchExpenses += (expenses['referee'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['organizer'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['pitch'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['water'] as num?)?.toDouble() ?? 0;
    matchExpenses += (expenses['other'] as num?)?.toDouble() ?? 0;

    double matchCollected = 0;
    for (var payment in payments.values) {
      if (payment is Map) {
        matchCollected += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Match Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                match['name'] ?? 'Match',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              ),
              pw.Text(
                '${match['date'] ?? ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Text(
            match['field'] ?? '',
            style: const pw.TextStyle(fontSize: 10),
            textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.Divider(),

          // Financials
          _buildPdfSummaryRow(ar ? 'المحصّل' : 'Collected', matchCollected, ar),
          _buildPdfSummaryRow(ar ? 'المصاريف' : 'Expenses', matchExpenses, ar),
          _buildPdfSummaryRow(
            ar ? 'الصافي' : 'Net',
            matchCollected - matchExpenses,
            ar,
            isBold: true,
          ),
          pw.SizedBox(height: 10),

          // Expenses Breakdown
          if (matchExpenses > 0) ...[
            pw.Text(
              ar ? 'تفاصيل المصاريف' : 'Expenses Breakdown',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            ),
            _buildPdfExpenseRow(
              ar ? 'حكم' : 'Referee',
              expenses['referee'],
              ar,
            ),
            _buildPdfExpenseRow(
              ar ? 'منظم' : 'Organizer',
              expenses['organizer'],
              ar,
            ),
            _buildPdfExpenseRow(ar ? 'ملعب' : 'Pitch', expenses['pitch'], ar),
            _buildPdfExpenseRow(ar ? 'ماء' : 'Water', expenses['water'], ar),
            _buildPdfExpenseRow(ar ? 'أخرى' : 'Other', expenses['other'], ar),
            pw.SizedBox(height: 10),
          ],

          // Players
          pw.Text(
            '${ar ? 'اللاعبون' : 'Players'} (${players.length})',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          ),
          pw.SizedBox(height: 5),
          ...players.map((playerId) {
            final pid = playerId.toString();
            final name = userMap[pid] ?? 'Player';
            final payment = payments[pid] as Map<String, dynamic>? ?? {};
            final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
            final method = payment['method'] as String? ?? 'unpaid';

            String details = '';
            if (method == 'cash_to_wallet' && recharges.containsKey(pid)) {
              final r = recharges[pid];
              details = ar
                  ? '(نقدي: ${r['cashPaid']}, محفظة: ${r['walletAdded']}, مباراة: ${r['usedForMatch']})'
                  : '(Cash: ${r['cashPaid']}, Wallet: ${r['walletAdded']}, Match: ${r['usedForMatch']})';
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '$name ${details.isNotEmpty ? details : ""}',
                      style: const pw.TextStyle(fontSize: 9),
                      textDirection: ar
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                    ),
                  ),
                  pw.Text(
                    amount > 0
                        ? '${amount.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}'
                        : (ar ? 'غير مدفوع' : 'Unpaid'),
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: amount > 0 ? PdfColors.green : PdfColors.red,
                    ),
                    textDirection: ar
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  pw.Widget _buildPdfExpenseRow(String label, dynamic amount, bool ar) {
    final val = (amount as num?)?.toDouble() ?? 0;
    if (val == 0) return pw.SizedBox();
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9),
          textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
        pw.Text(
          '${val.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
          style: const pw.TextStyle(fontSize: 9),
          textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        ),
      ],
    );
  }
}
