import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LocationSelectorCard extends StatelessWidget {
  const LocationSelectorCard({
    super.key,
    required this.locations,
    required this.fromLocation,
    required this.toLocation,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onTrackPressed,
    this.onStopPressed,
    this.isTracking = false,
    this.onSwapPressed,
  });

  final List<String> locations;
  final String? fromLocation;
  final String? toLocation;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final VoidCallback onTrackPressed;
  final VoidCallback? onStopPressed;
  final bool isTracking;
  final VoidCallback? onSwapPressed;

  @override
  Widget build(BuildContext context) {
    final canTrack =
        fromLocation != null && toLocation != null && fromLocation != toLocation;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.blue700, AppColors.blue500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan your trip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Track your bus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                _LocationField(
                  label: 'From',
                  hint: 'Pick departure',
                  value: fromLocation,
                  accent: AppColors.success,
                  icon: Icons.trip_origin_rounded,
                  locations: locations,
                  onChanged: onFromChanged,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Material(
                    color: AppColors.blue50,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onSwapPressed,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: onSwapPressed != null ? AppColors.blue600 : AppColors.gray400,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _LocationField(
                  label: 'To',
                  hint: 'Pick destination',
                  value: toLocation,
                  accent: AppColors.blue600,
                  icon: Icons.location_on_rounded,
                  locations: locations,
                  onChanged: onToChanged,
                ),
                const SizedBox(height: 18),
                if (isTracking)
                  _TripActionButton(
                    label: 'Stop',
                    icon: Icons.stop_rounded,
                    gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
                    shadowColor: const Color(0xFFDC2626),
                    onPressed: onStopPressed,
                  )
                else
                  _TripActionButton(
                    label: 'Track Bus',
                    icon: Icons.radar_rounded,
                    gradientColors: canTrack
                        ? const [AppColors.blue700, AppColors.blue500]
                        : null,
                    shadowColor: AppColors.blue600,
                    enabled: canTrack,
                    onPressed: canTrack ? onTrackPressed : null,
                  ),
                if (isTracking) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Live updates are active. Stop when you are done following this trip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ] else if (!canTrack) ...[
                  const SizedBox(height: 10),
                  Text(
                    fromLocation == null || toLocation == null
                        ? 'Select both locations to start live tracking.'
                        : 'Choose different departure and destination.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gray500,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripActionButton extends StatelessWidget {
  const _TripActionButton({
    required this.label,
    required this.icon,
    required this.shadowColor,
    this.gradientColors,
    this.enabled = true,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color>? gradientColors;
  final Color shadowColor;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: active && gradientColors != null
            ? LinearGradient(colors: gradientColors!)
            : null,
        color: active ? null : AppColors.gray200,
        boxShadow: active
            ? [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active ? onPressed : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : AppColors.gray500,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.gray500,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.value,
    required this.accent,
    required this.icon,
    required this.locations,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
  final Color accent;
  final IconData icon;
  final List<String> locations;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 2),
            child: Icon(icon, color: accent, size: 20),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: DropdownButtonFormField<String>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  labelStyle: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                icon: Icon(Icons.expand_more_rounded, color: accent),
                items: locations
                    .map(
                      (location) => DropdownMenuItem(
                        value: location,
                        child: Text(
                          location,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
