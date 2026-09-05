import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isPass;
  final String hintText;
  final TextInputType textInputType;
  final Function(String)? onChanged;

  const TextFieldInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.textInputType,
    this.isPass = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.white24, width: 1),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: isPass,
      keyboardType: textInputType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF160A22), // Tema gelap Oxide2
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5), // Merah Oxide2
        ),
        enabledBorder: inputBorder,
      ),
    );
  }
}
