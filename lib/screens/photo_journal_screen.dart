import 'package:flutter/material.dart';

class PhotoJournalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Journal')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                
              },
              child: Text('Add Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
