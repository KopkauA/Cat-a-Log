import 'package:flutter/material.dart';
import 'colors.dart';

class PawDropdown extends StatelessWidget {
  const PawDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.person, color: gray, size: 28),
      onSelected: (value) {
        if (value == 'about') {
          // Navigate to About us page
        } else if (value == 'data') {
          // Navigate to Data page
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'about',
          child: Text('About us'),
        ),
        PopupMenuItem(
          value: 'data',
          child: Text('Data'),
        ),
      ],
    );
  }
}
