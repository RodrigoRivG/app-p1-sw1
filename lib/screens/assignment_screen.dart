import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tramites_app/constants/colors_and_themes.dart';

class AssignmentScreen extends StatefulWidget {
  final Function(String) onSearchRequested;

  const AssignmentScreen({super.key, required this.onSearchRequested});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descController = TextEditingController();

  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechInitialized = false;

  // Flow State
  int _currentStep = 1; // 1: Form, 2: Recommendation, 3: Success
  bool _loading = false;
  String? _errorMessage;

  // Recommendation Results
  String _recommendedPolicyId = '';
  String _recommendedPolicyName = '';
  String _recommendationReason = '';

  // Success Results
  String _createdProcedureId = '';

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.8,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Speech Methods ──────────────────────────
  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _pulseCtrl.stop();
      await _speech.stop();
      return;
    }

    try {
      if (!_speechInitialized) {
        final hasSpeech = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
              _pulseCtrl.stop();
            }
          },
          onError: (error) {
            setState(() => _isListening = false);
            _pulseCtrl.stop();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error de dictado: ${error.errorMsg}')),
              );
            }
          },
        );
        if (hasSpeech) {
          _speechInitialized = true;
        }
      }

      if (_speechInitialized) {
        setState(() => _isListening = true);
        _pulseCtrl.repeat(reverse: true);
        await _speech.listen(
          localeId: 'es_ES',
          onResult: (result) {
            setState(() {
              _descController.text = result.recognizedWords;
            });
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El dictado por voz no está disponible en este dispositivo')),
          );
        }
      }
    } on Exception catch (e) {
      setState(() => _isListening = false);
      _pulseCtrl.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar micrófono: $e')),
        );
      }
    }
  }

  // ── API Methods ─────────────────────────────
  Future<void> _findPolicy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('http://192.168.0.14:8080/api/policies/assign-policy');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data;

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is String) {
          data = jsonDecode(decoded) as Map<String, dynamic>;
        } else {
          throw Exception('Formato de respuesta desconocido');
        }

        setState(() {
          _recommendedPolicyId = (data['policyId'] ?? '') as String;
          _recommendedPolicyName = (data['policyName'] ?? '') as String;
          _recommendationReason = (data['reason'] ?? '') as String;
          _currentStep = 2; // Go to recommendation
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error del servidor (${response.statusCode}).';
          _loading = false;
        });
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'No se pudo conectar al servidor.\n${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _startProcedure() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('http://10.0.2.2:8080/api/procedures');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'policyId': _recommendedPolicyId,
          'clientName': _nameController.text.trim(),
          'clientEmail': _emailController.text.trim(),
          'clientInfo': {},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final Map<String, dynamic> data;

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          throw Exception('Formato de respuesta desconocido');
        }

        setState(() {
          _createdProcedureId = (data['id'] ?? '') as String;
          _currentStep = 3; // Go to success screen
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error del servidor al crear trámite (${response.statusCode}).';
          _loading = false;
        });
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'No se pudo crear el trámite.\n${e.toString()}';
        _loading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _emailController.clear();
      _descController.clear();
      _recommendedPolicyId = '';
      _recommendedPolicyName = '';
      _recommendationReason = '';
      _createdProcedureId = '';
      _errorMessage = null;
      _currentStep = 1;
    });
  }

  // ── Build Methods ───────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Iniciar Trámite Inteligente',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: bgDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _loading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: accent),
                      SizedBox(height: 16),
                      Text('Procesando solicitud con IA…',
                          style: TextStyle(color: textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                      ],
                      _buildCurrentStepWidget(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 1:
        return _buildFormStep();
      case 2:
        return _buildRecommendationStep();
      case 3:
        return _buildSuccessStep();
      default:
        return _buildFormStep();
    }
  }

  // --- Step 1: Form Layout ---
  Widget _buildFormStep() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresá tus datos para empezar',
              style: TextStyle(
                  color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'La IA te asignará la política correspondiente según tu descripción.',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Name Field
            _buildLabel('Nombre completo'),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: _inputDecoration('Ej. Carlos Mendoza', Icons.person_outline),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresá tu nombre' : null,
            ),
            const SizedBox(height: 16),

            // Email Field
            _buildLabel('Correo electrónico'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: _inputDecoration('carlos@correo.com', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá tu correo';
                final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!regex.hasMatch(v.trim())) return 'Ingresá un correo válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Case Description Field
            Row(
              children: [
                _buildLabel('Describe tu situación o caso'),
                const Spacer(),
                // Animated Voice Button
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseCtrl.value : 1.0,
                      child: child,
                    );
                  },
                  child: IconButton(
                    onPressed: _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? const Color(0xFFEF4444) : accentSoft,
                      size: 22,
                    ),
                    tooltip: 'Dictar por voz',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: 'Explica qué necesitas realizar o tu caso aquí...',
                hintStyle: const TextStyle(color: textSecondary, fontSize: 13),
                filled: true,
                fillColor: bgDark,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accent, width: 1.5),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Ingresá una descripción' : null,
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [accent, Color(0xFF8B63FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _findPolicy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.psychology_outlined, size: 20),
                  label: const Text(
                    'Encontrar mi trámite',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Recommendation Layout ---
  Widget _buildRecommendationStep() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF10B981),
              child: Icon(Icons.done_all_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              '¡Trámite Recomendado!',
              style: TextStyle(
                  color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel('Política recomendada'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Text(
              _recommendedPolicyName,
              style: const TextStyle(
                color: accentSoft,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),

          _buildLabel('Justificación de la recomendación'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Text(
              _recommendationReason,
              style: const TextStyle(
                color: textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Confirm Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _startProcedure,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Confirmar e Iniciar Trámite',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Retry Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep = 1),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: dividerColor),
                foregroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Intentar de nuevo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Success Layout ---
  Widget _buildSuccessStep() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dividerColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF10B981),
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Trámite Creado con Éxito!',
            style: TextStyle(
                color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se ha registrado tu solicitud bajo el siguiente identificador de trámite.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _createdProcedureId,
                    style: const TextStyle(
                      color: accentSoft,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _createdProcedureId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID copiado al portapapeles')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: textSecondary, size: 20),
                  tooltip: 'Copiar ID',
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Go to Status Query Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [accent, Color(0xFF8B63FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final email = _emailController.text.trim();
                  _resetForm();
                  widget.onSearchRequested(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text(
                  'Consultar mi trámite',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Start another button
          TextButton(
            onPressed: _resetForm,
            child: const Text(
              'Iniciar otro trámite',
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSecondary, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: textSecondary, size: 18),
      filled: true,
      fillColor: bgDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
