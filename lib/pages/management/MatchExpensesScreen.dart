import 'package:flutter/material.dart';
import 'package:letsplay/widgets/App_Bottom_Nav.dart';
import 'package:letsplay/widgets/LogoButton.dart' show LogoButton;
import '../../services/language.dart';
import '../../services/firebase_service.dart';

class MatchExpensesScreen extends StatefulWidget {
  final LocaleController ctrl;
  const MatchExpensesScreen({super.key, required this.ctrl});

  @override
  State<MatchExpensesScreen> createState() => _MatchExpensesScreenState();
}

class _MatchExpensesScreenState extends State<MatchExpensesScreen> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _selectedMatchId;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _firebaseService.getMatches();
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading matches: $e');
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
                ar ? 'مصاريف المباريات' : 'Match Expenses',
                style: theme.textTheme.titleMedium,
              ),
              actions: const [LogoButton()],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _matches.isEmpty
                ? Center(
                    child: Text(
                      ar ? 'لا توجد مباريات' : 'No matches found',
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
                      final isExpanded = _selectedMatchId == matchId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMatchExpenseCard(
                          match,
                          isExpanded,
                          ar,
                          theme,
                        ),
                      );
                    },
                  ),
            bottomNavigationBar: const AppBottomNav(index: 3),
          ),
        );
      },
    );
  }

  Widget _buildMatchExpenseCard(
    Map<String, dynamic> match,
    bool isExpanded,
    bool ar,
    ThemeData theme,
  ) {
    final matchId = match['id'] as String?;
    final expenses = match['expenses'] as Map<String, dynamic>? ?? {};

    final refereeExpense = (expenses['referee'] as num?)?.toDouble() ?? 0.0;
    final organizerExpense = (expenses['organizer'] as num?)?.toDouble() ?? 0.0;
    final pitchExpense = (expenses['pitch'] as num?)?.toDouble() ?? 0.0;
    final waterExpense = (expenses['water'] as num?)?.toDouble() ?? 0.0;
    final otherExpenses = (expenses['other'] as num?)?.toDouble() ?? 0.0;

    final totalExpenses =
        refereeExpense +
        organizerExpense +
        pitchExpense +
        waterExpense +
        otherExpenses;

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
                      Icons.receipt_long,
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
                        '${totalExpenses.toStringAsFixed(0)} ${ar ? 'د.أ' : 'JOD'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: totalExpenses > 0
                              ? Colors.orange
                              : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            _buildExpensesForm(match, expenses, ar, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildExpensesForm(
    Map<String, dynamic> match,
    Map<String, dynamic> expenses,
    bool ar,
    ThemeData theme,
  ) {
    final matchId = match['id'] as String?;

    final refereeController = TextEditingController(
      text: (expenses['referee'] as num?)?.toString() ?? '0',
    );
    final organizerController = TextEditingController(
      text: (expenses['organizer'] as num?)?.toString() ?? '0',
    );
    final pitchController = TextEditingController(
      text: (expenses['pitch'] as num?)?.toString() ?? '0',
    );
    final waterController = TextEditingController(
      text: (expenses['water'] as num?)?.toString() ?? '0',
    );
    final otherController = TextEditingController(
      text: (expenses['other'] as num?)?.toString() ?? '0',
    );
    final commentsController = TextEditingController(
      text: expenses['comments'] as String? ?? '',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'مصاريف الموظفين' : 'STAFF EXPENSES',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildExpenseRow(
            Icons.sports,
            ar ? 'الحكم' : 'Referee',
            refereeController,
            ar,
            theme,
          ),
          const SizedBox(height: 12),
          _buildExpenseRow(
            Icons.person,
            ar ? 'المنظم' : 'Organizer',
            organizerController,
            ar,
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            ar ? 'مصاريف الملعب' : 'PITCH EXPENSES',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildExpenseRow(
            Icons.stadium,
            ar ? 'الملعب' : 'Pitch',
            pitchController,
            ar,
            theme,
          ),
          const SizedBox(height: 12),
          _buildExpenseRow(
            Icons.water_drop,
            ar ? 'الماء' : 'Water',
            waterController,
            ar,
            theme,
          ),
          const SizedBox(height: 12),
          _buildExpenseRow(
            Icons.list,
            ar ? 'مصاريف أخرى' : 'Other Expenses',
            otherController,
            ar,
            theme,
          ),
          const SizedBox(height: 24),
          Text(
            ar ? 'التعليقات' : 'COMMENTS',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: commentsController,
            style: theme.textTheme.bodyMedium,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: ar ? 'تعليقاتك هنا' : 'Your comments here',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white30,
              ),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveExpenses(
                matchId,
                refereeController.text,
                organizerController.text,
                pitchController.text,
                waterController.text,
                otherController.text,
                commentsController.text,
                ar,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                ar ? 'حفظ' : 'Save',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(
    IconData icon,
    String label,
    TextEditingController controller,
    bool ar,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                suffixText: ar ? 'د.أ' : 'JOD',
                suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white60, size: 20),
        ],
      ),
    );
  }

  Future<void> _saveExpenses(
    String? matchId,
    String referee,
    String organizer,
    String pitch,
    String water,
    String other,
    String comments,
    bool ar,
  ) async {
    if (matchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'خطأ: معرف المباراة غير موجود' : 'Error: Match ID not found',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final expenses = {
        'expenses': {
          'referee': double.tryParse(referee) ?? 0.0,
          'organizer': double.tryParse(organizer) ?? 0.0,
          'pitch': double.tryParse(pitch) ?? 0.0,
          'water': double.tryParse(water) ?? 0.0,
          'other': double.tryParse(other) ?? 0.0,
          'comments': comments,
        },
      };

      await _firebaseService.updateMatch(matchId, expenses);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم حفظ المصاريف بنجاح!' : 'Expenses saved successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh matches
        _loadMatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'خطأ: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
