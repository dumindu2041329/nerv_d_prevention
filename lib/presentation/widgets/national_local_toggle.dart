import 'package:flutter/material.dart';

/// Simple "Island-wide / Local" toggle pill.
/// Used on Home, Timeline, and Weather screens.
class NationalLocalToggle extends StatelessWidget {
  final bool isNational;
  final ValueChanged<bool>? onChanged;

  const NationalLocalToggle({
    super.key,
    this.isNational = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.18);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(context, 'Island-wide', isNational, true,
                  () => onChanged?.call(true)),
              _segment(context, 'Local', !isNational, false,
                  () => onChanged?.call(false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    bool isSelected,
    bool isLeft,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary.withValues(alpha: 0.18);
    final selectedTextColor = theme.colorScheme.primary;
    final unselectedTextColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(24) : Radius.zero,
            bottomLeft: isLeft ? const Radius.circular(24) : Radius.zero,
            topRight: isLeft ? Radius.zero : const Radius.circular(24),
            bottomRight: isLeft ? Radius.zero : const Radius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
