import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final HabitFrequency frequency;
  
  @HiveField(3)
  final int colorValue;
  
  @HiveField(4)
  final int dailyGoal;
  
  @HiveField(5)
  final bool enableReminders;
  
  @HiveField(6)
  final int? reminderTimeHour;
  
  @HiveField(7)
  final int? reminderTimeMinute;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final List<HabitEntry> entries;

  @HiveField(10)
  final int? reminderWeekday;

  // Private/internal constructor for Hive
  Habit._internal({
    required this.id,
    required this.name,
    required this.frequency,
    required this.colorValue,
    this.dailyGoal = 1,
    this.enableReminders = false,
    this.reminderTimeHour,
    this.reminderTimeMinute,
    this.reminderWeekday,
    required this.createdAt,
    List<HabitEntry>? entries,
  }) : entries = entries ?? [];

  // Public constructor for our app code
  Habit({
    required this.id,
    required this.name,
    required this.frequency,
    required Color color,
    this.dailyGoal = 1,
    this.enableReminders = false,
    this.reminderTimeHour,
    this.reminderTimeMinute,
    this.reminderWeekday,
    required this.createdAt,
    List<HabitEntry>? entries,
  })  : colorValue = color.value,
        entries = entries ?? [];

  Color get color => Color(colorValue);
  
  TimeOfDay? get reminderTime {
    if (reminderTimeHour != null && reminderTimeMinute != null) {
      return TimeOfDay(hour: reminderTimeHour!, minute: reminderTimeMinute!);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency.index,
      'colorValue': colorValue,
      'dailyGoal': dailyGoal,
      'enableReminders': enableReminders,
      'reminderTimeHour': reminderTimeHour,
      'reminderTimeMinute': reminderTimeMinute,
      'reminderWeekday': reminderWeekday,
      'createdAt': createdAt.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      frequency: HabitFrequency.values[json['frequency']],
      color: Color(json['colorValue']),
      dailyGoal: json['dailyGoal'],
      enableReminders: json['enableReminders'],
      reminderTimeHour: json['reminderTimeHour'],
      reminderTimeMinute: json['reminderTimeMinute'],
      reminderWeekday: json['reminderWeekday'],
      createdAt: DateTime.parse(json['createdAt']),
      entries: (json['entries'] as List)
          .map((e) => HabitEntry.fromJson(e))
          .toList(),
    );
  }

  Habit copyWith({
    String? id,
    String? name,
    HabitFrequency? frequency,
    Color? color,
    int? dailyGoal,
    bool? enableReminders,
    int? reminderTimeHour,
    int? reminderTimeMinute,
    int? reminderWeekday,
    DateTime? createdAt,
    List<HabitEntry>? entries,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      color: color ?? this.color,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderTimeHour: reminderTimeHour ?? this.reminderTimeHour,
      reminderTimeMinute: reminderTimeMinute ?? this.reminderTimeMinute,
      reminderWeekday: reminderWeekday ?? this.reminderWeekday,
      createdAt: createdAt ?? this.createdAt,
      entries: entries ?? this.entries,
    );
  }
}

@HiveType(typeId: 1)
class HabitEntry {
  @HiveField(0)
  final String habitId;
  
  @HiveField(1)
  final DateTime date;
  
  @HiveField(2)
  final int progress;

  HabitEntry({
    required this.habitId,
    required this.date,
    required this.progress,
  });

  Map<String, dynamic> toJson() {
    return {
      'habitId': habitId,
      'date': date.toIso8601String(),
      'progress': progress,
    };
  }

  factory HabitEntry.fromJson(Map<String, dynamic> json) {
    return HabitEntry(
      habitId: json['habitId'],
      date: DateTime.parse(json['date']),
      progress: json['progress'],
    );
  }
}

@HiveType(typeId: 2)
enum HabitFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
}