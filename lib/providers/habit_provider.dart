import 'package:flutter/material.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/services/database_service.dart';
import 'package:habit_heatmap/core/utils/date_utils.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Habit> _habits = [];
  bool _isLoading = false;

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;

  HabitProvider() {
    _init();
  }

  Future<void> _init() async {
    await _db.init();
    await loadHabits();
    _db.addListener(_onDatabaseChanged);
  }

  void _onDatabaseChanged() {
    loadHabits();
  }

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();
    
    _habits = _db.getAllHabits();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    await _db.addHabit(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
  }

  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date, bool isCompleted) async {
    final habit = _habits.firstWhere((h) => h.id == habitId);
    
    if (habit.frequency == HabitFrequency.daily) {
      final entry = HabitEntry(
        habitId: habitId,
        date: date,
        progress: isCompleted ? habit.dailyGoal : 0,
      );
      await _db.updateHabitEntry(habitId, entry);
    } else {
      // Weekly logic: Toggling completion for the week
      final startOfWeek = HabitDateUtils.getStartOfWeek(date);
      // We'll log the progress on 'date' (today) to satisfy the weekly goal
      // First, see current week progress
      int currentWeekProgress = 0;
      for (var e in habit.entries) {
        if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), startOfWeek)) {
          currentWeekProgress += e.progress;
        }
      }
      
      if (isCompleted) {
        // If not already completed, add enough to today to reach the goal
        if (currentWeekProgress < habit.dailyGoal) {
          final needed = habit.dailyGoal - currentWeekProgress;
          // Get today's existing progress
          final todayEntry = habit.entries.firstWhere(
            (e) => HabitDateUtils.isSameDay(e.date, date),
            orElse: () => HabitEntry(habitId: habitId, date: date, progress: 0),
          );
          final entry = HabitEntry(
            habitId: habitId,
            date: date,
            progress: todayEntry.progress + needed,
          );
          await _db.updateHabitEntry(habitId, entry);
        }
      } else {
        // Un-completing a weekly habit: This is tricky. 
        // For now, we'll just clear all progress for this week to be safe, 
        // or just clear today's progress. Let's clear all for the week.
        for (var e in habit.entries) {
          if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), startOfWeek)) {
            await _db.updateHabitEntry(habitId, HabitEntry(habitId: habitId, date: e.date, progress: 0));
          }
        }
      }
    }
  }

  Future<void> logProgress(String habitId, int progress) async {
    final today = DateTime.now();
    final entry = HabitEntry(
      habitId: habitId,
      date: today,
      progress: progress,
    );
    await _db.updateHabitEntry(habitId, entry);
  }

  Map<String, dynamic> getWeeklyStats() {
    int totalCompleted = 0;
    int totalPossible = 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    for (var habit in _habits) {
      if (habit.frequency == HabitFrequency.daily) {
        final difference = todayStart.difference(
          DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day)
        ).inDays + 1;
        
        final daysToTrack = difference > 7 ? 7 : difference;
        final trackingStartDate = todayStart.subtract(Duration(days: daysToTrack - 1));
        
        final completedInWindow = habit.entries.where(
          (e) => (e.date.isAfter(trackingStartDate) || HabitDateUtils.isSameDay(e.date, trackingStartDate))
              && e.progress >= habit.dailyGoal
        ).length;
        
        totalPossible += daysToTrack;
        totalCompleted += completedInWindow;
      } else {
        // Weekly habit global stats
        final startOfWeek = HabitDateUtils.getStartOfWeek(todayStart);
        // Look at last 4 weeks
        for (int i = 0; i < 4; i++) {
          final weekStart = startOfWeek.subtract(Duration(days: i * 7));
          final creationWeek = HabitDateUtils.getStartOfWeek(habit.createdAt);
          
          if (weekStart.isAfter(creationWeek) || HabitDateUtils.isSameDay(weekStart, creationWeek)) {
            totalPossible++;
            int weekProgress = 0;
            for (var e in habit.entries) {
              if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), weekStart)) {
                weekProgress += e.progress;
              }
            }
            if (weekProgress >= habit.dailyGoal) {
              totalCompleted++;
            }
          }
        }
      }
    }
    
    final completionRate = totalPossible > 0 ? totalCompleted / totalPossible : 0.0;
    
    return {
      'completionRate': completionRate,
      'currentStreak': _calculateMaxStreak(),
      'dailyHabitsDone': _habits.where((h) => _isCurrentPeriodCompleted(h)).length,
      'dailyHabitsTotal': _habits.length,
      'consistency': completionRate,
    };
  }

  int _calculateMaxStreak() {
    int maxStreak = 0;
    for (var habit in _habits) {
      final streak = HabitDateUtils.calculateStreak(habit.entries, frequency: habit.frequency, goal: habit.dailyGoal);
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }

  bool _isCurrentPeriodCompleted(Habit habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (habit.frequency == HabitFrequency.daily) {
      return habit.entries.any(
        (entry) => HabitDateUtils.isSameDay(entry.date, today) && entry.progress >= habit.dailyGoal,
      );
    } else {
      final startOfWeek = HabitDateUtils.getStartOfWeek(today);
      int weekProgress = 0;
      for (var e in habit.entries) {
        if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), startOfWeek)) {
          weekProgress += e.progress;
        }
      }
      return weekProgress >= habit.dailyGoal;
    }
  }

  @override
  void dispose() {
    _db.removeListener(_onDatabaseChanged);
    super.dispose();
  }
}
