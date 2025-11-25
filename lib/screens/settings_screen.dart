import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = false;
  bool _privateProfile = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Push Notifications'),
              value: _pushNotifications,
              onChanged: (bool value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Private Profile'),
              value: _privateProfile,
              onChanged: (bool value) {
                setState(() {
                  _privateProfile = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                // Added Logout functionality
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
