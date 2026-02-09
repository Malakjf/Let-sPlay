import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';

class SendReportDialog extends StatelessWidget {
  final Map<String, dynamic> match;
  final List<Map<String, dynamic>> players;
  final Map<String, dynamic> expenses;
  final String matchName;
  final String matchDate;
  final String fieldName;

  const SendReportDialog({
    super.key,
    required this.match,
    required this.players,
    required this.expenses,
    required this.matchName,
    required this.matchDate,
    required this.fieldName,
  });

  Future<void> _exportExcel(BuildContext context) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];
    sheet.appendRow([
      TextCellValue('Match Name'),
      TextCellValue('Match Date'),
      TextCellValue('Player Name'),
      TextCellValue('Role'),
      TextCellValue('Payment Method'),
      TextCellValue('Paid Amount'),
      TextCellValue('Wallet Change'),
      TextCellValue('Referee Expense'),
      TextCellValue('Organizer Expense'),
      TextCellValue('Pitch Expense'),
      TextCellValue('Water Expense'),
      TextCellValue('Other Expense'),
    ]);
    for (final player in players) {
      sheet.appendRow([
        TextCellValue(matchName),
        TextCellValue(matchDate),
        TextCellValue(player['name']?.toString() ?? ''),
        TextCellValue(player['role']?.toString() ?? ''),
        TextCellValue(player['paymentMethod']?.toString() ?? ''),
        DoubleCellValue((player['paidAmount'] ?? 0).toDouble()),
        DoubleCellValue((player['walletChange'] ?? 0).toDouble()),
        DoubleCellValue((expenses['referee'] ?? 0).toDouble()),
        DoubleCellValue((expenses['organizer'] ?? 0).toDouble()),
        DoubleCellValue((expenses['pitch'] ?? 0).toDouble()),
        DoubleCellValue((expenses['water'] ?? 0).toDouble()),
        DoubleCellValue((expenses['other'] ?? 0).toDouble()),
      ]);
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/match_report.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Match Report Excel');
  }

  Future<void> _exportPDF(BuildContext context) async {
    final pdf = pw.Document();
    // Language detection
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final labels = isArabic
        ? {
            'report': 'تقرير المباراة',
            'players': 'اللاعبون',
            'paid': 'المدفوعين',
            'collected': 'إجمالي المحصّل',
            'expenses': 'إجمالي المصاريف',
            'net': 'الصافي',
            'expensesSection': 'المصاريف',
            'matchName': 'اسم المباراة',
            'date': 'التاريخ',
            'field': 'الملعب',
          }
        : {
            'report': 'Match Report',
            'players': 'Players',
            'paid': 'Paid',
            'collected': 'Total Collected',
            'expenses': 'Total Expenses',
            'net': 'Net Balance',
            'expensesSection': 'Expenses',
            'matchName': 'Match Name',
            'date': 'Date',
            'field': 'Field',
          };

    // Load logo asset
    final logoBytes = await DefaultAssetBundle.of(
      context,
    ).load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // Load font for Arabic
    pw.Font? cairoFont;
    if (isArabic) {
      cairoFont = pw.Font.ttf(
        (await rootBundle.load('assets/fonts/Cairo-Regular.ttf')),
      );
    }

    final pw.TextStyle headerStyle = isArabic
        ? pw.TextStyle(
            font: cairoFont,
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
          )
        : pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle labelStyle = isArabic
        ? pw.TextStyle(font: cairoFont, fontSize: 14)
        : const pw.TextStyle(fontSize: 14);
    final pw.TextStyle tableHeaderStyle = isArabic
        ? pw.TextStyle(
            font: cairoFont,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          )
        : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle tableCellStyle = isArabic
        ? pw.TextStyle(font: cairoFont, fontSize: 12)
        : const pw.TextStyle(fontSize: 12);

    pdf.addPage(
      pw.MultiPage(
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Image(logoImage, width: 80, height: 80),
                pw.SizedBox(height: 8),
                pw.Text('LetsPlay', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text(labels['report']!, style: headerStyle)),
          pw.SizedBox(height: 8),
          pw.Text('${labels['matchName']!}: $matchName', style: labelStyle),
          pw.Text('${labels['date']!}: $matchDate', style: labelStyle),
          pw.Text('${labels['field']!}: $fieldName', style: labelStyle),
          pw.SizedBox(height: 16),
          pw.Text(labels['players']!, style: tableHeaderStyle),
          pw.Table.fromTextArray(
            cellStyle: tableCellStyle,
            headerStyle: tableHeaderStyle,
            headers: isArabic
                ? ['الاسم', 'الدور', 'طريقة الدفع', 'المبلغ']
                : ['Name', 'Role', 'Payment Method', 'Amount Paid'],
            data: players
                .map(
                  (p) => [
                    p['name'],
                    p['role'],
                    p['paymentMethod'],
                    p['paidAmount'].toString(),
                  ],
                )
                .toList(),
            cellAlignment: isArabic
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 16),
          pw.Text(labels['expensesSection']!, style: tableHeaderStyle),
          pw.Table.fromTextArray(
            cellStyle: tableCellStyle,
            headerStyle: tableHeaderStyle,
            headers: isArabic
                ? ['الحكم', 'المنظم', 'الملعب', 'الماء', 'أخرى', 'الإجمالي']
                : ['Referee', 'Organizer', 'Pitch', 'Water', 'Other', 'Total'],
            data: [
              [
                expenses['referee'].toString(),
                expenses['organizer'].toString(),
                expenses['pitch'].toString(),
                expenses['water'].toString(),
                expenses['other'].toString(),
                (expenses['referee'] +
                        expenses['organizer'] +
                        expenses['pitch'] +
                        expenses['water'] +
                        expenses['other'])
                    .toString(),
              ],
            ],
            cellAlignment: isArabic
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 16),
          pw.Text(isArabic ? 'الملخص' : 'Summary', style: tableHeaderStyle),
          pw.Text(
            '${labels['collected']!}: ${players.fold<num>(0, (sum, p) => sum + (p['paidAmount'] ?? 0))}',
            style: labelStyle,
          ),
          pw.Text(
            '${labels['expenses']!}: ${(expenses['referee'] + expenses['organizer'] + expenses['pitch'] + expenses['water'] + expenses['other'])}',
            style: labelStyle,
          ),
          pw.Text(
            '${labels['net']!}: ${(players.fold<num>(0, (sum, p) => sum + (p['paidAmount'] ?? 0)) - (expenses['referee'] + expenses['organizer'] + expenses['pitch'] + expenses['water'] + expenses['other']))}',
            style: labelStyle,
          ),
        ],
      ),
    );
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/match_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Match Report PDF');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.table_chart),
            label: const Text('Export as Excel (.xlsx)'),
            onPressed: () => _exportExcel(context),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export as PDF (.pdf)'),
            onPressed: () => _exportPDF(context),
          ),
        ],
      ),
    );
  }
}
