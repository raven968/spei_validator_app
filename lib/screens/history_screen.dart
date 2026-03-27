import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

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
        title: const Text('Historial',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: historyAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00E676))),
        error: (e, _) => _buildError(
          ref,
          e.toString().replaceFirst('Exception: ', ''),
        ),
        data: (validations) => validations.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(historyProvider),
                color: const Color(0xFF00E676),
                backgroundColor: const Color(0xFF1B2838),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: validations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ValidationCard(data: validations[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2838),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                color: Colors.white24, size: 40),
          ),
          const SizedBox(height: 16),
          const Text('Sin validaciones aún',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Tus validaciones aparecerán aquí',
              style: TextStyle(color: Colors.white30, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade300, size: 40),
            const SizedBox(height: 14),
            Text(message,
                style: TextStyle(color: Colors.red.shade200, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(historyProvider),
              child: const Text('Reintentar',
                  style: TextStyle(color: Color(0xFF00E676))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ValidationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isValid = data['is_valid_format'] == true;
    final extracted = data['extracted_data'] as Map<String, dynamic>?;
    final banxico = data['banxico_status'] as Map<String, dynamic>?;
    final fecha = data['fecha_operacion']?.toString() ?? '';
    final createdAt = data['created_at']?.toString().split('T').first ?? '';

    final monto = extracted?['monto']?.toString();
    final claveRastreo = extracted?['clave_rastreo']?.toString();
    final bancoEmisor = extracted?['banco_emisor']?.toString();
    final bancoReceptor = extracted?['banco_receptor']?.toString();
    final banxicoStatus = banxico?['status']?.toString();

    // Verde: encontrado, Rojo: no encontrado, Amarillo: en proceso/sin datos
    final Color banxicoColor;
    final String banxicoLabel;
    if (banxicoStatus == 'success') {
      banxicoColor = const Color(0xFF00E676);
      banxicoLabel = 'Banxico OK';
    } else if (banxicoStatus == 'error') {
      banxicoColor = Colors.red.shade400;
      banxicoLabel = 'No encontrado';
    } else {
      banxicoColor = Colors.amber;
      banxicoLabel = 'En proceso';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? const Color(0xFF00E676).withValues(alpha: 0.25)
              : Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isValid ? const Color(0xFF00E676) : Colors.red)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isValid ? Icons.check_rounded : Icons.close_rounded,
                  color: isValid
                      ? const Color(0xFF00E676)
                      : Colors.red.shade300,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isValid ? 'Formato válido' : 'Formato inválido',
                  style: TextStyle(
                    color: isValid
                        ? const Color(0xFF00E676)
                        : Colors.red.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (banxico != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: banxicoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    banxicoLabel,
                    style: TextStyle(
                      color: banxicoColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (monto != null) _buildRow('Monto', '\$$monto'),
          if (claveRastreo != null)
            _buildRow('Clave rastreo', claveRastreo),
          if (bancoEmisor != null) _buildRow('Emisor', bancoEmisor),
          if (bancoReceptor != null)
            _buildRow('Receptor', bancoReceptor),
          if (fecha.isNotEmpty) _buildRow('Fecha op.', fecha),
          const SizedBox(height: 8),
          Text('Validado el $createdAt',
              style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
