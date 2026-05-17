import 'package:flutter/material.dart';

/// Reusable "National / Local" toggle pill widget matching the official NERV app.
/// Used on Home, Timeline, and Weather screens.
class NationalLocalToggle extends StatelessWidget {
  final bool isNational;
  final ValueChanged<bool>? onChanged;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  const NationalLocalToggle({
    super.key,
    this.isNational = true,
    this.onChanged,
    this.showAddButton = true,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildTogglePill(context),
          const Spacer(),
          if (showAddButton)
            _buildAddButton(context),
        ],
      ),
    );
  }

  Widget _buildTogglePill(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF3A3A3A),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillSegment(
            context,
            label: 'National',
            isSelected: isNational,
            onTap: () => onChanged?.call(true),
            isLeft: true,
          ),
          _buildPillSegment(
            context,
            label: 'Local',
            isSelected: !isNational,
            onTap: () => onChanged?.call(false),
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPillSegment(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3F3F) : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(24) : Radius.zero,
            right: !isLeft ? const Radius.circular(24) : Radius.zero,
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

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
