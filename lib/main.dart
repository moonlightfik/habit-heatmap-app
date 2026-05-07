import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_heatmap/models/habit.dart';
import 'package:habit_heatmap/providers/habit_provider.dart';
import 'package:habit_heatmap/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:habit_heatmap/routes/app_routes.dart';

/// Global navigator key used by NotificationService to show dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppTheme {
  static final ThemeData lightTheme = ThemeData.light();
  static final ThemeData darkTheme = ThemeData.dark();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitEntryAdapter());
  Hive.registerAdapter(HabitFrequencyAdapter());

  // Open boxes
  await Hive.openBox<Habit>('habits');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HabitProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Momentum',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(
                  // ignore: deprecated_member_use
                  textScaleFactor: themeProvider.textScaleFactor,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            initialRoute: '/splash',
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
