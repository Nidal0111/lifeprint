import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryModel {
  final String id;
  final String title;
  final MemoryType type;
  final String? cloudinaryUrl;
  final String? transcript;

  /// 🔥 Auto-detected emotion (single value)
  final String emotion;

  final DateTime? releaseDate;
  final DateTime createdAt;
  final String createdBy;
  final List<String> linkedUserIds;

  /// Transient flag (not stored in Firestore)
  final bool isShared;

  MemoryModel({
    required this.id,
    required this.title,
    required this.type,
    this.cloudinaryUrl,
    this.transcript,
    required this.emotion,
    this.releaseDate,
    required this.createdAt,
    required this.createdBy,
    this.linkedUserIds = const [],
    this.isShared = false,
  });

  // -------------------- FIRESTORE --------------------

  /// Convert model → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.name,
      'cloudinaryUrl': cloudinaryUrl,
      'transcript': transcript,
      'emotion': emotion, // ✅ single emotion
      'releaseDate': releaseDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'linkedUserIds': linkedUserIds,
    };
  }

  /// Create model from Firestore map
  factory MemoryModel.fromMap(Map<String, dynamic> map, String docId) {
    return MemoryModel(
      id: docId,
      title: map['title'] ?? '',
      type: MemoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MemoryType.text,
      ),
      cloudinaryUrl: map['cloudinaryUrl'],
      transcript: map['transcript'],

      // ✅ Safe fallback for old documents
      emotion: (map['emotion'] ?? 'unknown').toString(),

      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      linkedUserIds:
          List<String>.from(map['linkedUserIds'] ?? const []),
      isShared: false,
    );
  }

  /// Create model from Firestore DocumentSnapshot
  factory MemoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryModel.fromMap(data, doc.id);
  }

  // -------------------- UTIL --------------------

  MemoryModel copyWith({
    String? id,
    String? title,
    MemoryType? type,
    String? cloudinaryUrl,
    String? transcript,
    String? emotion,
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
      emotion: emotion ?? this.emotion,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      linkedUserIds: linkedUserIds ?? this.linkedUserIds,
      isShared: isShared ?? this.isShared,
    );
  }

  @override
  String toString() {
    return 'MemoryModel(id: $id, title: $title, type: $type, emotion: $emotion)';
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
        other.emotion == emotion &&
        other.releaseDate == releaseDate &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.linkedUserIds == linkedUserIds &&
        other.isShared == isShared;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      type.hashCode ^
      cloudinaryUrl.hashCode ^
      transcript.hashCode ^
      emotion.hashCode ^
      releaseDate.hashCode ^
      createdAt.hashCode ^
      createdBy.hashCode ^
      linkedUserIds.hashCode ^
      isShared.hashCode;
}

// -------------------- ENUM --------------------

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
