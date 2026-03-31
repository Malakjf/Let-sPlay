enum RoleRequestStatus { pending, approved, rejected }

class RoleRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String requestedRole;
  final DateTime requestDate;
  final RoleRequestStatus status;

  const RoleRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.requestedRole,
    required this.requestDate,
    this.status = RoleRequestStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'requestedRole': requestedRole,
      'requestDate': requestDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory RoleRequest.fromMap(Map<String, dynamic> map) {
    return RoleRequest(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      userEmail: map['userEmail'],
      requestedRole: map['requestedRole'],
      requestDate: DateTime.parse(map['requestDate']),
      status: RoleRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoleRequestStatus.pending,
      ),
    );
  }
}
