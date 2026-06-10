import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Usuário', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
                      if (user?.phone.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(user!.phone, style: AppTextStyles.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionTitle('Conta'),
          _ListTile(
            icon: Icons.location_on_outlined,
            title: 'Meu endereço',
            subtitle: user?.address.isNotEmpty == true ? user!.address : 'Adicionar endereço',
          ),
          _ListTile(
            icon: Icons.credit_card_outlined,
            title: 'Formas de pagamento',
            subtitle: 'Cartão, PIX, Dinheiro',
          ),
          _ListTile(
            icon: Icons.receipt_long_outlined,
            title: 'Histórico de pedidos',
            onTap: () => context.go('/orders'),
          ),
          const SizedBox(height: 12),
          _SectionTitle('Preferências'),
          _ListTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Ativadas',
          ),
          _ListTile(
            icon: Icons.help_outline,
            title: 'Central de ajuda',
          ),
          _ListTile(
            icon: Icons.star_outline,
            title: 'Avaliar o app',
          ),
          const SizedBox(height: 12),
          _SectionTitle('Diagnóstico'),
          _ListTile(
            icon: Icons.bug_report_outlined,
            title: 'Testar captura de erro Sentry',
            subtitle: 'Apenas para demonstração',
            iconColor: AppColors.error,
            onTap: () async {
              SentryService.addBreadcrumb(
                'Erro de teste disparado manualmente',
                category: 'debug',
                data: {'user': user?.id},
              );
              try {
                throw Exception('Erro de teste do Sentry — disparado manualmente pelo usuário');
              } catch (e, st) {
                await SentryService.captureException(e, stackTrace: st, hint: 'manual test error');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro capturado e enviado ao Sentry!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text('Sair', style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('FoodRush v1.0.0', style: AppTextStyles.labelSmall),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(title, style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8, fontSize: 12)),
    );
  }
}

class _ListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _ListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.textLight)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
