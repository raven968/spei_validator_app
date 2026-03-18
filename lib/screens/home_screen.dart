import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/validation_service.dart';
import '../models/validation_result.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _dateController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;
  ValidationResult? _result;
  String? _errorMessage;

  late AnimationController _resultAnimController;
  late Animation<double> _resultFadeAnim;

  @override
  void initState() {
    super.initState();
    // Default date: today in dd-MM-yyyy
    _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFadeAnim = CurvedAnimation(
      parent: _resultAnimController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF00E676),
              onPrimary: const Color(0xFF0D1B2A),
              surface: const Color(0xFF1B2838),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
        _errorMessage = null;
        _resultAnimController.reset();
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B2838),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar imagen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00E676)),
                ),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Tomar una foto nueva', style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF448AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF448AFF)),
                ),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Elegir de tus fotos', style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validate() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una imagen primero'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
      _resultAnimController.reset();
    });

    try {
      final result = await ApiService.validateSpei(
        fecha: _dateController.text,
        imageFile: _selectedImage!,
      );
      setState(() {
        _result = result;
        _isLoading = false;
      });
      _resultAnimController.forward();
      // Guardar en historial si el usuario tiene plan Business (silencioso)
      ValidationService.saveResult(
        result: result,
        fechaOperacion: _dateController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      _resultAnimController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0D1B2A), size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPEI Validator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Valida tu comprobante de transferencia',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.workspace_premium_rounded,
                        color: Color(0xFF00E676), size: 22),
                    tooltip: 'Mi subscripción',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const SubscriptionScreen(fromHome: true)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white38, size: 22),
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Date Input ──
              _buildLabel('Fecha de operación'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1B2838),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.calendar_today_rounded, color: Color(0xFF00E676), size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_drop_down_rounded, color: Colors.white38, size: 28),
                      ),
                      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF2A3F55), width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Image Input ──
              _buildLabel('Captura de transferencia'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 180),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2838),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? const Color(0xFF00E676).withValues(alpha: 0.4)
                          : const Color(0xFF2A3F55),
                      width: _selectedImage != null ? 1.5 : 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _result = null;
                                        _errorMessage = null;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: Color(0xFF00E676),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Toca para seleccionar imagen',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Cámara o Galería',
                              style: TextStyle(color: Colors.white30, fontSize: 12),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Validate Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF0D1B2A),
                    disabledBackgroundColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D1B2A),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Validar Transferencia'),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Results ──
              if (_result != null || _errorMessage != null)
                FadeTransition(
                  opacity: _resultFadeAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(_resultFadeAnim),
                    child: _errorMessage != null
                        ? _buildErrorCard(_errorMessage!)
                        : _buildResultCards(_result!),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade200, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCards(ValidationResult result) {
    return Column(
      children: [
        // ── Validation Status ──
        _buildStatusCard(result),
        if (result.isValidFormat && result.extractedData != null) ...[
          const SizedBox(height: 14),
          _buildExtractedDataCard(result.extractedData!),
        ],
        if (result.banxicoStatus != null) ...[
          const SizedBox(height: 14),
          _buildBanxicoCard(result.banxicoStatus!),
        ],
      ],
    );
  }

  Widget _buildStatusCard(ValidationResult result) {
    final isValid = result.isValidFormat;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [const Color(0xFF00E676).withValues(alpha: 0.12), const Color(0xFF00C853).withValues(alpha: 0.06)]
              : [Colors.red.withValues(alpha: 0.12), Colors.red.withValues(alpha: 0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? const Color(0xFF00E676).withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isValid ? const Color(0xFF00E676) : Colors.red).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isValid ? const Color(0xFF00E676) : Colors.red.shade300,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Formato Válido' : 'Formato Inválido',
                  style: TextStyle(
                    color: isValid ? const Color(0xFF00E676) : Colors.red.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isValid && result.issues.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...result.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $issue',
                      style: TextStyle(color: Colors.red.shade200, fontSize: 13),
                    ),
                  )),
                ],
                if (isValid)
                  const Text(
                    'La imagen fue verificada visualmente',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedDataCard(Map<String, dynamic> data) {
    final fields = <MapEntry<String, String>>[
      MapEntry('Banco Emisor', data['banco_emisor']?.toString() ?? '—'),
      MapEntry('Banco Receptor', data['banco_receptor']?.toString() ?? '—'),
      MapEntry('Cuenta Beneficiaria', data['cuenta_beneficiaria']?.toString() ?? '—'),
      MapEntry('Monto', '\$${data['monto']?.toString() ?? '0.00'}'),
      MapEntry('Clave de Rastreo', data['clave_rastreo']?.toString() ?? '—'),
      MapEntry('Fecha', data['fecha']?.toString() ?? '—'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3F55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: Color(0xFF448AFF), size: 20),
              SizedBox(width: 8),
              Text(
                'Datos Extraídos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...fields.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBanxicoCard(Map<String, dynamic> banxico) {
    final status = banxico['status']?.toString() ?? 'unknown';
    final isSuccess = status == 'success';
    final message = banxico['message']?.toString() ?? '';
    final estadoPago = banxico['estado_pago']?.toString() ?? '';
    final fechaRecepcion = banxico['fecha_recepcion']?.toString() ?? '';
    final fechaProcesamiento = banxico['fecha_procesamiento']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? const Color(0xFF00E676).withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.account_balance_rounded : Icons.warning_amber_rounded,
                color: isSuccess ? const Color(0xFF00E676) : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Validación Banxico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                message,
                style: TextStyle(
                  color: isSuccess ? const Color(0xFF00E676) : Colors.orange.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (estadoPago.isNotEmpty)
            _buildBanxicoRow('Estado del Pago', estadoPago),
          if (fechaRecepcion.isNotEmpty)
            _buildBanxicoRow('Recepción', fechaRecepcion),
          if (fechaProcesamiento.isNotEmpty)
            _buildBanxicoRow('Procesamiento', fechaProcesamiento),
        ],
      ),
    );
  }

  Widget _buildBanxicoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
