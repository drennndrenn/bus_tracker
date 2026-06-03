import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/location_map_data.dart';
import '../../data/osrm_route_service.dart';

class MapPanel extends StatefulWidget {
  const MapPanel({
    super.key,
    required this.from,
    required this.to,
    required this.isTracking,
    required this.progress,
    required this.statusLabel,
  });

  final String? from;
  final String? to;
  final bool isTracking;
  final double progress;
  final String statusLabel;

  @override
  State<MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<MapPanel> {
  static const _minZoom = 8.0;
  static const _maxZoom = 16.0;
  static const _zoomStep = 0.75;

  final _mapController = MapController();
  final _routeService = const OsrmRouteService();
  List<LatLng> _fetchedRoute = const [];
  bool _isLoadingRoute = false;
  String? _lastRouteKey;

  /// Incremented whenever a new OSRM fetch is started or route is cleared.
  /// Results from older serials are ignored so stale responses cannot overwrite the map.
  int _routeFetchSerial = 0;

  @override
  void initState() {
    super.initState();
    _tryFetchRoute();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.isTracking != widget.isTracking) {
      _tryFetchRoute();
    }
    if (oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.isTracking != widget.isTracking) {
      _recenterMap();
    }
  }

  void _recenterMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasRoute = widget.isTracking &&
          widget.from != null &&
          widget.to != null &&
          widget.from != widget.to;
      final center = hasRoute
          ? _routeCenter(
              _fetchedRoute.isNotEmpty
                  ? _fetchedRoute
                  : _buildSimulatedRoutePoints(widget.from!, widget.to!),
            )
          : const LatLng(7.495, 125.67);
      final zoom = hasRoute ? 10.65 : 10.15;
      _mapController.move(center, zoom);
    });
  }

  void _zoomIn() => _zoomBy(_zoomStep);

  void _zoomOut() => _zoomBy(-_zoomStep);

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom);
    _mapController.move(camera.center, nextZoom);
  }

  Future<void> _tryFetchRoute() async {
    final from = widget.from;
    final to = widget.to;
    final hasRoute = widget.isTracking && from != null && to != null && from != to;
    if (!hasRoute) {
      _routeFetchSerial++;
      if (!mounted) return;
      setState(() {
        _fetchedRoute = const [];
        _isLoadingRoute = false;
        _lastRouteKey = null;
      });
      return;
    }

    final routeKey = '$from->$to';
    if (_lastRouteKey == routeKey && _fetchedRoute.isNotEmpty) return;

    final serial = ++_routeFetchSerial;
    setState(() {
      _isLoadingRoute = true;
      _lastRouteKey = routeKey;
    });

    try {
      final route = await _routeService.fetchRoute(fromLocation: from, toLocation: to);
      if (!mounted || serial != _routeFetchSerial) return;
      setState(() {
        _fetchedRoute = route;
        _isLoadingRoute = false;
      });
      _recenterMap();
    } catch (_) {
      if (!mounted || serial != _routeFetchSerial) return;
      setState(() {
        _fetchedRoute = const [];
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute =
        widget.isTracking && widget.from != null && widget.to != null && widget.from != widget.to;
    final routePoints = hasRoute
        ? (_fetchedRoute.isNotEmpty ? _fetchedRoute : _buildSimulatedRoutePoints(widget.from!, widget.to!))
        : <LatLng>[];
    final routeStops = hasRoute ? _buildRouteStops(routePoints) : <LatLng>[];
    final busPoint = hasRoute ? _busPoint(routePoints, widget.progress) : null;
    final center = hasRoute ? _routeCenter(routePoints) : const LatLng(7.495, 125.67);
    final roadPolylines = _roadPolylines();

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFDBEAFE),
              Color(0xFFEFF6FF),
              Color(0xFFECFDF5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
                Positioned.fill(
                  child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: hasRoute ? 10.65 : 10.15,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartbus.tracker',
                        ),
                        PolylineLayer(polylines: roadPolylines),
                        if (hasRoute)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4,
                                color: AppColors.blue600,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: _locationMarkers(widget.from, widget.to),
                        ),
                        if (hasRoute)
                          MarkerLayer(
                            markers: [
                              for (final stop in routeStops) _stopMarker(stop),
                              if (busPoint != null) _busMarker(busPoint),
                            ],
                          ),
                      ],
                    ),
                ),
                if (!hasRoute) const _MapIdleOverlay(),
                Positioned(
                  right: 12,
                  top: 88,
                  child: _MapZoomControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                  ),
                ),
                if (hasRoute)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _MapChip(
                          icon: Icons.map_rounded,
                          label: 'Davao del Norte',
                        ),
                        const Spacer(),
                        if (_isLoadingRoute)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        else
                          _MapChip(
                            icon: Icons.route_rounded,
                            label: '${widget.from} → ${widget.to}',
                          ),
                      ],
                    ),
                  ),
                if (widget.isTracking)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 14,
                    child: _MapStatusFooter(
                      progress: widget.progress,
                      statusLabel: widget.statusLabel,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 3,
      shadowColor: AppColors.blue600.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add_rounded,
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
          ),
          Container(height: 1, width: 36, color: AppColors.gray100),
          _ZoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.blue700, size: 22),
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        shape: const RoundedRectangleBorder(),
      ),
    );
  }
}

