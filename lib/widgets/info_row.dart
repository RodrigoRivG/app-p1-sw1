import 'package:flutter/material.dart';
import 'package:tramites_app/constants/colors_and_themes.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: textSecondary, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: textSecondary, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: monospace ? 'monospace' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
