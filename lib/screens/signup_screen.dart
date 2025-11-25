import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signUp() async {
    
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(hintText: 'Email'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(hintText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
