import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String linkedUserId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final String createdBy;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.linkedUserId,
    this.profileImageUrl,
    required this.createdAt,
    required this.createdBy,
  });

  // Convert a FamilyMember object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'linkedUserId': linkedUserId,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Create a FamilyMember object from a Map object
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      linkedUserId: map['linkedUserId'] as String,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      createdBy: map['createdBy'] as String,
    );
  }

  // Create a FamilyMember object from a Firestore DocumentSnapshot
  factory FamilyMember.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyMember(
      id: doc.id,
      name: data['name'] as String,
      relation: data['relation'] as String,
      linkedUserId: data['linkedUserId'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] as String),
      createdBy: data['createdBy'] as String,
    );
  }

  // Copy method for immutable updates
  FamilyMember copyWith({
    String? id,
    String? name,
    String? relation,
    String? linkedUserId,
    String? profileImageUrl,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      linkedUserId: linkedUserId ?? this.linkedUserId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FamilyMember &&
        other.id == id &&
        other.name == name &&
        other.relation == relation &&
        other.linkedUserId == linkedUserId &&
        other.profileImageUrl == profileImageUrl &&
        other.createdAt == createdAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        relation.hashCode ^
        linkedUserId.hashCode ^
        profileImageUrl.hashCode ^
        createdAt.hashCode ^
        createdBy.hashCode;
  }

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, relation: $relation, linkedUserId: $linkedUserId, profileImageUrl: $profileImageUrl, createdAt: $createdAt, createdBy: $createdBy)';
  }
}

class Relationship {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String relation;
  final DateTime createdAt;

  Relationship({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.relation,
    required this.createdAt,
  });

  // Convert a Relationship object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'relation': relation,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a Relationship object from a Map object
  factory Relationship.fromMap(Map<String, dynamic> map) {
    return Relationship(
      id: map['id'] as String,
      fromUserId: map['fromUserId'] as String,
      toUserId: map['toUserId'] as String,
      relation: map['relation'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Create a Relationship object from a Firestore DocumentSnapshot
  factory Relationship.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Relationship(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      relation: data['relation'] as String,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Relationship &&
        other.id == id &&
        other.fromUserId == fromUserId &&
        other.toUserId == toUserId &&
        other.relation == relation &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fromUserId.hashCode ^
        toUserId.hashCode ^
        relation.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Relationship(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, relation: $relation, createdAt: $createdAt)';
  }
}

// Predefined relationship types
class RelationshipType {
  static const String parent = 'parent';
  static const String child = 'child';
  static const String spouse = 'spouse';
  static const String sibling = 'sibling';
  static const String grandparent = 'grandparent';
  static const String grandchild = 'grandchild';
  static const String uncle = 'uncle';
  static const String aunt = 'aunt';
  static const String nephew = 'nephew';
  static const String niece = 'niece';
  static const String cousin = 'cousin';

  static const List<String> allRelations = [
    parent,
    child,
    spouse,
    sibling,
    grandparent,
    grandchild,
    uncle,
    aunt,
    nephew,
    niece,
    cousin,
  ];

  static String getDisplayName(String relation) {
    switch (relation) {
      case parent:
        return 'Parent';
      case child:
        return 'Child';
      case spouse:
        return 'Spouse';
      case sibling:
        return 'Sibling';
      case grandparent:
        return 'Grandparent';
      case grandchild:
        return 'Grandchild';
      case uncle:
        return 'Uncle';
      case aunt:
        return 'Aunt';
      case nephew:
        return 'Nephew';
      case niece:
        return 'Niece';
      case cousin:
        return 'Cousin';
      default:
        return relation;
    }
  }
}
