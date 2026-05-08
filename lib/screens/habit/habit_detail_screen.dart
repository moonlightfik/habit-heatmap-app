import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/core/utils/date_utils.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/providers/habit_provider.dart';
import 'package:habit_heatmap/screens/habit/add_edit_habit_screen.dart';
import 'package:habit_heatmap/screens/home/widgets/heatmap_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late Habit _habit;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  String _getReminderTimeString() {
    if (_habit.reminderTimeHour != null && _habit.reminderTimeMinute != null) {
      final time = TimeOfDay(hour: _habit.reminderTimeHour!, minute: _habit.reminderTimeMinute!);
      return time.format(context);
    }
    return 'No reminder';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? AppTheme.lightBackground
          : AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryHeader(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildWeeklyPerformance(),
                  const SizedBox(height: 24),
                  _buildSmartInsights(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _habit.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: _showOptionsMenu,
        ),
      ],
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _habit.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _habit.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _habit.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: _habit.color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_habit.frequency == HabitFrequency.daily ? 'Daily' : 'Weekly'} • ${_getReminderTimeString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _editHabit,
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text(
              'Edit Habit',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _logToday,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(
              'Log Today',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _habit.color,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _calculateStats();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        // Significant height increase for mobile cards
        final aspectRatio = constraints.maxWidth > 600 ? 1.6 : 0.75;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              'CURRENT STREAK',
              '${stats['currentStreak']} Days',
              stats['streakIncrease'] ?? '+2 from last week',
              Icons.local_fire_department,
              _habit.color,
              trend: stats['streakIncrease'],
            ),
            _buildStatCard(
              'COMPLETION %',
              '${stats['completionPercentage']}%',
              stats['completionChange'] ?? '+5% from last month',
              Icons.percent,
              _habit.color,
              trend: stats['completionChange'],
            ),
            _buildStatCard(
              'BEST STREAK',
              '${stats['bestStreak']} Days',
              stats['bestStreakDate'] ?? 'Achieved ${_getBestStreakDate()}',
              Icons.emoji_events,
              _habit.color,
            ),
            _buildStatCard(
              'TOTAL LOGS',
              '${stats['totalLogs']}',
              stats['totalLogsPeriod'] ?? 'Since ${_getStartDate()}',
              Icons.calendar_today,
              _habit.color,
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (trend != null && trend.isNotEmpty) ...[
                Icon(
                  trend.contains('+') ? Icons.trending_up : Icons.trending_down,
                  size: 10,
                  color: trend.contains('+') ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 2),
              ],
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance() {
    final weeklyData = _getWeeklyPerformanceData();
    final isWeekly = _habit.frequency == HabitFrequency.weekly;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            isWeekly ? 'Performance (Last 7 Weeks)' : 'Weekly Performance',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWeekly ? 'Average weekly completion: ${weeklyData['averageRate']}' : 'Average completion rate: ${weeklyData['averageRate']}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (isWeekly) {
                          return Text('W${7 - value.toInt()}', style: const TextStyle(fontSize: 10));
                        }
                        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() >= 0 && value.toInt() < weekdays.length) {
                          return Text(
                            weekdays[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData['bars'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartInsights() {
    final insights = _generateInsights();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _habit.color.withOpacity(0.1),
            _habit.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _habit.color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: _habit.color,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight['icon'],
                size: 16,
                color: _habit.color,
              ),
              const SizedBox(width: 8),
              Text(
                insight['title'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _habit.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight['message'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    final entries = _habit.entries;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Current streak (Frequency aware)
    int currentStreak = HabitDateUtils.calculateStreak(
      entries, 
      frequency: _habit.frequency, 
      goal: _habit.dailyGoal
    );
    
    // Best streak
    // For simplicity, using current streak as best for now
    int bestStreak = currentStreak; 

    // Completion percentage
    final completionRate = HabitDateUtils.getCompletionRate(
      entries, 
      30, 
      creationDate: _habit.createdAt, 
      goal: _habit.dailyGoal,
      frequency: _habit.frequency
    );
    final completionPercentage = (completionRate * 100).toInt();
    
    // Weekly Progress (Mon-Sun)
    final startOfWeek = HabitDateUtils.getStartOfWeek(todayStart);
    int currentWeekProgress = 0;
    for (var e in entries) {
      if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), startOfWeek)) {
        currentWeekProgress += e.progress;
      }
    }

    // Previous period for comparison
    final previousPeriodRate = HabitDateUtils.getCompletionRate(
      entries, 
      60, // Total window
      creationDate: _habit.createdAt, 
      goal: _habit.dailyGoal,
      frequency: _habit.frequency
    );
    // This is a rough estimation of trend
    final prevRate = (previousPeriodRate * 100).toInt();
    final completionDiff = completionPercentage - prevRate;
    
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completionPercentage': completionPercentage,
      'completionDiff': completionDiff,
      'totalLogs': entries.length,
      'weeklyProgress': currentWeekProgress,
      'streakIncrease': 'Tracked ${_habit.frequency.name}',
      'completionChange': completionDiff >= 0 ? '+$completionDiff% trend' : '$completionDiff% trend',
      'bestStreakDate': _getBestStreakDate(),
      'totalLogsPeriod': 'Since ${_getStartDate()}',
    };
  }

  int _calculateStreakForPeriod(int days, [int offset = 0]) {
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = offset; i < offset + days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final entry = _habit.entries.firstWhere(
        (e) => HabitDateUtils.isSameDay(e.date, date),
        orElse: () => HabitEntry(habitId: '', date: date, progress: 0),
      );
      
      if (entry.progress >= _habit.dailyGoal) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  String _getBestStreakDate() {
    final entries = _habit.entries.where((e) => e.progress >= _habit.dailyGoal).toList();
    if (entries.isNotEmpty) {
      final bestStreakMonth = DateFormat('MMM yyyy').format(entries.first.date);
      return 'Achieved $bestStreakMonth';
    }
    return 'Achieved recently';
  }

  String _getStartDate() {
    if (_habit.entries.isNotEmpty) {
      final firstEntryDate = _habit.entries.first.date;
      return DateFormat('MMM d, yyyy').format(firstEntryDate);
    }
    return DateFormat('MMM d, yyyy').format(_habit.createdAt);
  }

  Map<String, dynamic> _getWeeklyPerformanceData() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final List<BarChartGroupData> bars = [];
    final isWeekly = _habit.frequency == HabitFrequency.weekly;
    
    if (isWeekly) {
      // Last 7 weeks
      final startOfCurrentWeek = HabitDateUtils.getStartOfWeek(todayStart);
      int totalWeeksCompleted = 0;
      
      for (int i = 0; i < 7; i++) {
        final weekStart = startOfCurrentWeek.subtract(Duration(days: (6 - i) * 7));
        int weekProgress = 0;
        for (var e in _habit.entries) {
          if (HabitDateUtils.isSameDay(HabitDateUtils.getStartOfWeek(e.date), weekStart)) {
            weekProgress += e.progress;
          }
        }
        
        double completionRate = (weekProgress.toDouble() / _habit.dailyGoal.toDouble()).clamp(0, 1) * 100;
        if (weekProgress >= _habit.dailyGoal) totalWeeksCompleted++;
        
        bars.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: completionRate,
                color: _habit.color,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
      
      final avgRate = (totalWeeksCompleted / 7 * 100).toInt();
      return {
        'bars': bars,
        'averageRate': '$avgRate%',
      };
    } else {
      // Current week: Mon to Sun
      final monday = HabitDateUtils.getStartOfWeek(todayStart);
      
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final entriesOnDay = _habit.entries.where(
          (e) => HabitDateUtils.isSameDay(e.date, date)
        ).toList();
        
        double completionRate = 0;
        if (entriesOnDay.isNotEmpty) {
          final dayProgress = entriesOnDay.fold<int>(0, (sum, e) => sum + e.progress);
          completionRate = (dayProgress.toDouble() / _habit.dailyGoal.toDouble()).clamp(0, 1) * 100;
        }
        
        bars.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: completionRate,
                color: _habit.color,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }
      
      final elapsedDaysInWeek = todayStart.difference(monday).inDays + 1;
      int totalCompletedInWeek = 0;
      for (int i = 0; i < elapsedDaysInWeek; i++) {
        final date = monday.add(Duration(days: i));
        if (_habit.entries.any((e) => HabitDateUtils.isSameDay(e.date, date) && e.progress >= _habit.dailyGoal)) {
          totalCompletedInWeek++;
        }
      }
      
      final avgRate = elapsedDaysInWeek > 0 ? (totalCompletedInWeek / elapsedDaysInWeek * 100).toInt() : 0;
      
      return {
        'bars': bars,
        'averageRate': '$avgRate%',
      };
    }
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];
    
    final morningCompletions = _habit.entries.where(
      (e) => e.progress >= _habit.dailyGoal && e.date.hour < 8
    ).length;
    final totalCompletions = _habit.entries.where((e) => e.progress >= _habit.dailyGoal).length;
    
    if (totalCompletions > 0 && morningCompletions / totalCompletions > 0.4) {
      insights.add({
        'icon': Icons.wb_sunny,
        'title': 'Mornings are your prime time',
        'message': 'You are 40% more likely to complete this habit when logged before 8:00 AM.',
      });
    }
    
    final saturdayCompletions = _habit.entries.where(
      (e) => e.date.weekday == DateTime.saturday && e.progress >= _habit.dailyGoal
    ).length;
    final totalSaturdays = _habit.entries.where((e) => e.date.weekday == DateTime.saturday).length;
    
    if (totalSaturdays > 0) {
      final saturdayRate = saturdayCompletions / totalSaturdays;
      if (saturdayRate < 0.7) {
        insights.add({
          'icon': Icons.warning_amber,
          'title': 'Consistency Warning',
          'message': 'Saturdays have a ${((1 - saturdayRate) * 100).toInt()}% lower completion rate. Try setting a reminder for the weekend.',
        });
      }
    }
    
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.trending_up,
        'title': 'Keep going!',
        'message': 'You\'re building momentum. Stay consistent and watch your streaks grow!',
      });
    }
    
    return insights;
  }

  void _editHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditHabitScreen(habit: _habit),
      ),
    );
    if (result != null && result is Habit) {
      // Preserve existing entries when editing
      final updatedHabit = result.copyWith(entries: _habit.entries);
      // Persist to database
      await context.read<HabitProvider>().updateHabit(updatedHabit);
      setState(() {
        _habit = updatedHabit;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${updatedHabit.name}" updated!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _logToday() {
    final today = DateTime.now();
    final existingEntry = _habit.entries.firstWhere(
      (e) => HabitDateUtils.isSameDay(e.date, today),
      orElse: () => HabitEntry(habitId: _habit.id, date: today, progress: 0),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        int progress = existingEntry.progress;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Log "${_habit.name}"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_habit.frequency == HabitFrequency.weekly 
                      ? 'Total weekly completions so far.' 
                      : 'How many times did you complete this today?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (progress > 0) progress--;
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '$progress / ${_habit.dailyGoal}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (progress < _habit.dailyGoal * 2) progress++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  if (_habit.frequency == HabitFrequency.weekly) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Goal: ${_habit.dailyGoal} per week',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<HabitProvider>().logProgress(_habit.id, progress);
                    Navigator.pop(context);
                    
                    setState(() {
                      final List<HabitEntry> updatedEntries = List.from(_habit.entries);
                      final index = updatedEntries.indexWhere(
                        (e) => HabitDateUtils.isSameDay(e.date, today)
                      );
                      
                      if (index != -1) {
                        updatedEntries[index] = HabitEntry(
                          habitId: _habit.id,
                          date: today,
                          progress: progress,
                        );
                      } else {
                        updatedEntries.add(HabitEntry(
                          habitId: _habit.id,
                          date: today,
                          progress: progress,
                        ));
                      }
                      
                      _habit = _habit.copyWith(entries: updatedEntries);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_habit.frequency == HabitFrequency.weekly 
                            ? 'Logged $progress/${_habit.dailyGoal} for this week'
                            : 'Logged $progress/${_habit.dailyGoal} for today'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _habit.color,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Habit'),
                onTap: () {
                  Navigator.pop(context);
                  _editHabit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete Habit'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Progress'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit'),
          content: Text('Are you sure you want to delete "${_habit.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<HabitProvider>().deleteHabit(_habit.id);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${_habit.name}" has been deleted'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
