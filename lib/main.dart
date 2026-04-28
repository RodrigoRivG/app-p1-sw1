import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TramitesApp());
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────

class Procedure {
  final String id;
  final String clientName;
  final String clientEmail;
  final String status;
  final String createdAt;
  final String currentNodeId;

  const Procedure({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.status,
    required this.createdAt,
    required this.currentNodeId,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    return Procedure(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'Sin nombre',
      clientEmail: json['clientEmail'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      createdAt: json['createdAt'] as String? ?? '',
      currentNodeId: json['currentNodeId'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────
// Constants / Design tokens
// ─────────────────────────────────────────────

const _bgDark = Color(0xFF0D0F18);
const _surface = Color(0xFF161925);
const _surfaceCard = Color(0xFF1E2235);
const _accent = Color(0xFF6C63FF);
const _accentSoft = Color(0xFF8B85FF);
const _textPrimary = Color(0xFFECEFF8);
const _textSecondary = Color(0xFF9095B0);
const _divider = Color(0xFF252A40);

const _statusColors = {
  'in_progress': Color(0xFF3B82F6),
  'completed': Color(0xFF22C55E),
  'cancelled': Color(0xFFEF4444),
};

const _statusLabels = {
  'in_progress': 'En progreso',
  'completed': 'Completado',
  'cancelled': 'Cancelado',
};

const _statusIcons = {
  'in_progress': Icons.hourglass_top_rounded,
  'completed': Icons.check_circle_rounded,
  'cancelled': Icons.cancel_rounded,
};

// ─────────────────────────────────────────────
// App root
// ─────────────────────────────────────────────

class TramitesApp extends StatelessWidget {
  const TramitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de Trámites',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          background: _bgDark,
          surface: _surface,
          primary: _accent,
        ),
        scaffoldBackgroundColor: _bgDark,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// Home screen
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Procedure> _procedures = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── API call ─────────────────────────────────
  Future<void> _fetchProcedures() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() {
      _loading = true;
      _hasSearched = false;
      _errorMessage = null;
      _procedures = [];
    });

    _fadeCtrl.reset();

    try {
      final uri = Uri.parse(
        'https://sw1-p1-backend2-123084394988.southamerica-east1.run.app/api/procedures/by-email?email=${Uri.encodeComponent(email)}',
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data;

        // Handle both list and single object responses
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          data = [decoded];
        } else {
          data = [];
        }

        setState(() {
          _procedures = data.map((e) => Procedure.fromJson(e as Map<String, dynamic>)).toList();
          _hasSearched = true;
          _loading = false;
        });
        _fadeCtrl.forward();
      } else {
        setState(() {
          _errorMessage = 'Error del servidor (${response.statusCode}). Intente nuevamente.';
          _loading = false;
          _hasSearched = true;
        });
        _fadeCtrl.forward();
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'No se pudo conectar al servidor.\n${e.toString()}';
        _loading = false;
        _hasSearched = true;
      });
      _fadeCtrl.forward();
    }
  }

  // ── Build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: _bgDark,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accent, _accentSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Trámites',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Consulta el estado de tus gestiones',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Search card ─────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _SearchCard(
                formKey: _formKey,
                emailController: _emailController,
                loading: _loading,
                onSearch: _fetchProcedures,
              ),
            ),
          ),

          // ── Results ─────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildResults(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: _accent),
              SizedBox(height: 16),
              Text('Buscando trámites…',
                  style: TextStyle(color: _textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) return const SizedBox.shrink();

    if (_errorMessage != null) {
      return _ErrorState(message: _errorMessage!);
    }

    if (_procedures.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Row(
            children: [
              Text(
                '${_procedures.length} trámite${_procedures.length != 1 ? "s" : ""} encontrado${_procedures.length != 1 ? "s" : ""}',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    color: _accentSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._procedures.asMap().entries.map((entry) {
          return AnimatedProcedureCard(
            procedure: entry.value,
            index: entry.key,
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Search card widget
// ─────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool loading;
  final VoidCallback onSearch;

  const _SearchCard({
    required this.formKey,
    required this.emailController,
    required this.loading,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresá tu correo electrónico',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Consultá el estado de todos tus trámites',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              cursorColor: _accent,
              decoration: InputDecoration(
                hintText: 'ejemplo@correo.com',
                hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.email_outlined, color: _textSecondary, size: 20),
                filled: true,
                fillColor: _bgDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresá un correo electrónico';
                }
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresá un correo válido';
                }
                return null;
              },
              onFieldSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accent, Color(0xFF8B63FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search_rounded, size: 20),
                  label: Text(
                    loading ? 'Consultando…' : 'Consultar',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Animated procedure card
// ─────────────────────────────────────────────

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
          child: _ProcedureCard(procedure: widget.procedure),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Procedure card
// ─────────────────────────────────────────────

class _ProcedureCard extends StatelessWidget {
  final Procedure procedure;

  const _ProcedureCard({required this.procedure});

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
    final statusColor = _statusColors[procedure.status] ?? const Color(0xFF9095B0);
    final statusLabel = _statusLabels[procedure.status] ?? procedure.status;
    final statusIcon = _statusIcons[procedure.status] ?? Icons.help_outline_rounded;

    return Container(
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
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
                          color: _accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _accent.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(
                            procedure.clientName.isNotEmpty
                                ? procedure.clientName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _accentSoft,
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
                                color: _textPrimary,
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
                                color: _textSecondary,
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
                  const Divider(color: _divider, height: 1),
                  const SizedBox(height: 14),

                  // ── Info rows ───────────────
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Creado el',
                    value: _formatDate(procedure.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.account_tree_outlined,
                    label: 'Nodo actual',
                    value: procedure.currentNodeId.isEmpty
                        ? '—'
                        : procedure.currentNodeId,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
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

// ─────────────────────────────────────────────
// Info row helper
// ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  const _InfoRow({
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
        Icon(icon, color: _textSecondary, size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textPrimary,
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

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _divider),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: _textSecondary,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No se encontraron trámites',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'No se encontraron trámites para este correo electrónico.',
            style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error al consultar',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
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
