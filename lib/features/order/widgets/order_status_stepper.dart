import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/order.dart';

class OrderStatusStepper extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderStatusStepper({super.key, required this.currentStatus});

  static const _steps = [
    (OrderStatus.received, Icons.receipt_outlined, 'Recebido'),
    (OrderStatus.preparing, Icons.soup_kitchen_outlined, 'Preparando'),
    (OrderStatus.onTheWay, Icons.delivery_dining, 'A caminho'),
    (OrderStatus.delivered, Icons.check_circle_outline, 'Entregue'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = currentStatus.stepIndex;

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isComplete = i < current;
        final isActive = i == current;
        final isLast = i == _steps.length - 1;
        final color = isComplete || isActive ? AppColors.primary : AppColors.textLight;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete || isActive
                        ? AppColors.primary
                        : AppColors.divider,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isComplete ? Icons.check : step.$2,
                    color: isComplete || isActive ? AppColors.white : AppColors.textLight,
                    size: 22,
                  ),
                )
                    .animate(target: isActive ? 1 : 0)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 400.ms),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: isComplete ? AppColors.primary : AppColors.divider,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$3,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isActive)
                    Text(
                      'Em andamento...',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                    ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
