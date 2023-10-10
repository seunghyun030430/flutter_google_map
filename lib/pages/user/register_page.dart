import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({Key? key, required this.showLoginPage}) : super(key: key);
  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Join Us!',
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
              ),
              const SizedBox(
                height: 20,
              ),
              CustomTextField(
                controller: passwordController,
                labelText: 'Password',
              ),
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                onTap: () {},
                text: 'Sign Up',
              ),
              const SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: widget.showLoginPage,
                child: const Text(
                  'Already have an account? Login now',
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
