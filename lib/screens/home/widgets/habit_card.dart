import 'package:flutter/material.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/core/utils/date_utils.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final Function(bool) onToggle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onToggle,
  });

  String _getReminderTimeString(BuildContext context) {
    if (habit.reminderTimeHour != null && habit.reminderTimeMinute != null) {
      final time = TimeOfDay(hour: habit.reminderTimeHour!, minute: habit.reminderTimeMinute!);
      return time.format(context);
    }
    return 'No reminder';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final streak = HabitDateUtils.calculateStreak(habit.entries, frequency: habit.frequency, goal: habit.dailyGoal);
    final isWeekly = habit.frequency == HabitFrequency.weekly;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: habit.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streak ${isWeekly ? 'Weeks' : 'Days'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: habit.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getReminderTimeString(context),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: _isCompleted(),
                  onChanged: (value) {
                    onToggle(value ?? false);
                  },
                  activeColor: habit.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressBar(isWeekly ? 'Past 14 Weeks' : 'Past 14 Days', stats['past14'] ?? 0),
                const SizedBox(width: 16),
                if (stats.containsKey('past28'))
                  _buildProgressBar(isWeekly ? 'Past 28 Weeks' : 'Past 28 Days', stats['past28'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: habit.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              color: habit.color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats() {
    final past14 = HabitDateUtils.getCompletionRate(
      habit.entries, 
      habit.frequency == HabitFrequency.daily ? 14 : 14 * 7, 
      creationDate: habit.createdAt, 
      goal: habit.dailyGoal,
      frequency: habit.frequency
    );
    final stats = <String, double>{
      'past14': past14,
    };
    
    final daysSinceCreation = DateTime.now().difference(habit.createdAt).inDays + 1;
    if (habit.frequency == HabitFrequency.daily ? daysSinceCreation > 14 : daysSinceCreation > 14 * 7) {
      stats['past28'] = HabitDateUtils.getCompletionRate(
        habit.entries, 
        habit.frequency == HabitFrequency.daily ? 28 : 28 * 7, 
        creationDate: habit.createdAt, 
        goal: habit.dailyGoal,
        frequency: habit.frequency
      );
    }
    
    return stats;
  }

  bool _isCompleted() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (habit.frequency == HabitFrequency.daily) {
      return habit.entries.any(
        (entry) => HabitDateUtils.isSameDay(entry.date, today) && entry.progress >= habit.dailyGoal,
      );
    } else {
      // Weekly: sum of progress in current week
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
}