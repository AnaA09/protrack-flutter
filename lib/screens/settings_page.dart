import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cognito_service.dart';
import '../routes/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  bool _autoSync = true;
  String _selectedDateFormat = 'MM/DD/YYYY';
  String _selectedTimeFormat = '12-hour';
  bool _showProjectDeadlines = true;
  bool _showTaskDueDates = true;
  bool _enableEmailNotifications = true;
  bool _enablePushNotifications = true;

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _dateFormats = ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'];
  final List<String> _timeFormats = ['12-hour', '24-hour'];

  Future<void> _signOut() async {
    final cognitoService = Provider.of<CognitoService>(context, listen: false);
    await cognitoService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Account Settings
          _buildSectionHeader('Account Settings'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Update your profile information'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: const Text('Change your email address'),
            onTap: () {
              // Navigate to email change
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('Change password and security settings'),
            onTap: () {
              // Navigate to security settings
            },
          ),
          _buildDivider(), // Display Settings
          _buildSectionHeader('Display Settings'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark/light theme'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                }
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date Format'),
            subtitle: Text(_selectedDateFormat),
            trailing: DropdownButton<String>(
              value: _selectedDateFormat,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDateFormat = newValue;
                  });
                }
              },
              items: _dateFormats.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time Format'),
            subtitle: Text(_selectedTimeFormat),
            trailing: DropdownButton<String>(
              value: _selectedTimeFormat,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTimeFormat = newValue;
                  });
                }
              },
              items: _timeFormats.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          _buildDivider(),

          // Project & Task Settings
          _buildSectionHeader('Project & Task Settings'),
          SwitchListTile(
            secondary: const Icon(Icons.event),
            title: const Text('Show Project Deadlines'),
            subtitle: const Text('Display project deadlines in calendar'),
            value: _showProjectDeadlines,
            onChanged: (bool value) {
              setState(() {
                _showProjectDeadlines = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.assignment_turned_in),
            title: const Text('Show Task Due Dates'),
            subtitle: const Text('Display task due dates in calendar'),
            value: _showTaskDueDates,
            onChanged: (bool value) {
              setState(() {
                _showTaskDueDates = value;
              });
            },
          ),
          _buildDivider(),

          // Notifications
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.mark_email_unread),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive email notifications'),
            value: _enableEmailNotifications,
            onChanged: (bool value) {
              setState(() {
                _enableEmailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notification_important),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications'),
            value: _enablePushNotifications,
            onChanged: (bool value) {
              setState(() {
                _enablePushNotifications = value;
              });
            },
          ),
          _buildDivider(), // Data & Storage
          _buildSectionHeader('Data & Storage'),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Auto Sync'),
            subtitle: const Text('Automatically sync data in background'),
            value: _autoSync,
            onChanged: (bool value) {
              setState(() {
                _autoSync = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Clear Cache'),
            subtitle: const Text('Delete temporary files'),
            onTap: () {
              // Implement cache clearing
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            subtitle: const Text('Export your data to a file'),
            onTap: () {
              // Implement data export
            },
          ),
          _buildDivider(),

          // Support & Legal
          _buildSectionHeader('Support & Legal'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('View documentation and get help'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.help),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About ProTrack'),
            subtitle: const Text('Version information and updates'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('View our privacy policy'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Service'),
            subtitle: const Text('View terms of service'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.termsOfService),
          ),
          _buildDivider(),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(indent: 16, endIndent: 16);
  }
}
