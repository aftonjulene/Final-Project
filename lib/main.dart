import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/photo_journal_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',  // Set the initial route
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
        '/feed': (context) => FeedScreen(),
        '/profile': (context) => ProfileScreen(),
        '/photo_journal': (context) => PhotoJournalScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
