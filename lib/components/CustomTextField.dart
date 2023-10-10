import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget{
  final TextEditingController controller;
  final String labelText;

  const CustomTextField({Key? key, required this.controller, required this.labelText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextFormField(
        controller: controller,
        obscureText: false,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
          hintText: labelText,
          filled: true,
          fillColor: Colors.white
        ),
      ),
    );
  }
}