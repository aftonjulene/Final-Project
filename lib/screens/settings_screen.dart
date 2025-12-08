import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _workoutReminders = false;
  bool _socialUpdates = true;
  bool _privateProfile = false;
  bool _showStats = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: null,
            title: 'Workout Reminders',
            value: _workoutReminders,
            onChanged: (value) {
              setState(() {
                _workoutReminders = value;
              });
            },
            indent: true,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: null,
            title: 'Social Updates',
            value: _socialUpdates,
            onChanged: (value) {
              setState(() {
                _socialUpdates = value;
              });
            },
            indent: true,
          ),
          const SizedBox(height: 32),
          const Text(
            'Privacy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.lock,
            title: 'Private Profile',
            value: _privateProfile,
            onChanged: (value) {
              setState(() {
                _privateProfile = value;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: null,
            title: 'Show Stats',
            value: _showStats,
            onChanged: (value) {
              setState(() {
                _showStats = value;
              });
            },
            indent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    IconData? icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool indent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(icon, color: Colors.grey[700])
            : (indent ? const SizedBox(width: 24) : null),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: indent ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF1a1d2e),
        ),
      ),
    );
  }
}
