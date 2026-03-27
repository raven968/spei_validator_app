import 'package:flutter/material.dart';
import '../models/validation_result.dart';

class ValidationResultCards extends StatelessWidget {
  final ValidationResult result;

  const ValidationResultCards({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusCard(result: result),
        if (result.isValidFormat && result.extractedData != null) ...[
          const SizedBox(height: 14),
          _ExtractedDataCard(data: result.extractedData!),
        ],
        if (result.banxicoStatus != null) ...[
          const SizedBox(height: 14),
          _BanxicoCard(banxico: result.banxicoStatus!),
        ],
      ],
    );
  }
}

class ValidationErrorCard extends StatelessWidget {
  final String message;

  const ValidationErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.red.shade700.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade300, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(color: Colors.red.shade200, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ── Status Card ──

class _StatusCard extends StatelessWidget {
  final ValidationResult result;
  const _StatusCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isValid = result.isValidFormat;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isValid
              ? [
                  const Color(0xFF00E676).withValues(alpha: 0.12),
                  const Color(0xFF00C853).withValues(alpha: 0.06),
                ]
              : [
                  Colors.red.withValues(alpha: 0.12),
                  Colors.red.withValues(alpha: 0.06),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? const Color(0xFF00E676).withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isValid ? const Color(0xFF00E676) : Colors.red)
                  .withValues(alpha: 0.15),
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
                    color: isValid
                        ? const Color(0xFF00E676)
                        : Colors.red.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isValid && result.issues.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...result.issues.map((issue) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• $issue',
                            style: TextStyle(
                                color: Colors.red.shade200, fontSize: 13)),
                      )),
                ],
                if (isValid)
                  const Text('La imagen fue verificada visualmente',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Extracted Data Card ──

class _ExtractedDataCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExtractedDataCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final fields = <MapEntry<String, String>>[
      MapEntry('Banco Emisor', data['banco_emisor']?.toString() ?? '—'),
      MapEntry('Banco Receptor', data['banco_receptor']?.toString() ?? '—'),
      MapEntry('Cuenta Beneficiaria',
          data['cuenta_beneficiaria']?.toString() ?? '—'),
      MapEntry('Monto', '\$${data['monto']?.toString() ?? '0.00'}'),
      MapEntry('Clave de Rastreo',
          data['clave_rastreo']?.toString() ?? '—'),
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
              Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF448AFF), size: 20),
              SizedBox(width: 8),
              Text('Datos Extraídos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...fields.map((entry) => _DataRow(
              label: entry.key, value: entry.value)),
        ],
      ),
    );
  }
}

// ── Banxico Card ──

class _BanxicoCard extends StatelessWidget {
  final Map<String, dynamic> banxico;
  const _BanxicoCard({required this.banxico});

  @override
  Widget build(BuildContext context) {
    final status = banxico['status']?.toString() ?? 'unknown';
    final message = banxico['message']?.toString() ?? '';
    final estadoPago = banxico['estado_pago']?.toString() ?? '';
    final fechaRecepcion = banxico['fecha_recepcion']?.toString() ?? '';
    final fechaProcesamiento =
        banxico['fecha_procesamiento']?.toString() ?? '';

    // Verde: encontrado, Rojo: no encontrado, Amarillo: en proceso/sin datos
    final Color statusColor;
    final IconData statusIcon;
    if (status == 'success') {
      statusColor = const Color(0xFF00E676);
      statusIcon = Icons.account_balance_rounded;
    } else if (status == 'error') {
      statusColor = Colors.red.shade400;
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.amber;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              const Text('Validación Banxico',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(message,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          if (estadoPago.isNotEmpty)
            _DataRow(label: 'Estado del Pago', value: estadoPago),
          if (fechaRecepcion.isNotEmpty)
            _DataRow(label: 'Recepción', value: fechaRecepcion),
          if (fechaProcesamiento.isNotEmpty)
            _DataRow(label: 'Procesamiento', value: fechaProcesamiento),
        ],
      ),
    );
  }
}

// ── Shared row widget ──

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
