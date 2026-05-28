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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment('Island-wide', isNational, true, () => onChanged?.call(true)),
              _segment('Local', !isNational, false, () => onChanged?.call(false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(String label, bool isSelected, bool isLeft, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3F3F) : Colors.transparent,
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
            color: isSelected ? Colors.white : const Color(0xFF6A6A6A),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
