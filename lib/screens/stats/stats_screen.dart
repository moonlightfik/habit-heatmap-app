import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/providers/habit_provider.dart';
import 'package:habit_heatmap/core/utils/date_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  final List<Habit>? habits;
  
  const StatsScreen({super.key, this.habits});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'Weekly';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? AppTheme.lightBackground
          : AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),
                    _buildConsistencyScore(),
                    const SizedBox(height: 24),
                    _buildTopPerformingHabits(),
                    const SizedBox(height: 24),
                    _buildProgressionChart(),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  List<Habit> get _habits {
    if (widget.habits != null) {
      return widget.habits!;
    }
    return context.read<HabitProvider>().habits;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Momentum',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareInsights,
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: _exportData,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Insights',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your progress and celebrate your growth',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade100
            : AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Weekly'),
          ),
          Expanded(
            child: _buildPeriodButton('Monthly'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            period,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsistencyScore() {
    final consistencyData = _calculateConsistencyScore();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consistency Score',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${consistencyData['score']}%',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      consistencyData['increase'].toString().contains('+')
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      consistencyData['increase'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: consistencyData['score'] / 100,
            backgroundColor: Colors.white.withOpacity(0.2),
            color: Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingHabits() {
    final topHabits = _getTopPerformingHabits();
    
    if (topHabits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('No habits yet. Start adding some habits!'),
        ),
      );
    }
    
    return Container(
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
          const Text(
            'Top Performing Habits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topHabits.length,
            itemBuilder: (context, index) {
              final habit = topHabits[index];
              return _buildHabitPerformanceTile(habit, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPerformanceTile(Habit habit, int tileIndex) {
    final completionRate = _getHabitCompletionRate(habit);
    final color = _getPerformanceColor(completionRate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habit.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getHabitIcon(habit.name),
                  color: habit.color,
                  size: 20,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${completionRate.toInt()}% completion rate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${completionRate.toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (tileIndex < _getTopPerformingHabits().length - 1)
            const SizedBox(height: 16),
          if (tileIndex < _getTopPerformingHabits().length - 1)
            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressionChart() {
    final progressionData = _getProgressionData();
    final isWeekly = _selectedPeriod == 'Weekly';
    final now = DateTime.now();
    
    if (progressionData['activeHabits'].isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('Complete habits to see your progression!'),
        ),
      );
    }
    
    return Container(
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
          Text(
            isWeekly ? 'Weekly Progression' : '${DateFormat('MMMM').format(now)} Progression',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWeekly 
              ? 'Total completions over the last 7 days'
              : 'Cumulative habit growth in ${DateFormat('MMMM').format(now)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // Fix repeated labels
                      getTitlesWidget: (value, meta) {
                        if (isWeekly) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          if (value.toInt() >= 0 && value.toInt() < 7) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                        } else {
                          const weeks = ['W1', 'W2', 'W3', 'W4'];
                          if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                weeks[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
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
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: isWeekly ? 6 : 3,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: progressionData['activeHabits'],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: const LineTouchData(enabled: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Actual Progression', AppTheme.primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _calculateOverallStats();
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatTile(
          'Longest Streak',
          '${stats['longestStreak']} Days',
          Icons.local_fire_department,
          AppTheme.primaryColor,
        ),
        _buildStatTile(
          'Active Habits',
          '${stats['totalHabits']}',
          Icons.checklist,
          AppTheme.secondaryColor,
        ),
        _buildStatTile(
          'Completions',
          '${stats['totalCompletions']}',
          Icons.assignment_turned_in,
          AppTheme.accentColor,
        ),
        _buildStatTile(
          'Avg / Day',
          '${stats['avgPerDay']}',
          Icons.trending_up,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Data Calculation Methods
  Map<String, dynamic> _calculateConsistencyScore() {
    final habits = _habits;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final days = _selectedPeriod == 'Weekly' ? 7 : 30;
    
    int currentCompleted = 0;
    int currentPossible = 0;
    int previousCompleted = 0;
    int previousPossible = 0;
    
    final currentStart = todayStart.subtract(Duration(days: days - 1));
    final previousStart = currentStart.subtract(Duration(days: days));
    
    for (var habit in habits) {
      // Current Period
      final habitCreationDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
      
      final currentPeriodDays = todayStart.difference(
        habitCreationDate.isAfter(currentStart) ? habitCreationDate : currentStart
      ).inDays + 1;
      
      if (currentPeriodDays > 0) {
        final periodStart = todayStart.subtract(Duration(days: currentPeriodDays - 1));
        currentCompleted += habit.entries.where(
          (e) => (e.date.isAfter(periodStart) || HabitDateUtils.isSameDay(e.date, periodStart)) && e.progress >= habit.dailyGoal
        ).length;
        currentPossible += currentPeriodDays;
      }
      
      // Previous Period
      if (habitCreationDate.isBefore(currentStart)) {
        final prevPeriodStart = habitCreationDate.isAfter(previousStart) ? habitCreationDate : previousStart;
        final prevPeriodEnd = currentStart.subtract(const Duration(days: 1));
        final prevPeriodDays = prevPeriodEnd.difference(prevPeriodStart).inDays + 1;
        
        if (prevPeriodDays > 0) {
          previousCompleted += habit.entries.where(
            (e) => (e.date.isAfter(prevPeriodStart) || HabitDateUtils.isSameDay(e.date, prevPeriodStart)) &&
                   e.date.isBefore(currentStart) &&
                   e.progress >= habit.dailyGoal
          ).length;
          previousPossible += prevPeriodDays;
        }
      }
    }
    
    final currentScore = currentPossible > 0 ? (currentCompleted / currentPossible * 100).toInt() : 0;
    final previousScore = previousPossible > 0 ? (previousCompleted / previousPossible * 100).toInt() : 0;
    
    final diff = currentScore - previousScore;
    final increaseText = diff >= 0 ? '+$diff% vs last period' : '$diff% vs last period';
    
    return {
      'score': currentScore,
      'increase': increaseText,
    };
  }

  List<Habit> _getTopPerformingHabits() {
    final habits = _habits;
    final habitsWithRates = habits.map((habit) {
      return {
        'habit': habit,
        'rate': _getHabitCompletionRate(habit),
      };
    }).toList();
    
    habitsWithRates.sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));
    
    return habitsWithRates.take(4).map((e) => e['habit'] as Habit).toList();
  }

  double _getHabitCompletionRate(Habit habit) {
    final days = _selectedPeriod == 'Weekly' ? 7 : 30;
    return HabitDateUtils.getCompletionRate(
      habit.entries, 
      days, 
      creationDate: habit.createdAt, 
      goal: habit.dailyGoal
    ) * 100;
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 80) return AppTheme.successColor;
    if (rate >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  IconData _getHabitIcon(String habitName) {
    final name = habitName.toLowerCase();
    if (name.contains('run') || name.contains('workout') || name.contains('gym')) return Icons.directions_run;
    if (name.contains('read')) return Icons.menu_book;
    if (name.contains('meditat') || name.contains('breath')) return Icons.self_improvement;
    if (name.contains('water') || name.contains('hydrat')) return Icons.water_drop;
    if (name.contains('study') || name.contains('learn')) return Icons.school;
    return Icons.fitness_center;
  }

  Map<String, dynamic> _getProgressionData() {
    final habits = _habits;
    final List<FlSpot> activeHabitsSpots = [];
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    if (_selectedPeriod == 'Weekly') {
      // Last 7 days: Mon to Sun
      final monday = todayStart.subtract(Duration(days: todayStart.weekday - 1));
      int cumulativeCompletions = 0;
      
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        
        // Only count if day has passed or is today
        if (date.isAfter(todayStart)) {
          activeHabitsSpots.add(FlSpot(i.toDouble(), 0));
          continue;
        }

        int dailyCompletions = 0;
        for (var habit in habits) {
          final creationDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
          // Only count if habit existed on this date
          if (date.isAfter(creationDate) || HabitDateUtils.isSameDay(date, creationDate)) {
            if (habit.entries.any((e) => HabitDateUtils.isSameDay(e.date, date) && e.progress >= habit.dailyGoal)) {
              dailyCompletions++;
            }
          }
        }
        cumulativeCompletions += dailyCompletions;
        activeHabitsSpots.add(FlSpot(i.toDouble(), cumulativeCompletions.toDouble()));
      }
    } else {
      // Current Calendar Month: 4 standard blocks
      int cumulativeCompletions = 0;
      final firstOfMonth = DateTime(now.year, now.month, 1);
      
      for (int week = 0; week < 4; week++) {
        final weekStart = firstOfMonth.add(Duration(days: week * 7));
        // Simple 7-day blocks for W1-W4 (W4 includes the rest of the month)
        DateTime weekEnd = weekStart.add(const Duration(days: 6));
        if (week == 3) {
          // Last week block goes to the end of the month
          weekEnd = DateTime(now.year, now.month + 1, 0);
        }
        
        // If the whole week is in the future
        if (weekStart.isAfter(todayStart)) {
          activeHabitsSpots.add(FlSpot(week.toDouble(), 0));
          continue;
        }

        int weekCompletions = 0;
        for (var habit in habits) {
          final creationDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
          
          weekCompletions += habit.entries.where((e) {
            final isCorrectDay = (e.date.isAfter(weekStart) || HabitDateUtils.isSameDay(e.date, weekStart)) &&
                                 (e.date.isBefore(weekEnd) || HabitDateUtils.isSameDay(e.date, weekEnd));
            final existed = e.date.isAfter(creationDate) || HabitDateUtils.isSameDay(e.date, creationDate);
            final notFuture = e.date.isBefore(todayStart) || HabitDateUtils.isSameDay(e.date, todayStart);
            
            return isCorrectDay && existed && notFuture && e.progress >= habit.dailyGoal;
          }).length;
        }
        
        cumulativeCompletions += weekCompletions;
        activeHabitsSpots.add(FlSpot(week.toDouble(), cumulativeCompletions.toDouble()));
      }
    }
    
    return {
      'activeHabits': activeHabitsSpots,
      'target': [], // Not used
    };
  }

  Map<String, dynamic> _calculateOverallStats() {
    final habits = _habits;
    final days = _selectedPeriod == 'Weekly' ? 7 : 30;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final periodStart = todayStart.subtract(Duration(days: days - 1));
    
    int longestStreak = 0;
    int totalCompletions = 0;
    
    for (var habit in habits) {
      // Overall longest streak ever
      final streak = HabitDateUtils.calculateStreak(habit.entries);
      if (streak > longestStreak) longestStreak = streak;
      
      // Period specific completions
      final periodCompletions = habit.entries.where(
        (e) => (e.date.isAfter(periodStart) || HabitDateUtils.isSameDay(e.date, periodStart)) &&
               e.progress >= habit.dailyGoal
      ).length;
      totalCompletions += periodCompletions;
    }
    
    // As per user request: "average/day count ... must be calculated as total habits done/total habits"
    final avgPerDay = habits.isNotEmpty 
        ? (totalCompletions / habits.length).toStringAsFixed(1)
        : '0';
    
    return {
      'longestStreak': longestStreak,
      'totalHabits': habits.length,
      'totalCompletions': totalCompletions,
      'avgPerDay': avgPerDay,
    };
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (widget.habits == null) {
      await context.read<HabitProvider>().loadHabits();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _shareInsights() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
