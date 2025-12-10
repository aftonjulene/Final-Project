import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _loading = false;
      return;
    }
    _userId = user.uid;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _pushNotifications =
            data['pushNotifications'] as bool? ?? _pushNotifications;
        _workoutReminders =
            data['workoutReminders'] as bool? ?? _workoutReminders;
        _socialUpdates = data['socialUpdates'] as bool? ?? _socialUpdates;
        _privateProfile = data['privateProfile'] as bool? ?? _privateProfile;
        _showStats = data['showStats'] as bool? ?? _showStats;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateSetting(String field, bool value) async {
    if (_userId == null) return;

    await FirebaseFirestore.instance.collection('users').doc(_userId).set({
      field: value,
    }, SetOptions(merge: true));

    if (field == 'privateProfile') {
      await _updateUserPrivacyOnWorkouts(value);
    }
  }

  Future<void> _updateUserPrivacyOnWorkouts(bool isPrivate) async {
    if (_userId == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: _userId)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'userIsPrivate': isPrivate});
      count++;

      if (count == 400) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

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
              _updateSetting('pushNotifications', value);
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
              _updateSetting('workoutReminders', value);
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
              _updateSetting('socialUpdates', value);
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
              _updateSetting('privateProfile', value);
            },
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
