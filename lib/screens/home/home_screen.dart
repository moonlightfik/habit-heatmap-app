import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/providers/habit_provider.dart';
import 'package:habit_heatmap/screens/habit/add_edit_habit_screen.dart';
import 'package:habit_heatmap/screens/habit/habit_detail_screen.dart';
import 'package:habit_heatmap/screens/home/widgets/habit_card.dart';
import 'package:habit_heatmap/screens/stats/stats_screen.dart';
import 'package:habit_heatmap/screens/settings/settings_screen.dart';
import 'package:habit_heatmap/services/notification_service.dart';
import 'package:habit_heatmap/main.dart' show navigatorKey;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadHabits();
      _notificationService.init(navigatorKey);
    });
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        final isLoading = habitProvider.isLoading;
        final weeklyStats = habitProvider.getWeeklyStats();

        // Keep notification service updated with latest habits
        _notificationService.updateHabits(habits);
        
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.light
              ? AppTheme.lightBackground
              : AppTheme.darkBackground,
          appBar: _buildAppBar(habits.isEmpty),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => habitProvider.loadHabits(),
                  child: habits.isEmpty
                      ? _buildEmptyState()
                      : _buildDashboard(habits, weeklyStats),
                ),
          floatingActionButton: habits.isEmpty ? null : _buildFloatingActionButton(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(bool isEmpty) {
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
      actions: isEmpty
          ? null
          : [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () {
                  final habits = context.read<HabitProvider>().habits;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(habits: habits),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.secondaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      size: 70,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                    Positioned(
                      bottom: 30,
                      right: 30,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Fresh Start',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                'Ready to start your streak?',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: Text(
                'Track your progress and visualize your growth.\nAdd your first habit to begin.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 48),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addFirstHabit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Add First Habit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _exploreTemplates,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'Explore Templates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(List<Habit> habits, Map<String, dynamic> weeklyStats) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(weeklyStats),
          const SizedBox(height: 24),
          _buildProgressOverview(weeklyStats),
          const SizedBox(height: 32),
          _buildHabitsSection(habits),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> weeklyStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your momentum is building.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You\'ve completed ${(weeklyStats['completionRate'] * 100).toInt()}% of your goals this week. Keep the streak alive to reach your monthly milestone.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressOverview(Map<String, dynamic> weeklyStats) {
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'MAX STREAK',
              '${weeklyStats['currentStreak']}',
              Icons.local_fire_department,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatCard(
              'DAILY HABITS',
              '${weeklyStats['dailyHabitsDone']} / ${weeklyStats['dailyHabitsTotal']} Done',
              Icons.checklist,
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatCard(
              'TOTAL PROGRESS',
              '${(weeklyStats['consistency'] * 100).toInt()}% Consistency',
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHabitsSection(List<Habit> habits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Habits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HabitCard(
                habit: habit,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitDetailScreen(habit: habit),
                    ),
                  );
                },
                onToggle: (isCompleted) {
                  context.read<HabitProvider>().toggleHabitCompletion(
                    habit.id,
                    DateTime.now(),
                    isCompleted,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _addFirstHabit,
      icon: const Icon(Icons.add),
      label: const Text('Add Habit'),
      backgroundColor: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Future<void> _addFirstHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditHabitScreen(),
      ),
    );
    if (result != null && result is Habit) {
      await context.read<HabitProvider>().addHabit(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit "${result.name}" created!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exploreTemplates() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Habit Templates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTemplateTile(
                icon: Icons.directions_run,
                name: 'Morning Run',
                description: 'Start your day with energy',
                onTap: () {
                  Navigator.pop(context);
                  _createTemplateHabit('Morning Run', AppTheme.primaryColor);
                },
              ),
              _buildTemplateTile(
                icon: Icons.menu_book,
                name: 'Read Daily',
                description: 'Read 20 pages every day',
                onTap: () {
                  Navigator.pop(context);
                  _createTemplateHabit('Read Daily', AppTheme.secondaryColor);
                },
              ),
              _buildTemplateTile(
                icon: Icons.self_improvement,
                name: 'Meditate',
                description: 'Find peace and clarity',
                onTap: () {
                  Navigator.pop(context);
                  _createTemplateHabit('Meditate', AppTheme.accentColor);
                },
              ),
              _buildTemplateTile(
                icon: Icons.fitness_center,
                name: 'Workout',
                description: 'Stay fit and healthy',
                onTap: () {
                  Navigator.pop(context);
                  _createTemplateHabit('Workout', AppTheme.successColor);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateTile({
    required IconData icon,
    required String name,
    required String description,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: onTap,
    );
  }

  void _createTemplateHabit(String name, Color color) {
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      frequency: HabitFrequency.daily,
      color: color,
      dailyGoal: 1,
      enableReminders: false,
      reminderTimeHour: null,
      reminderTimeMinute: null,
      createdAt: DateTime.now(),
    );
    
    context.read<HabitProvider>().addHabit(habit);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$name" habit created!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}