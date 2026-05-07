import 'package:flutter/material.dart';
import 'package:habit_heatmap/screens/splash/splash_screen.dart';
import 'package:habit_heatmap/screens/onboarding/onboarding_screen.dart';
import 'package:habit_heatmap/screens/home/home_screen.dart';
import 'package:habit_heatmap/screens/habit/add_edit_habit_screen.dart';
import 'package:habit_heatmap/screens/stats/stats_screen.dart';
import 'package:habit_heatmap/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String addEditHabit = '/add-edit-habit';
  static const String habitDetail = '/habit-detail';
  static const String stats = '/stats';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      home: (context) => const HomeScreen(),
      addEditHabit: (context) => const AddEditHabitScreen(),
      stats: (context) => const StatsScreen(habits: []),
      settings: (context) => const SettingsScreen(),
    };
  }
}