import 'package:flutter/material.dart';
import '../models/match_player.dart';

class PlayerDetailsDialog extends StatelessWidget {
  final MatchPlayer player;
  final bool isArabic;
  final VoidCallback? onAddFunds;

  const PlayerDetailsDialog({
    super.key,
    required this.player,
    required this.isArabic,
    this.onAddFunds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.appBarTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 50,
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
                    ? Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                        size: 50,
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                player.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.sports_soccer,
                    player.goals.toString(),
                    isArabic ? 'أهداف' : 'Goals',
                    theme,
                  ),
                  _buildStatItem(
                    Icons.sports,
                    player.assists.toString(),
                    isArabic ? 'تمريرات' : 'Assists',
                    theme,
                  ),
                  _buildStatItem(
                    Icons.event,
                    player.matches.toString(),
                    isArabic ? 'مباريات' : 'Matches',
                    theme,
                  ),
                  _buildStatItem(
                    Icons.emoji_events,
                    player.motm.toString(),
                    'MOTM',
                    theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCardBadge(player.redCards, Colors.red, theme),
                  const SizedBox(width: 12),
                  _buildCardBadge(player.yellowCards, Colors.yellow, theme),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Wallet
              Text(
                isArabic ? 'رصيد المحفظة' : 'Wallet Credit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${player.walletCredit} ${isArabic ? 'د.ل' : 'PFJ'}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Add Funds (for staff)
              if (player.isStaff && onAddFunds != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddFunds,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(isArabic ? 'إضافة رصيد' : 'Add Funds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Contact
              Text(
                isArabic ? 'التفاصيل' : 'DETAILS',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (player.email != null && player.email!.isNotEmpty)
                _buildDetailRow(Icons.email, player.email!, theme),
              if (player.phone != null && player.phone!.isNotEmpty)
                _buildDetailRow(Icons.phone, player.phone!, theme),

              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBadge(int count, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
