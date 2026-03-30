import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/app_input_decoration.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _success;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).valueOrNull;
    final newName = _nameController.text.trim();
    final newPassword = _passwordController.text;

    final nameChanged = newName != user?.name;
    final hasPassword = newPassword.isNotEmpty;

    if (!nameChanged && !hasPassword) {
      setState(() => _error = 'No hay cambios por guardar');
      return;
    }

    setState(() {
      _error = null;
      _success = null;
    });

    await ref.read(profileProvider.notifier).updateProfile(
          name: nameChanged ? newName : null,
          password: hasPassword ? newPassword : null,
        );

    final profileState = ref.read(profileProvider);
    if (profileState.hasError) {
      setState(() {
        _error =
            profileState.error.toString().replaceFirst('Exception: ', '');
      });
    } else {
      setState(() {
        _success = 'Perfil actualizado';
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final isSaving = profileAsync.isLoading && _initialized;

    // Initialize name controller when data loads
    profileAsync.whenData((user) {
      if (!_initialized && user != null) {
        _nameController.text = user.name;
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mi perfil',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: profileAsync.isLoading && !_initialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 28,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        ref.watch(authProvider).valueOrNull?.email ?? '',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const _FieldLabel('Nombre'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      decoration: appInputDecoration(
                        hintText: 'Tu nombre',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    const _FieldLabel('Nueva contraseña'),
                    const SizedBox(height: 4),
                    const Text('Déjalo vacío si no deseas cambiarla',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      decoration: appInputDecoration(
                        hintText: 'Nueva contraseña',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty && v.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      decoration: appInputDecoration(
                        hintText: 'Confirmar contraseña',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (_passwordController.text.isNotEmpty &&
                            v != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      _MessageCard(message: _error!, isError: true),
                      const SizedBox(height: 16),
                    ],
                    if (_success != null) ...[
                      _MessageCard(message: _success!, isError: false),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: const Color(0xFF0D1B2A),
                          disabledBackgroundColor: const Color(0xFF00E676)
                              .withValues(alpha: 0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0D1B2A),
                                    strokeWidth: 2.5))
                            : const Text('Guardar cambios'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
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
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;
  const _MessageCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.shade900.withValues(alpha: 0.25)
            : const Color(0xFF00E676).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? Colors.red.shade700.withValues(alpha: 0.4)
              : const Color(0xFF00E676).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color:
                isError ? Colors.red.shade300 : const Color(0xFF00E676),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? Colors.red.shade200
                    : const Color(0xFF00E676),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
