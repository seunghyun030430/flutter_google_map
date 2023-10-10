import 'package:flutter/material.dart';
import 'package:demo/pages/user/login_page.dart';
import 'package:demo/pages/user/register_page.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showLoginPage = true;

  void toggleView() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      return LoginPage(
        showRegisterPage: toggleView,
      );
    } else {
      return RegisterPage(
        showLoginPage:  toggleView,
      );
    }
  }
}
