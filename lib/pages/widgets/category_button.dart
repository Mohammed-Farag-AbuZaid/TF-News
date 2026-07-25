import 'package:flutter/material.dart';
import 'package:tf_news/utils/constants/colors.dart';

class CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(
          isSelected ? TColors.primary : TColors.primary.withOpacity(0.08),
        ),
        foregroundColor: MaterialStatePropertyAll(
          isSelected ? Colors.white : TColors.primary,
        ),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? TColors.primary
                  : TColors.primary.withOpacity(0.2),
            ),
          ),
        ),
        padding: const MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: (label == 'Must-know')
            ? Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.red : Colors.red.withOpacity(0.8),
              )
            : Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : TColors.primary,
              ),
      ),
    );
  }
}