import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_heatmap/models/habit.dart';

class DatabaseService extends ChangeNotifier {
  static const String habitsBoxName = 'habits';
  
  late Box<Habit> _habitsBox;
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Future<void> init() async {
    _habitsBox = await Hive.openBox<Habit>(habitsBoxName);
  }
  
  Box<Habit> get habitsBox => _habitsBox;
  
  // Get all habits
  List<Habit> getAllHabits() {
    return _habitsBox.values.toList();
  }
  
  // Get habit by id
  Habit? getHabit(String id) {
    return _habitsBox.get(id);
  }
  
  // Add new habit
  Future<void> addHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
    notifyListeners();
  }
  
  // Update habit
  Future<void> updateHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
    notifyListeners();
  }
  
  // Delete habit
  Future<void> deleteHabit(String id) async {
    await _habitsBox.delete(id);
    notifyListeners();
  }
  
  // Update habit entry
  Future<void> updateHabitEntry(String habitId, HabitEntry newEntry) async {
    final habit = _habitsBox.get(habitId);
    if (habit != null) {
      final entries = List<HabitEntry>.from(habit.entries);
      final existingIndex = entries.indexWhere(
        (e) => e.date.year == newEntry.date.year &&
               e.date.month == newEntry.date.month &&
               e.date.day == newEntry.date.day,
      );
      
      if (existingIndex != -1) {
        entries[existingIndex] = newEntry;
      } else {
        entries.add(newEntry);
      }
      
      final updatedHabit = habit.copyWith(entries: entries);
      await _habitsBox.put(habitId, updatedHabit);
      notifyListeners();
    }
  }
  
  // Get habit entries for a date range
  List<HabitEntry> getEntriesForDateRange(String habitId, DateTime start, DateTime end) {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return [];
    
    return habit.entries.where(
      (e) => e.date.isAfter(start) && e.date.isBefore(end)
    ).toList();
  }
  
  // Get today's entries for a habit
  HabitEntry? getTodayEntry(String habitId) {
    final habit = _habitsBox.get(habitId);
    if (habit == null) return null;
    
    final today = DateTime.now();
    return habit.entries.firstWhere(
      (e) => e.date.year == today.year &&
             e.date.month == today.month &&
             e.date.day == today.day,
      orElse: () => HabitEntry(habitId: habitId, date: today, progress: 0),
    );
  }
  
  // Clear all data (for testing/logout)
  Future<void> clearAllData() async {
    await _habitsBox.clear();
    notifyListeners();
  }
}