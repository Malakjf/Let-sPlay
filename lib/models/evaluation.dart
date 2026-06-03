class Evaluation {
  final String id;
  final String playerId;
  final String coachId;
  final String createdBy;
  final String? reviewedBy;
  final String? sentToPlayerBy;
  final Map<String, dynamic> details;
  final String
  status; // Draft, Pending Admin Review, Sent to Player, Approved, Rejected
  final bool submittedByCoach;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Evaluation({
    required this.id,
    required this.playerId,
    required this.coachId,
    required this.createdBy,
    this.reviewedBy,
    this.sentToPlayerBy,
    required this.details,
    required this.status,
    this.submittedByCoach = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'coachId': coachId,
    'createdBy': createdBy,
    'reviewedBy': reviewedBy,
    'sentToPlayerBy': sentToPlayerBy,
    'details': details,
    'status': status,
    'submittedByCoach': submittedByCoach,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static Evaluation fromMap(String id, Map<String, dynamic> m) {
    DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return Evaluation(
      id: id,
      playerId: m['playerId'] ?? '',
      coachId: m['coachId'] ?? '',
      createdBy: m['createdBy'] ?? '',
      reviewedBy: m['reviewedBy'],
      sentToPlayerBy: m['sentToPlayerBy'],
      details: Map<String, dynamic>.from(m['details'] ?? {}),
      status: m['status'] ?? 'Draft',
      submittedByCoach: m['submittedByCoach'] ?? false,
      createdAt: parseTs(m['createdAt']),
      updatedAt: parseTs(m['updatedAt']),
    );
  }
}
