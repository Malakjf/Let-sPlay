class MatchPlayer {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool hasPaid;
  final num walletCredit;
  final String role;
  final String? phone;
  final String? paymentMethod;
  final String? email;
  final int goals;
  final int assists;
  final int matches;
  final int motm;
  final int redCards;
  final int yellowCards;

  MatchPlayer({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.hasPaid = false,
    this.walletCredit = 0,
    required this.role,
    this.phone,
    this.paymentMethod,
    this.email,
    this.goals = 0,
    this.assists = 0,
    this.matches = 0,
    this.motm = 0,
    this.redCards = 0,
    this.yellowCards = 0,
  });

  factory MatchPlayer.fromMap(
    Map<String, dynamic> data, {
    bool hasPaid = false,
    String? paymentMethod,
  }) {
    return MatchPlayer(
      id: data['uid'] ?? data['id'] ?? '',
      name: data['name'] ?? data['username'] ?? 'Unknown',
      avatarUrl: data['avatarUrl'] ?? data['photoUrl'],
      hasPaid: hasPaid,
      walletCredit: data['walletCredit'] ?? 0,
      role: data['role'] ?? 'player',
      phone: data['phone'] ?? data['phoneNumber'],
      paymentMethod: paymentMethod,
      email: data['email'],
      goals: data['goals'] ?? 0,
      assists: data['assists'] ?? 0,
      matches: data['matches'] ?? 0,
      motm: data['motm'] ?? 0,
      redCards: data['redCards'] ?? 0,
      yellowCards: data['yellowCards'] ?? 0,
    );
  }

  MatchPlayer copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? hasPaid,
    num? walletCredit,
    String? role,
    String? phone,
    String? paymentMethod,
    String? email,
    int? goals,
    int? assists,
    int? matches,
    int? motm,
    int? redCards,
    int? yellowCards,
  }) {
    return MatchPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasPaid: hasPaid ?? this.hasPaid,
      walletCredit: walletCredit ?? this.walletCredit,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      email: email ?? this.email,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      matches: matches ?? this.matches,
      motm: motm ?? this.motm,
      redCards: redCards ?? this.redCards,
      yellowCards: yellowCards ?? this.yellowCards,
    );
  }

  bool get isStaff =>
      role.toLowerCase() == 'coach' ||
      role.toLowerCase() == 'organizer' ||
      role.toLowerCase() == 'admin';

  // Getters for PlayerTile compatibility
  bool get isPaid => hasPaid;

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'organizer':
        return 'Organizer';
      case 'coach':
        return 'Coach';
      case 'academy_player':
        return 'Academy';
      default:
        return 'Player';
    }
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Cash';
      case 'cash_to_wallet':
        return 'Cash -> Wallet';
      case 'online':
        return 'Online';
      default:
        return paymentMethod ?? '';
    }
  }
}
