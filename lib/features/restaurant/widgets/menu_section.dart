import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/menu_item.dart';
import 'menu_item_card.dart';

class MenuSection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;
  final void Function(MenuItem) onAdd;

  const MenuSection({
    super.key,
    required this.title,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headlineMedium),
            ],
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: MenuItemCard(item: item, onAdd: () => onAdd(item)),
          ),
        ),
      ],
    );
  }
}
