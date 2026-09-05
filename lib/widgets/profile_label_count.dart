import 'package:flutter/material.dart';

class ProfileLabelCount extends StatelessWidget {
  final String labelText;
  final String count;

  const ProfileLabelCount({
    super.key,
    required this.labelText,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}