class _MapIdleOverlay extends StatelessWidget {
  const _MapIdleOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.blue100),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.explore_rounded, color: AppColors.blue600, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ready to track',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose departure and destination above, then tap Track Bus to see the route here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.gray600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.blue600),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Polyline> _roadPolylines() {
  return roadSegments
      .map((segment) {
        final a = locationLatLng[segment[0]];
        final b = locationLatLng[segment[1]];
        if (a == null || b == null) return null;
        return Polyline(
          points: [LatLng(a.lat, a.lng), LatLng(b.lat, b.lng)],
          strokeWidth: 2,
          color: AppColors.gray400.withValues(alpha: 0.55),
        );
      })
      .whereType<Polyline>()
      .toList();
}

List<Marker> _locationMarkers(String? from, String? to) {
  return locationLatLng.entries.map((entry) {
    final isActive = entry.key == from || entry.key == to;
    final dotSize = isActive ? 18.0 : 14.0;
    final hit = dotSize + 8;
    return Marker(
      point: LatLng(entry.value.lat, entry.value.lng),
      width: hit,
      height: hit,
      alignment: Alignment.center,
      child: Tooltip(
        message: entry.key,
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: isActive ? AppColors.blue600 : AppColors.gray500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }).toList();
}

Marker _stopMarker(LatLng point) {
  return Marker(
    point: point,
    width: 20,
    height: 20,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0EA5E9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.stop_circle_rounded, size: 12, color: Color(0xFF0284C7)),
    ),
  );
}

Marker _busMarker(LatLng point) {
  return Marker(
    point: point,
    width: 30,
    height: 30,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue600, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.directions_bus_rounded, size: 16, color: AppColors.blue600),
    ),
  );
}

List<LatLng> _buildSimulatedRoutePoints(String from, String to) {
  final chain = routeChainGeoPoints(from, to);
  final names = routeChainLocationNames(from, to);
  if (chain.length < 2 || names.length != chain.length) return const [];

  const stepsPerLeg = 22;
  final out = <LatLng>[];

  for (var leg = 0; leg < chain.length - 1; leg++) {
    final straight = straightLegLatLngs(names[leg], names[leg + 1]);
    if (straight != null) {
      final startIdx = leg > 0 ? 1 : 0;
      for (var i = startIdx; i < straight.length; i++) {
        out.add(straight[i]);
      }
      continue;
    }

    final fromPoint = chain[leg];
    final toPoint = chain[leg + 1];
    final start = LatLng(fromPoint.lat, fromPoint.lng);
    final end = LatLng(toPoint.lat, toPoint.lng);
    final control = LatLng(
      ((start.latitude + end.latitude) / 2) + ((end.longitude - start.longitude) * 0.08),
      ((start.longitude + end.longitude) / 2) - ((end.latitude - start.latitude) * 0.08),
    );

    for (var k = 0; k <= stepsPerLeg; k++) {
      if (leg > 0 && k == 0) continue;
      final t = k / stepsPerLeg;
      final oneMinus = 1 - t;
      final lat = (oneMinus * oneMinus * start.latitude) +
          (2 * oneMinus * t * control.latitude) +
          (t * t * end.latitude);
      final lng = (oneMinus * oneMinus * start.longitude) +
          (2 * oneMinus * t * control.longitude) +
          (t * t * end.longitude);
      out.add(LatLng(lat, lng));
    }
  }
  return out;
}

LatLng _busPoint(List<LatLng> route, double progress) {
  if (route.isEmpty) return const LatLng(7.495, 125.67);
  final t = progress.clamp(0.02, 0.98);
  final idx = (t * (route.length - 1)).round();
  return route[idx];
}

List<LatLng> _buildRouteStops(List<LatLng> route) {
  if (route.length < 4) return const [];
  return [
    route[(route.length * 0.25).round()],
    route[(route.length * 0.5).round()],
    route[(route.length * 0.75).round()],
  ];
}

LatLng _routeCenter(List<LatLng> route) {
  if (route.isEmpty) return const LatLng(7.495, 125.67);
  final avgLat = route.map((p) => p.latitude).reduce((a, b) => a + b) / route.length;
  final avgLng = route.map((p) => p.longitude).reduce((a, b) => a + b) / route.length;
  return LatLng(avgLat, avgLng);
}

class _MapStatusFooter extends StatelessWidget {
  const _MapStatusFooter({
    required this.progress,
    required this.statusLabel,
  });

  final double progress;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue100),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue600.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Live • $statusLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray900,
                    ),
              ),
              const Spacer(),
              Text(
                '${(progress.clamp(0, 1) * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.blue100,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
