import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String title;
  final MemoryType type;
  final String? cloudinaryUrl;
  final String? transcript;
  final List<String> emotions;
  final DateTime? releaseDate;
  final DateTime createdAt;
  final String createdBy;
  final List<String> linkedUserIds;
  // Transient flag: true when this memory is shared with the current user.
  // This is not persisted to Firestore.
  final bool isShared;

  MemoryModel({
    required this.id,
    required this.title,
    required this.type,
    this.cloudinaryUrl,
    this.transcript,
    this.emotions = const [],
    this.releaseDate,
    required this.createdAt,
    required this.createdBy,
    this.linkedUserIds = const [],
    this.isShared = false,
  });

  // Convert MemoryModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'cloudinaryUrl': cloudinaryUrl,
      'transcript': transcript,
      'emotions': emotions,
      'releaseDate': releaseDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'linkedUserIds': linkedUserIds,
      // Note: isShared is transient and intentionally not persisted
    };
  }

  // Create MemoryModel from Firestore document
  factory MemoryModel.fromMap(Map<String, dynamic> map) {
    return MemoryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      type: MemoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MemoryType.text,
      ),
      cloudinaryUrl: map['cloudinaryUrl'],
      transcript: map['transcript'],
      emotions: List<String>.from(map['emotions'] ?? []),
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      linkedUserIds: List<String>.from(map['linkedUserIds'] ?? []),
      // isShared is transient; default to false when created from Firestore
      isShared: false,
    );
  }

  // Create MemoryModel from Firestore DocumentSnapshot
  factory MemoryModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MemoryModel.fromMap(data);
  }

  // Create a copy of MemoryModel with updated fields
  MemoryModel copyWith({
    String? id,
    String? title,
    MemoryType? type,
    String? cloudinaryUrl,
    String? transcript,
    List<String>? emotions,
    DateTime? releaseDate,
    DateTime? createdAt,
    String? createdBy,
    List<String>? linkedUserIds,
    bool? isShared,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      transcript: transcript ?? this.transcript,
      emotions: emotions ?? this.emotions,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      linkedUserIds: linkedUserIds ?? this.linkedUserIds,
      isShared: isShared ?? this.isShared,
    );
  }

  @override
  String toString() {
    return 'MemoryModel(id: $id, title: $title, type: $type, cloudinaryUrl: $cloudinaryUrl, transcript: $transcript, emotions: $emotions, releaseDate: $releaseDate, createdAt: $createdAt, createdBy: $createdBy, linkedUserIds: $linkedUserIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryModel &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.cloudinaryUrl == cloudinaryUrl &&
        other.transcript == transcript &&
        other.emotions == emotions &&
        other.releaseDate == releaseDate &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.linkedUserIds == linkedUserIds &&
        other.isShared == isShared;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        type.hashCode ^
        cloudinaryUrl.hashCode ^
        transcript.hashCode ^
        emotions.hashCode ^
        releaseDate.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode ^
        linkedUserIds.hashCode ^
        isShared.hashCode;
  }
}

enum MemoryType {
  photo,
  video,
  audio,
  text;

  String get displayName {
    switch (this) {
      case MemoryType.photo:
        return 'Photo';
      case MemoryType.video:
        return 'Video';
      case MemoryType.audio:
        return 'Audio';
      case MemoryType.text:
        return 'Text';
    }
  }

  String get icon {
    switch (this) {
      case MemoryType.photo:
        return '📷';
      case MemoryType.video:
        return '🎥';
      case MemoryType.audio:
        return '🎵';
      case MemoryType.text:
        return '📝';
    }
  }
}
