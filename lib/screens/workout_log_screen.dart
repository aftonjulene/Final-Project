import 'package:flutter/material.dart';

class WorkoutLogScreen extends StatefulWidget {
  @override
  _WorkoutLogScreenState createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final TextEditingController _workoutController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Workout')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _workoutController,
              decoration: InputDecoration(hintText: 'Workout Name'),
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(hintText: 'Duration (minutes)'),
            ),
            ElevatedButton(
              onPressed: () {
                
              },
              child: Text('Log Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
