import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Column(
        children: [
          CircleAvatar(radius: 50),
          Text('John Doe'),
          Text('Fitness Goal: Build Muscle'),
        ],
      ),
    );
  }
}
