import 'package:flutter/material.dart';
import '../models/match_player.dart';
import '../models/players_view_mode.dart';

class PlayerTile extends StatelessWidget {
  final MatchPlayer player;
  final PlayersViewMode mode;
  final bool isArabic;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  const PlayerTile({
    super.key,
    required this.player,
    required this.mode,
    required this.isArabic,
    this.onTap,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  player.avatarUrl != null && player.avatarUrl!.isNotEmpty
                  ? NetworkImage(
                      player.avatarUrl!.contains('?')
                          ? '${player.avatarUrl}&t=${DateTime.now().millisecondsSinceEpoch}'
                          : '${player.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                    )
                  : null,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
              child: player.avatarUrl == null || player.avatarUrl!.isEmpty
                  ? Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (mode == PlayersViewMode.roster && player.isStaff)
                    _buildRoleBadge(theme)
                  else if (mode == PlayersViewMode.payments)
                    Text(
                      '${isArabic ? 'المحفظة:' : 'Wallet:'} ${player.walletCredit} ${isArabic ? 'د.ل' : 'PFJ'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  if (player.phone != null && player.phone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          player.phone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Button
            if (onAction != null) _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme) {
    Color badgeColor;
    switch (player.role) {
      case 'coach':
        badgeColor = Colors.blue;
        break;
      case 'organizer':
        badgeColor = Colors.green;
        break;
      case 'admin':
        badgeColor = Colors.purple;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        player.roleLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    if (mode == PlayersViewMode.roster) {
      return Icon(
        Icons.chevron_right,
        color: theme.colorScheme.primary.withOpacity(0.6),
        size: 24,
      );
    } else {
      // Payments mode - show payment status or charge button
      if (player.isPaid) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.paymentMethod != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(
                    player.paymentMethod,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.paymentMethodLabel,
                  style: TextStyle(
                    color: _getPaymentMethodColor(player.paymentMethod),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        );
      }
      return ElevatedButton(
        onPressed: onAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isArabic ? 'تحصيل' : 'Charge',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Color _getPaymentMethodColor(String? method) {
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
        return Colors.grey;
    }
  }
}
