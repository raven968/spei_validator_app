import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E676), Color(0xFF00C853)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.verified_user_rounded,
              color: Color(0xFF0D1B2A), size: 26),
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
        const _AppMenu(),
      ],
    );
  }
}

class _AppMenu extends ConsumerWidget {
  const _AppMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final name = user?.name ?? 'Usuario';
    final email = user?.email ?? '';

    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded, color: Colors.white70, size: 24),
      color: const Color(0xFF1B2838),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 48),
      onSelected: (value) => _onSelected(context, ref, value),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _UserAvatar(name: name),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    if (email.isNotEmpty)
                      Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text('Mi perfil',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'subscription',
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF00E676), size: 20),
              SizedBox(width: 12),
              Text('Mi subscripción',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'history',
          child: Row(
            children: [
              Icon(Icons.history_rounded,
                  color: Color(0xFF448AFF), size: 20),
              SizedBox(width: 12),
              Text('Historial',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.white38, size: 20),
              SizedBox(width: 12),
              Text('Cerrar sesión',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onSelected(
      BuildContext context, WidgetRef ref, String value) async {
    switch (value) {
      case 'profile':
        context.push('/profile');
      case 'subscription':
        context.push('/subscription?fromHome=true');
      case 'history':
        context.push('/history');
      case 'logout':
        await ref.read(authProvider.notifier).logout();
        // GoRouter redirect handles navigation
    }
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 14,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
