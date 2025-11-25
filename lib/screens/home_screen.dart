import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/feed');
              },
              child: Text('View Feed'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/photo_journal');
              },
              child: Text('View Photo Journal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              child: Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
