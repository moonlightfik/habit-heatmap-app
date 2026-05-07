import 'package:habit_heatmap/models/habit.dart';

class HabitDateUtils {
  static DateTime getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  static int calculateStreak(List<HabitEntry> entries, {HabitFrequency frequency = HabitFrequency.daily, int goal = 1}) {
    if (entries.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (frequency == HabitFrequency.daily) {
      // Daily logic
      var streak = 0;
      var currentDate = today;
      
      final Map<String, int> dailyProgress = {};
      for (var e in entries) {
        final key = '${e.date.year}-${e.date.month}-${e.date.day}';
        dailyProgress[key] = (dailyProgress[key] ?? 0) + e.progress;
      }

      // Check today first, if not done, check yesterday
      String todayKey = '${today.year}-${today.month}-${today.day}';
      if ((dailyProgress[todayKey] ?? 0) < goal) {
        currentDate = today.subtract(const Duration(days: 1));
      }

      while (true) {
        String key = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
        if ((dailyProgress[key] ?? 0) >= goal) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return streak;
    } else {
      // Weekly logic
      var streak = 0;
      var currentWeekStart = getStartOfWeek(today);
      
      final Map<String, int> weeklyProgress = {};
      for (var e in entries) {
        final weekStart = getStartOfWeek(e.date);
        final key = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
        weeklyProgress[key] = (weeklyProgress[key] ?? 0) + e.progress;
      }

      // Check current week first
      String currentKey = '${currentWeekStart.year}-${currentWeekStart.month}-${currentWeekStart.day}';
      if ((weeklyProgress[currentKey] ?? 0) < goal) {
        currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      }

      while (true) {
        String key = '${currentWeekStart.year}-${currentWeekStart.month}-${currentWeekStart.day}';
        if ((weeklyProgress[key] ?? 0) >= goal) {
          streak++;
          currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
        } else {
          break;
        }
      }
      return streak;
    }
  }
  
  static double getCompletionRate(List<HabitEntry> entries, int windowDays, {DateTime? creationDate, int goal = 1, HabitFrequency frequency = HabitFrequency.daily}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(Duration(days: windowDays - 1));
    
    DateTime actualStart = windowStart;
    if (creationDate != null) {
      final creationStart = DateTime(creationDate.year, creationDate.month, creationDate.day);
      if (creationStart.isAfter(windowStart)) {
        actualStart = creationStart;
      }
    }

    if (frequency == HabitFrequency.daily) {
      final daysToTrack = today.difference(actualStart).inDays + 1;
      int completed = 0;
      
      final Map<String, int> dailyProgress = {};
      for (var e in entries) {
        final key = '${e.date.year}-${e.date.month}-${e.date.day}';
        dailyProgress[key] = (dailyProgress[key] ?? 0) + e.progress;
      }

      for (int i = 0; i < daysToTrack; i++) {
        final date = actualStart.add(Duration(days: i));
        final key = '${date.year}-${date.month}-${date.day}';
        if ((dailyProgress[key] ?? 0) >= goal) completed++;
      }
      return daysToTrack > 0 ? completed / daysToTrack : 0.0;
    } else {
      // Weekly Completion Rate
      final startWeek = getStartOfWeek(actualStart);
      final endWeek = getStartOfWeek(today);
      
      int weeksToTrack = (endWeek.difference(startWeek).inDays ~/ 7) + 1;
      int completed = 0;

      final Map<String, int> weeklyProgress = {};
      for (var e in entries) {
        final ws = getStartOfWeek(e.date);
        final key = '${ws.year}-${ws.month}-${ws.day}';
        weeklyProgress[key] = (weeklyProgress[key] ?? 0) + e.progress;
      }

      for (int i = 0; i < weeksToTrack; i++) {
        final weekStart = startWeek.add(Duration(days: i * 7));
        final key = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
        if ((weeklyProgress[key] ?? 0) >= goal) completed++;
      }
      return weeksToTrack > 0 ? completed / weeksToTrack : 0.0;
    }
  }
  
  static Map<DateTime, int> getHeatmapData(List<HabitEntry> entries, int days) {
    final Map<DateTime, int> data = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days));
    
    // Aggregate by day
    final Map<String, int> dailyProgress = {};
    for (var e in entries) {
      final key = '${e.date.year}-${e.date.month}-${e.date.day}';
      dailyProgress[key] = (dailyProgress[key] ?? 0) + e.progress;
    }

    for (int i = 0; i <= days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      data[date] = dailyProgress[key] ?? 0;
    }
    
    return data;
  }
  
  static List<DateTime> getLastNDays(int n) {
    final now = DateTime.now();
    final List<DateTime> days = [];
    
    for (int i = n - 1; i >= 0; i--) {
      days.add(DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }
    
    return days;
  }
  
  static String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}