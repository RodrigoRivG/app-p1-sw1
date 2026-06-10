import 'package:flutter/material.dart';
import 'package:tramites_app/constants/colors_and_themes.dart';
import 'package:tramites_app/models/procedure.dart';
import 'package:tramites_app/widgets/info_row.dart';

class AnimatedProcedureCard extends StatefulWidget {
  final Procedure procedure;
  final int index;

  const AnimatedProcedureCard({
    super.key,
    required this.procedure,
    required this.index,
  });

  @override
  State<AnimatedProcedureCard> createState() => _AnimatedProcedureCardState();
}

class _AnimatedProcedureCardState extends State<AnimatedProcedureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ProcedureCard(procedure: widget.procedure),
        ),
      ),
    );
  }
}

class ProcedureCard extends StatelessWidget {
  final Procedure procedure;

  const ProcedureCard({super.key, required this.procedure});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      final months = [
        '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = statusColors[procedure.status] ?? const Color(0xFF9095B0);
    final statusLabel = statusLabels[procedure.status] ?? procedure.status;
    final statusIcon = statusIcons[procedure.status] ?? Icons.help_outline_rounded;

    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Colored top accent bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.3)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(
                            procedure.clientName.isNotEmpty
                                ? procedure.clientName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: accentSoft,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              procedure.clientName,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              procedure.clientEmail,
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: dividerColor, height: 1),
                  const SizedBox(height: 14),

                  // ── Info rows ───────────────
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Creado el',
                    value: _formatDate(procedure.createdAt),
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Nodo actual',
                    value: procedure.currentNodeId.isEmpty
                        ? '—'
                        : procedure.currentNodeId,
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    icon: Icons.tag_rounded,
                    label: 'ID del trámite',
                    value: procedure.id,
                    monospace: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
