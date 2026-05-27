import 'package:flutter/material.dart';
import '../../core/constants/app_sl_constants.dart';

/// Reusable "Island-wide / District" toggle pill widget for Sri Lanka.
/// Used on Home, Timeline, and Weather screens.
class NationalLocalToggle extends StatelessWidget {
  /// Whether the toggle shows Island-wide (true) or a specific District (false).
  final bool isNational;

  /// Called when the user switches between Island-wide and District mode.
  /// Receives true for Island-wide, false when a district is selected.
  final ValueChanged<bool>? onChanged;

  /// The currently selected district when [isNational] is false.
  final SLDistrict? selectedDistrict;

  /// Called when the user selects a district from the picker.
  final ValueChanged<SLDistrict>? onDistrictSelected;

  /// Whether to show the add button that opens district selection.
  final bool showAddButton;

  const NationalLocalToggle({
    super.key,
    this.isNational = true,
    this.onChanged,
    this.selectedDistrict,
    this.onDistrictSelected,
    this.showAddButton = true,
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
          if (showAddButton) _buildDistrictButton(context),
        ],
      ),
    );
  }

  Widget _buildTogglePill(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPillSegment(
            context,
            label: 'Island-wide',
            isSelected: isNational,
            onTap: () => onChanged?.call(true),
            isLeft: true,
          ),
          _buildDistrictSegment(context),
        ],
      ),
    );
  }

  Widget _buildDistrictSegment(BuildContext context) {
    final isSelected = !isNational;
    final label = selectedDistrict?.displayName ?? 'District';

    return GestureDetector(
      onTap: () => _showDistrictPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3F3F) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6A6A6A),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3F3F) : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            bottomLeft: const Radius.circular(24),
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

  Widget _buildDistrictButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDistrictPicker(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF00BCD4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }

  void _showDistrictPicker(BuildContext context) {
    final districts = SLDistrict.alphabetical;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select District',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Divider(color: Color(0xFF2A2F3E), height: 1),
              // District list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: districts.length,
                  itemBuilder: (_, index) {
                    final district = districts[index];
                    final isSelectedDistrict =
                        selectedDistrict == district && !isNational;

                    return ListTile(
                      title: Text(
                        district.displayName,
                        style: TextStyle(
                          color: isSelectedDistrict
                              ? const Color(0xFFFF6B00)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: isSelectedDistrict
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        district.province,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelectedDistrict
                          ? const Icon(
                              Icons.check,
                              color: Color(0xFFFF6B00),
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onDistrictSelected?.call(district);
                        onChanged?.call(false);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
