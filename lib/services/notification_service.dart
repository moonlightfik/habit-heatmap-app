import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A notification service that periodically checks habit reminder times
/// and shows a dialog listing habits due today.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _checkTimer;
  GlobalKey<NavigatorState>? _navigatorKey;
  List<Habit> _habits = [];
  bool _pushNotificationsEnabled = true;
  final Set<String> _notifiedToday = {};
  bool _isDialogShowing = false;

  int _generalReminderHour = 20;
  int _generalReminderMinute = 0;

  /// Initialize the service with a navigator key for showing dialogs
  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _loadNotificationPreference();
    _startPeriodicCheck();
  }

  /// Update the list of habits to monitor
  void updateHabits(List<Habit> habits) {
    _habits = habits;
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotificationsEnabled = prefs.getBool('pushNotifications') ?? true;
    _generalReminderHour = prefs.getInt('reminderHour') ?? 20;
    _generalReminderMinute = prefs.getInt('reminderMinute') ?? 0;
  }

  /// Call this when the push notification setting changes
  void setPushNotificationsEnabled(bool enabled) {
    _pushNotificationsEnabled = enabled;
  }

  /// Update the general reminder time
  void updateGeneralReminderTime(int hour, int minute) {
    _generalReminderHour = hour;
    _generalReminderMinute = minute;
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    // Check every 10 seconds so we don't miss the minute window
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkReminders();
    });
    // Also check immediately
    Future.delayed(const Duration(seconds: 2), () => _checkReminders());
  }

  void _checkReminders() {
    if (!_pushNotificationsEnabled || _navigatorKey == null) return;
    if (_isDialogShowing) return;

    final now = TimeOfDay.now();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final isMonday = today.weekday == DateTime.monday;

    // 1. Check General Reminder
    final generalNotifKey = 'general_$todayKey';
    if (!_notifiedToday.contains(generalNotifKey)) {
      if (now.hour == _generalReminderHour && now.minute == _generalReminderMinute) {
        _notifiedToday.add(generalNotifKey);
        _showGeneralReminderDialog();
        return; // Show general first, don't overlap with habits
      }
    }

    // 2. Check Habit Reminders
    List<Habit> habitsToRemind = [];

    for (final habit in _habits) {
      if (!habit.enableReminders) continue;
      if (habit.reminderTimeHour == null || habit.reminderTimeMinute == null) continue;

      // Weekly habits only remind on their specific day (default to Monday if not set)
      if (habit.frequency == HabitFrequency.weekly) {
        final targetDay = habit.reminderWeekday ?? DateTime.monday;
        if (today.weekday != targetDay) continue;
      }

      final notifKey = '${habit.id}_$todayKey';
      if (_notifiedToday.contains(notifKey)) continue;

      // Check if current time matches reminder time
      if (now.hour == habit.reminderTimeHour! && now.minute == habit.reminderTimeMinute!) {
        _notifiedToday.add(notifKey);
        habitsToRemind.add(habit);
      }
    }

    if (habitsToRemind.isNotEmpty) {
      _showReminderDialog(habitsToRemind);
    }

    // Reset notifications at midnight
    final lastResetDate = _notifiedToday.isEmpty ? '' : _notifiedToday.first.split('_').last;
    if (lastResetDate.isNotEmpty && lastResetDate != todayKey) {
      _notifiedToday.clear();
    }
  }

  void _showGeneralReminderDialog() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    _isDialogShowing = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daily Motivation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "We have a lot to work on today! Ready to make some progress?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isDialogShowing = false;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Let's Get Started", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _isDialogShowing = false);
  }

  void _showReminderDialog(List<Habit> habits) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bell icon with animation
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.secondaryColor.withOpacity(0.2),
                        AppTheme.accentColor.withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppTheme.secondaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Habit Reminder',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  habits.length == 1
                      ? "It's time for your habit!"
                      : "You have ${habits.length} habits to complete!",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                // Habits list
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Column(
                      children: habits.map((habit) {
                        final frequencyLabel = habit.frequency == HabitFrequency.daily
                            ? 'Daily'
                            : 'Weekly';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: habit.color.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: habit.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  color: habit.color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      habit.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$frequencyLabel • Goal: ${habit.dailyGoal}x',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: habit.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  frequencyLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: habit.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _isDialogShowing = false;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Let's Go!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _navigatorKey = null;
  }
}
