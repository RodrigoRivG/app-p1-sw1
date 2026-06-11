import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tramites_app/constants/colors_and_themes.dart';
import 'package:tramites_app/models/procedure.dart';
import 'package:tramites_app/widgets/empty_state.dart';
import 'package:tramites_app/widgets/error_state.dart';
import 'package:tramites_app/widgets/procedure_card.dart';
import 'package:tramites_app/widgets/search_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Procedure> _procedures = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  void searchForEmail(String email) {
    _emailController.text = email;
    _fetchProcedures();
  }

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
        'https://sw1-p2-backend.onrender.com/api/procedures/by-email?email=${Uri.encodeComponent(email)}',
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
            backgroundColor: bgDark,
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
                        colors: [accent, accentSoft],
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
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Consulta el estado de tus gestiones',
                        style: TextStyle(
                          color: textSecondary,
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
              child: SearchCard(
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
              CircularProgressIndicator(color: accent),
              SizedBox(height: 16),
              Text('Buscando trámites…',
                  style: TextStyle(color: textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) return const SizedBox.shrink();

    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!);
    }

    if (_procedures.isEmpty) {
      return const EmptyState();
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
                  color: textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    color: accentSoft,
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
