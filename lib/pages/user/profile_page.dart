import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/components/CustomTextField.dart';
import 'package:demo/components/CustomButton.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Hello',
                style: TextStyle(
                  fontSize: 30,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Icon(
                Icons.person_2_rounded,
                size: 100,
              ),
              const SizedBox(
                height: 20,
              ),
              Text(user!.email!),
              const SizedBox(
                height: 20,
              ),
              CustomButton(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                },
                text: 'Sign Out',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
