import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? time;
  final String type; // 'event', 'meeting', 'birthday', 'appointment'
  final String userId;
  final bool hasReminder;
  final DateTime? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    required this.type,
    required this.userId,
    this.hasReminder = false,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] != null ? (map['time'] as Timestamp).toDate() : null,
      type: map['type'] ?? 'event',
      userId: map['userId'] ?? '',
      hasReminder: map['hasReminder'] ?? false,
      reminderTime: map['reminderTime'] != null
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time != null ? Timestamp.fromDate(time!) : null,
      'type': type,
      'userId': userId,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime != null
          ? Timestamp.fromDate(reminderTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? time,
    String? type,
    String? userId,
    bool? hasReminder,
    DateTime? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get formattedTime {
    if (time == null) return '';
    final hour = time!.hour;
    final minute = time!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String get typeIcon {
    switch (type) {
      case 'meeting':
        return '📅';
      case 'birthday':
        return '🎂';
      case 'appointment':
        return '🏥';
      default:
        return '📝';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'meeting':
        return const Color(0xFF2196F3);
      case 'birthday':
        return const Color(0xFFE91E63);
      case 'appointment':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9C27B0);
    }
  }
}
