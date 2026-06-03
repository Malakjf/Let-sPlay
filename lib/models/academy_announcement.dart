import 'package:cloud_firestore/cloud_firestore.dart';

class AcademyAnnouncement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? buttonText;
  final String? buttonAction;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> targetRoles;
  final String createdBy;
  final DateTime createdAt;

  AcademyAnnouncement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.buttonText,
    this.buttonAction,
    required this.isActive,
    required this.startDate,
    required this.endDate,
    required this.targetRoles,
    required this.createdBy,
    required this.createdAt,
  });

  factory AcademyAnnouncement.fromMap(String id, Map<String, dynamic> map) {
    return AcademyAnnouncement(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      buttonText: map['buttonText'],
      buttonAction: map['buttonAction'],
      isActive: map['isActive'] ?? false,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      targetRoles: List<String>.from(map['targetRoles'] ?? ['All']),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'buttonText': buttonText,
      'buttonAction': buttonAction,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetRoles': targetRoles,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
