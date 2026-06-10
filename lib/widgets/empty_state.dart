import 'package:flutter/material.dart';
import 'package:tramites_app/constants/colors_and_themes.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dividerColor),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: textSecondary,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No se encontraron trámites',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'No se encontraron trámites para este correo electrónico.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
