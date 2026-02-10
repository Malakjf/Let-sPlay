// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/language.dart';
import '../services/firebase_service.dart';
import '../widgets/GlassContainer.dart';
import '../widgets/logobutton.dart';

import 'organization/models/match_player.dart';
import 'organization/models/players_view_mode.dart';
import 'organization/widgets/players_header.dart';
import 'organization/widgets/players_tabs.dart';
import 'organization/widgets/payment_bottom_sheet.dart';
import 'organization/widgets/player_details_dialog.dart';
import 'organization/widgets/expenses_screen.dart';

/// Helper to safely parse dates from Firestore (Timestamp or String)
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class OrganizationPage extends StatefulWidget {
  final LocaleController ctrl;
  const OrganizationPage({super.key, required this.ctrl});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final FirebaseService _firebaseService = FirebaseService.instance;

  String? _selectedMatchId;
  PlayersViewMode _viewMode = PlayersViewMode.roster;

  /// Cache مساعد فقط (ليس مصدر الحقيقة)
  final Map<String, List<MatchPlayer>> _matchPlayersCache = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);

        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(ar ? 'المباريات' : 'Matches'),
              actions: const [LogoButton()],
            ),
            body: SafeArea(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    debugPrint(
                      '❌ Organization Stream Error: ${snapshot.error}',
                    );
                    return _emptyState(ar);
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState(ar);
                  }

                  final matches = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final doc = matches[index];
                      final match = doc.data();
                      match['id'] = doc.id;

                      return _buildMatchCard(match, ar, theme);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(bool ar) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_soccer, size: 60, color: Colors.white30),
          const SizedBox(height: 12),
          Text(
            ar ? 'لا توجد مباريات' : 'No matches yet',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, bool ar, ThemeData theme) {
    final matchId = match['id'] as String;
    final isExpanded = _selectedMatchId == matchId;

    return GlassContainer(
      key: ValueKey(matchId),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              setState(() {
                _selectedMatchId = isExpanded ? null : matchId;
                _viewMode = PlayersViewMode.roster;
              });

              if (!isExpanded && !_matchPlayersCache.containsKey(matchId)) {
                await _loadMatchPlayers(matchId, match);
              }
            },
            child: ListTile(
              title: Text(match['name'] ?? 'Match'),
              subtitle: Text(() {
                final date = _parseDate(match['date']);
                final dateString = date != null
                    ? '${date.year}-${date.month}-${date.day}'
                    : 'No Date';
                return '$dateString • ${match['fieldName'] ?? 'No Field'}';
              }()),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(),

            _buildMatchActionButtons(match, ar, theme),

            _buildMatchPlayersView(match, ar, theme),
          ],
        ],
      ),
    );
  }

  /// 🔥 اللاعبين — دائمًا متزامنين مع Firestore
  Widget _buildMatchPlayersView(
    Map<String, dynamic> match,
    bool ar,
    ThemeData theme,
  ) {
    final matchId = match['id'];
    final players = _matchPlayersCache[matchId] ?? <MatchPlayer>[];
    final attendance = match['attendance'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        PlayersHeader(
          currentPlayers: players.length,
          maxPlayers: match['maxPlayers'] ?? 10,
          isArabic: ar,
        ),
        PlayersTabs(
          selectedMode: _viewMode,
          isArabic: ar,
          onModeChanged: (m) {
            setState(() => _viewMode = m);
          },
        ),

        if (players.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              ar ? 'لا يوجد لاعبين' : 'No players yet',
              style: const TextStyle(color: Colors.white60),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final player = players[i];
              final playerAttendance =
                  attendance[player.id] as Map<String, dynamic>?;
              final isAttended = playerAttendance?['attended'] == true;

              return _buildPlayerListItem(player, match, isAttended, ar, theme);
            },
          ),
      ],
    );
  }

  Widget _buildPlayerListItem(
    MatchPlayer player,
    Map<String, dynamic> match,
    bool isAttended,
    bool ar,
    ThemeData theme,
  ) {
    final isRoster = _viewMode == PlayersViewMode.roster;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isRoster ? () => _showPlayerDetails(player, ar, theme) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAttendanceChip(match['id'], player.id, isAttended, theme),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage:
                    player.avatarUrl != null &&
                        player.avatarUrl!.isNotEmpty &&
                        (player.avatarUrl!.startsWith('http') ||
                            player.avatarUrl!.startsWith('https'))
                    ? NetworkImage(player.avatarUrl!)
                    : null,
                child:
                    player.avatarUrl == null ||
                        player.avatarUrl!.isEmpty ||
                        !(player.avatarUrl!.startsWith('http') ||
                            player.avatarUrl!.startsWith('https'))
                    ? Text(
                        player.name.isNotEmpty
                            ? player.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildRoleBadge(player.role, theme),
                  ],
                ),
              ),
              _buildActionButton(player, match, ar, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceChip(
    String matchId,
    String playerId,
    bool isAttended,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _toggleAttendance(matchId, playerId, !isAttended),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isAttended
              ? Colors.green.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isAttended ? Colors.green : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          isAttended ? Icons.check : Icons.circle_outlined,
          size: 18,
          color: isAttended ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, ThemeData theme) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.purple;
        break;
      case 'organizer':
        color = Colors.green;
        break;
      case 'academy player':
        color = Colors.orange;
        break;
      case 'player':
      default:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButton(
    MatchPlayer player,
    Map<String, dynamic> match,
    bool ar,
    ThemeData theme,
  ) {
    final isPayments = _viewMode == PlayersViewMode.payments;

    return InkWell(
      onTap: isPayments
          ? () => _handleChargeButton(player, match, ar, theme)
          : () => _showAddFundsDialog(player, ar, theme),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Icon(
          isPayments
              ? (player.hasPaid ? Icons.check_circle : Icons.attach_money)
              : Icons.add,
          size: 20,
          color: isPayments ? Colors.green : theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// ===============================
  /// 👇👇👇 كل الفنكشنز القديمة موجودة
  /// ===============================

  Future<void> _loadMatchPlayers(
    String matchId,
    Map<String, dynamic> match,
  ) async {
    final List<MatchPlayer> players = [];
    final ids = <String>{};
    final payments = match['payments'] as Map<String, dynamic>? ?? {};

    for (final id in (match['players'] ?? [])) {
      if (ids.add(id.toString())) {
        final data = await _firebaseService.getUserData(id);

        String? method;
        final pData = payments[id.toString()];
        if (pData is Map && pData.containsKey('method')) {
          method = pData['method'];
        }

        players.add(
          MatchPlayer.fromMap(
            data,
            hasPaid: payments.containsKey(id.toString()),
            paymentMethod: method,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _matchPlayersCache[matchId] = players;
      });
    }
  }

  Future<void> _toggleAttendance(
    String matchId,
    String playerId,
    bool? attended,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId);
    await docRef.set({
      'attendance': {
        playerId: {
          'attended': attended ?? false,
          'checkedAt': DateTime.now().toIso8601String(),
        },
      },
    }, SetOptions(merge: true));
  }

  void _handleChargeButton(
    MatchPlayer player,
    Map<String, dynamic> match,
    bool ar,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentBottomSheet(
        player: player,
        matchFee: match['price'] ?? 6,
        matchName: match['name'] ?? 'Match',
        isArabic: ar,
        onPaymentMethodSelected:
            (
              method, {
              num? amount,
              num? cashPaid,
              num? walletAdded,
              num? matchUsed,
            }) {
              _processPayment(
                match['id'],
                player,
                amount ?? (match['price'] ?? 6),
                method,
                ar,
                cashPaid: cashPaid,
                walletAdded: walletAdded,
                matchUsed: matchUsed,
              );
            },
      ),
    );
  }

  void _showPlayerDetails(MatchPlayer player, bool ar, ThemeData theme) {
    showDialog(
      context: context,
      builder: (_) => PlayerDetailsDialog(
        player: player,
        isArabic: ar,
        onAddFunds: () {
          Navigator.pop(context);
          _showAddFundsDialog(player, ar, theme);
        },
      ),
    );
  }

  Widget _buildMatchActionButtons(
    Map<String, dynamic> match,
    bool ar,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.receipt_long),
          label: Text(ar ? 'المصاريف' : 'Expenses'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          onPressed: () => _openExpenses(match, ar),
        ),
      ),
    );
  }

  void _openExpenses(Map<String, dynamic> match, bool ar) {
    final matchId = match['id'];
    final players = _matchPlayersCache[matchId] ?? <MatchPlayer>[];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrganizationExpensesScreen(
          ctrl: widget.ctrl,
          match: match,
          players: players,
        ),
      ),
    );
  }

  Future<void> _processPayment(
    String matchId,
    MatchPlayer player,
    num amount,
    String method,
    bool ar, {
    num? cashPaid,
    num? walletAdded,
    num? matchUsed,
  }) async {
    try {
      switch (method) {
        case 'wallet':
          await _processWalletPayment(matchId, player, amount);
          break;
        case 'cash':
          await _processCashPayment(matchId, player, amount);
          break;
        case 'cash_to_wallet':
          if (cashPaid == null || walletAdded == null || matchUsed == null) {
            throw Exception('Invalid cash_to_wallet data');
          }
          await _processCashToWalletPayment(
            matchId,
            player,
            cashPaid,
            walletAdded,
            matchUsed,
          );
          break;
        case 'online':
          await _processOnlinePayment(matchId, player, amount);
          break;
      }

      await _refreshPlayerInAllCaches(player.id);
      await _refreshMatchPaymentStatus(matchId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم تسجيل الدفع بنجاح' : 'Payment recorded successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'فشلت عملية الدفع: $e' : 'Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processWalletPayment(
    String matchId,
    MatchPlayer player,
    num amount,
  ) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(player.id);
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User not found');
      }

      final currentBalance = userSnapshot.data()?['walletCredit'] ?? 0;
      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      transaction.update(userRef, {
        'walletCredit': FieldValue.increment(-amount),
      });

      _recordMatchPayment(transaction, matchId, player.id, amount, 'wallet');
    });
  }

  Future<void> _processCashPayment(
    String matchId,
    MatchPlayer player,
    num amount,
  ) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      _recordMatchPayment(transaction, matchId, player.id, amount, 'cash');
    });
  }

  Future<void> _processCashToWalletPayment(
    String matchId,
    MatchPlayer player,
    num cashPaid,
    num walletAdded,
    num matchUsed,
  ) async {
    // Enforce strict accounting: Net Change = Cash In - Match Out
    final netWalletChange = cashPaid - matchUsed;

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(player.id);

      // 1. Update Wallet: Apply net change (can be positive or negative)
      transaction.update(userRef, {
        'walletCredit': FieldValue.increment(netWalletChange),
      });

      // 2. Record Payment
      // We record the full details for accounting
      final matchRef = FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId);

      // 2a. Record Match Payment (Income)
      transaction.update(matchRef, {
        'payments.${player.id}': {
          'method': 'cash_to_wallet',
          'amount':
              matchUsed, // Only the amount used for match counts as payment here
          'timestamp': DateTime.now().toIso8601String(),
        },
      });

      // 2b. Record Wallet Recharge Details (Separate accounting)
      transaction.update(matchRef, {
        'walletRecharges.${player.id}': {
          'cashPaid': cashPaid, // Total cash given
          'walletAdded': netWalletChange, // Net amount added/deducted
          'usedForMatch': matchUsed, // Amount used for match
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    });
  }

  Future<void> _processOnlinePayment(
    String matchId,
    MatchPlayer player,
    num amount,
  ) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      _recordMatchPayment(transaction, matchId, player.id, amount, 'online');
    });
  }

  void _recordMatchPayment(
    Transaction transaction,
    String matchId,
    String playerId,
    num amount,
    String method,
  ) {
    final matchRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId);
    transaction.update(matchRef, {
      'payments.$playerId': {
        'amount': amount,
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
  }

  Future<void> _refreshPlayerInAllCaches(String playerId) async {
    try {
      final userData = await _firebaseService.getUserData(playerId);

      if (mounted) {
        setState(() {
          for (final matchId in _matchPlayersCache.keys) {
            final players = _matchPlayersCache[matchId]!;
            final index = players.indexWhere((p) => p.id == playerId);
            if (index != -1) {
              final oldPlayer = players[index];
              players[index] = MatchPlayer.fromMap(
                userData,
                hasPaid: oldPlayer.hasPaid,
                paymentMethod: oldPlayer.paymentMethod,
              );
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error refreshing player cache: $e');
    }
  }

  Future<void> _refreshMatchPaymentStatus(String matchId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      if (doc.exists) {
        final payments = doc.data()?['payments'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            final players = _matchPlayersCache[matchId];
            if (players != null) {
              for (var i = 0; i < players.length; i++) {
                final p = players[i];
                final isPaid = payments.containsKey(p.id);

                String? method;
                final pData = payments[p.id];
                if (pData is Map && pData.containsKey('method')) {
                  method = pData['method'];
                }

                if (p.hasPaid != isPaid || p.paymentMethod != method) {
                  players[i] = p.copyWith(
                    hasPaid: isPaid,
                    paymentMethod: method,
                  );
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing match payments: $e');
    }
  }

  void _showAddFundsDialog(MatchPlayer player, bool ar, ThemeData theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          ar ? 'إضافة رصيد' : 'Add Funds',
          style: theme.textTheme.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ar
                  ? 'إضافة رصيد لمحفظة ${player.name}'
                  : 'Add funds to ${player.name}\'s wallet',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: ar ? 'المبلغ' : 'Amount',
                suffixText: ar ? 'د.أ' : 'JOD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(player.id)
                      .update({'walletCredit': FieldValue.increment(amount)});

                  await _refreshPlayerInAllCaches(player.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ar
                            ? 'تم إضافة الرصيد بنجاح'
                            : 'Funds added successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ar ? 'حدث خطأ' : 'Error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(ar ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
