import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/fare_data.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _repository = CompanyFareRepository.instance;
  late Future<Map<String, List<FareItem>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, List<FareItem>>> _loadData() {
    return _repository
        .loadRoutes(forceRefresh: true)
        .then((_) => _repository.loadFareMatrix(forceRefresh: true))
        .then(_repository.normalizeForLocations);
  }

  Future<void> _refresh() async {
    _repository.clearCache();
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<FareItem>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.blue600),
            ),
          );
        }

        final fareData = snapshot.data ??
            _repository.normalizeForLocations(fallbackFareData);
        final usingFallback = _repository.usingFallback;
        final companyLabel = _repository.companyName ?? 'Bachelor Express';

        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.blue600,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore routes',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a municipality to view fares to nearby destinations.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray600,
                              height: 1.4,
                            ),
                      ),
                      if (usingFallback) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  size: 18, color: AppColors.warning),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Showing saved fares — connect to load live data from the server.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _RoutesSummaryStrip(
                        locationCount: AppConstants.locations.length,
                        companyName: companyLabel,
                        liveData: !usingFallback,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final location = AppConstants.locations[index];
                      final style = _locationStyle(index);
                      final routeCount =
                          _repository.destinationCountFor(location, fareData);

                      return _LocationRouteCard(
                        location: location,
                        style: style,
                        routeCount: routeCount,
                        onTap: () => _openFareSheet(
                          context,
                          location,
                          fareData[location] ?? const <FareItem>[],
                        ),
                      );
                    },
                    childCount: AppConstants.locations.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFareSheet(
    BuildContext context,
    String location,
    List<FareItem> fares,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteDetailsSheet(location: location, fares: fares),
    );
  }
}

class _RoutesSummaryStrip extends StatelessWidget {
  const _RoutesSummaryStrip({
    required this.locationCount,
    required this.companyName,
    required this.liveData,
  });

  final int locationCount;
  final String companyName;
  final bool liveData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue600, AppColors.blue400],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$locationCount municipalities • ${liveData ? 'live fares' : 'offline fares'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _LocationRouteCard extends StatelessWidget {
  const _LocationRouteCard({
    required this.location,
    required this.style,
    required this.routeCount,
    required this.onTap,
  });

  final String location;
  final _LocationStyle style;
  final int routeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: style.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: style.shadow.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Icon(
                  style.icon,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(style.icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_outlined,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$routeCount fares',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDetailsSheet extends StatelessWidget {
  const _RouteDetailsSheet({
    required this.location,
    required this.fares,
  });

  final String location;
  final List<FareItem> fares;

  @override
  Widget build(BuildContext context) {
    final index = AppConstants.locations.indexOf(location);
    final style = _locationStyle(index >= 0 ? index : 0);
    final minFare =
        fares.isEmpty ? 0 : fares.map((f) => f.fare).reduce((a, b) => a < b ? a : b);
    final maxFare =
        fares.isEmpty ? 0 : fares.map((f) => f.fare).reduce((a, b) => a > b ? a : b);

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _FareSheetHeader(
                location: location,
                style: style,
                destinationCount: fares.length,
                minFare: minFare,
                maxFare: maxFare,
              ),
              Expanded(
                child: fares.isEmpty
                    ? Center(
                        child: Text(
                          'No fares loaded for this location.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.gray500,
                              ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: fares.length,
                        itemBuilder: (context, index) {
                          final fare = fares[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FareRowCard(
                              origin: location,
                              fare: fare,
                              accent: style.accent,
                            ),
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

class _FareSheetHeader extends StatelessWidget {
  const _FareSheetHeader({
    required this.location,
    required this.style,
    required this.destinationCount,
    required this.minFare,
    required this.maxFare,
  });

  final String location;
  final _LocationStyle style;
  final int destinationCount;
  final int minFare;
  final int maxFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: style.shadow.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(style.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fare matrix',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStatChip(
                icon: Icons.route_rounded,
                label: '$destinationCount routes',
              ),
              const SizedBox(width: 8),
              _HeaderStatChip(
                icon: Icons.sell_outlined,
                label: 'PHP $minFare – $maxFare',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStatChip extends StatelessWidget {
  const _HeaderStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FareRowCard extends StatelessWidget {
  const _FareRowCard({
    required this.origin,
    required this.fare,
    required this.accent,
  });

  final String origin;
  final FareItem fare;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.location_on_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fare.destination,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.trip_origin, size: 12, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          origin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppColors.gray400),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '₱${fare.fare}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStyle {
  const _LocationStyle({
    required this.gradient,
    required this.shadow,
    required this.accent,
    required this.icon,
  });

  final List<Color> gradient;
  final Color shadow;
  final Color accent;
  final IconData icon;
}

_LocationStyle _locationStyle(int index) {
  const styles = <_LocationStyle>[
    _LocationStyle(
      gradient: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      shadow: AppColors.blue700,
      accent: AppColors.blue600,
      icon: Icons.location_city_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFF047857), Color(0xFF10B981)],
      shadow: Color(0xFF047857),
      accent: AppColors.success,
      icon: Icons.apartment_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFF0E7490), Color(0xFF06B6D4)],
      shadow: Color(0xFF0E7490),
      accent: Color(0xFF0891B2),
      icon: Icons.park_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
      shadow: Color(0xFF6D28D9),
      accent: Color(0xFF7C3AED),
      icon: Icons.church_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFFB45309), Color(0xFFF59E0B)],
      shadow: Color(0xFFB45309),
      accent: AppColors.warning,
      icon: Icons.forest_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFFBE185D), Color(0xFFEC4899)],
      shadow: Color(0xFFBE185D),
      accent: Color(0xFFDB2777),
      icon: Icons.agriculture_rounded,
    ),
    _LocationStyle(
      gradient: [Color(0xFF1E40AF), Color(0xFF6366F1)],
      shadow: Color(0xFF1E40AF),
      accent: Color(0xFF4F46E5),
      icon: Icons.home_work_rounded,
    ),
  ];
  return styles[index % styles.length];
}
