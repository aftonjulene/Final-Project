import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activity Feed')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Alex Chen - Morning Run'),
            subtitle: Text('5km in 28 minutes'),
          ),
          ListTile(
            title: Text('Sarah Martinez - Leg Day'),
            subtitle: Text('6 exercises • 45 minutes'),
          ),
        ],
      ),
    );
  }
}
