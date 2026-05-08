import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_heatmap/core/theme/app_theme.dart';
import 'package:habit_heatmap/providers/theme_provider.dart';
import 'package:habit_heatmap/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _cloudSync = true;
  double _textSize = 16.0;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  String _lastSyncTime = '2 minutes ago';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _cloudSync = prefs.getBool('cloudSync') ?? true;
      _textSize = prefs.getDouble('textSize') ?? 16.0;
      final hour = prefs.getInt('reminderHour') ?? 20;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('pushNotifications', _pushNotifications);
    await prefs.setBool('cloudSync', _cloudSync);
    await prefs.setDouble('textSize', _textSize);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAppearanceSection(themeProvider),
                      const SizedBox(height: 32),
                      _buildAccountBackupSection(),
                      const SizedBox(height: 32),
                      _buildVersionInfo(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Momentum',
        style: GoogleFonts.inter(
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
          icon: const Icon(Icons.refresh),
          onPressed: _refreshSettings,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your experience and manage your data.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(ThemeProvider themeProvider) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'APPEARANCE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain in low light',
            icon: Icons.dark_mode_outlined,
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
              setState(() {
                _darkMode = value;
              });
            },
          ),
          _buildSliderTile(
            title: 'Text Size',
            subtitle: 'Adjust interface readability',
            icon: Icons.text_fields,
            value: themeProvider.textSize,
            min: 12,
            max: 24,
            onChanged: (value) {
              themeProvider.setTextSize(value);
            },
          ),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Daily reminders and streak alerts',
            icon: Icons.notifications_outlined,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
                _saveSettings();
              });
              NotificationService().setPushNotificationsEnabled(value);
            },
          ),
          _buildTimePickerTile(
            title: 'Reminder Time',
            subtitle: 'Set your daily check-in window',
            icon: Icons.access_time,
            time: _reminderTime,
            onTap: _selectReminderTime,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBackupSection() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'ACCOUNT & BACKUP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildSyncTile(
            title: 'Cloud Sync',
            subtitle: 'Last synced: $_lastSyncTime',
            icon: Icons.cloud_sync,
            value: _cloudSync,
            onChanged: (value) {
              setState(() {
                _cloudSync = value;
                _saveSettings();
                if (_cloudSync) {
                  _performCloudSync();
                }
              });
            },
            onSync: _performCloudSync,
          ),
          _buildActionTile(
            title: 'Export Data',
            subtitle: 'Download your habit history (JSON/CSV)',
            icon: Icons.download_outlined,
            onTap: _exportData,
            trailing: const Icon(Icons.chevron_right, size: 20),
          ),
          _buildActionTile(
            title: 'Momentum Plus',
            subtitle: 'Manage your premium subscription',
            icon: Icons.star_outline,
            onTap: _manageSubscription,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          _buildActionTile(
            title: 'Log Out',
            subtitle: 'Securely exit your account',
            icon: Icons.logout_outlined,
            onTap: _logout,
            trailing: const Icon(Icons.chevron_right, size: 20),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'Version 1.0.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2024 Momentum. All rights reserved.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toInt()}px',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time.format(context),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required VoidCallback onSync,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (value)
            IconButton(
              icon: const Icon(Icons.sync, size: 20),
              onPressed: onSync,
              color: AppTheme.primaryColor,
            ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppTheme.errorColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
        _saveSettings();
      });
      
      // Update the notification service
      NotificationService().updateGeneralReminderTime(picked.hour, picked.minute);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder time set to ${picked.format(context)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _performCloudSync() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _lastSyncTime = 'Just now';
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync completed successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('JSON Format'),
                onTap: () {
                  Navigator.pop(context);
                  _generateExport('json');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('CSV Format'),
                onTap: () {
                  Navigator.pop(context);
                  _generateExport('csv');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data as $format...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully as $format'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  void _manageSubscription() {
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
              Text(
                'Momentum Plus',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unlock premium features:',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildPremiumFeature('Unlimited habits'),
              _buildPremiumFeature('Advanced analytics'),
              _buildPremiumFeature('Cloud backup'),
              _buildPremiumFeature('Export data'),
              _buildPremiumFeature('Priority support'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Upgrade Now'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(feature, style: GoogleFonts.inter(fontSize: 14)),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out? You can always log back in to access your data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
    });
    
    Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logged out successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _refreshSettings() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings refreshed'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }
}