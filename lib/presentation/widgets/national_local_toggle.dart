import 'package:flutter/material.dart';
import 'nerv/nerv_styles.dart';

/// Island-wide / Local mode switch — styled as a two-segment console
/// control with a top accent tick on the active segment.
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
    final nerv = context.nerv;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: nerv.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: nerv.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              context,
              label: 'Island-wide',
              selected: isNational,
              accent: accent,
              onTap: () => onChanged?.call(true),
            ),
          ),
          Container(width: 1, height: 22, color: nerv.border),
          Expanded(
            child: _segment(
              context,
              label: 'Local',
              selected: !isNational,
              accent: accent,
              onTap: () => onChanged?.call(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final nerv = context.nerv;
    final idle = nerv.onSurface.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 2,
              width: 18,
              color: selected ? accent : Colors.transparent,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: selected ? accent : idle,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
