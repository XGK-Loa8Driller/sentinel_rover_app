import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/websocket_service.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../services/system_status_service.dart';

class RealTimeThreatMap extends StatefulWidget {
  const RealTimeThreatMap({super.key});

  @override
  State<RealTimeThreatMap> createState() => _RealTimeThreatMapState();
}

class _RealTimeThreatMapState extends State<RealTimeThreatMap> {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};

  BitmapDescriptor? _roverIcon;
  BitmapDescriptor? _droneIconCritical;
  BitmapDescriptor? _droneIconHigh;
  BitmapDescriptor? _droneIconMedium;
  BitmapDescriptor? _droneIconLow;

  // Track rover path
  final List<LatLng> _roverPath = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _startLocationTracking();

    // Update markers when threats change
    ever(_wsService.recentThreats, (_) => _updateMarkers());
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Load custom marker icons
  Future<void> _loadCustomMarkers() async {
    _roverIcon = await _createCustomMarker(
      Icons.precision_manufacturing,
      const Color(0xFF00F5FF),
      100,
    );

    _droneIconCritical = await _createCustomMarker(
      Icons.warning,
      const Color(0xFFFF3366),
      80,
    );

    _droneIconHigh = await _createCustomMarker(
      Icons.warning_amber,
      const Color(0xFFFF9500),
      80,
    );

    _droneIconMedium = await _createCustomMarker(
      Icons.info_outline,
      const Color(0xFFFFCC00),
      80,
    );

    _droneIconLow = await _createCustomMarker(
      Icons.info,
      const Color(0xFF00FF88),
      80,
    );

    _updateMarkers();
  }

  // Create custom marker from icon
  Future<BitmapDescriptor> _createCustomMarker(
    IconData icon,
    Color color,
    int size,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    // Draw circle background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // Start tracking rover location
  void _startLocationTracking() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      final status = Get.find<SystemStatusService>();
      status.show(
        'Location permission required for maps',
        StatusType.warning,
      );

      return;
    }

    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      // Update rover position
      _wsService.latitude.value = position.latitude;
      _wsService.longitude.value = position.longitude;

      // Add to path
      _roverPath.add(LatLng(position.latitude, position.longitude));

      // Update markers and path
      _updateMarkers();
      _updateRoverPath();

      // Center map on rover (optional)
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    });
  }

  // Update all markers on the map
  void _updateMarkers() {
    if (_roverIcon == null) return;

    final newMarkers = <Marker>{};
    final newCircles = <Circle>{};

    // Add rover marker
    newMarkers.add(
      Marker(
        markerId: const MarkerId('rover'),
        position: LatLng(
          _wsService.latitude.value,
          _wsService.longitude.value,
        ),
        icon: _roverIcon!,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'SENTINEL ROVER',
          snippet: 'Status: ${_wsService.roverStatus.value}',
        ),
      ),
    );

    // Add detection radius circle around rover
    newCircles.add(
      Circle(
        circleId: const CircleId('detection_radius'),
        center: LatLng(
          _wsService.latitude.value,
          _wsService.longitude.value,
        ),
        radius: 500, // 500 meters detection radius
        fillColor: const Color(0xFF00F5FF).withOpacity(0.1),
        strokeColor: const Color(0xFF00F5FF),
        strokeWidth: 2,
      ),
    );

    // Add threat markers
    for (var threat in _wsService.recentThreats) {
      if (threat.neutralized) continue; // Don't show neutralized threats

      BitmapDescriptor? icon;
      Color circleColor;

      switch (threat.severity.toLowerCase()) {
        case 'critical':
          icon = _droneIconCritical;
          circleColor = const Color(0xFFFF3366);
          break;
        case 'high':
          icon = _droneIconHigh;
          circleColor = const Color(0xFFFF9500);
          break;
        case 'medium':
          icon = _droneIconMedium;
          circleColor = const Color(0xFFFFCC00);
          break;
        default:
          icon = _droneIconLow;
          circleColor = const Color(0xFF00FF88);
      }

      if (icon != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('threat_${threat.id}'),
            position: LatLng(threat.latitude, threat.longitude),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: 'HOSTILE DRONE',
              snippet:
                  'Severity: ${threat.severity.toUpperCase()}\nDistance: ${threat.distance.toStringAsFixed(0)}m',
            ),
          ),
        );

        // Add threat radius
        newCircles.add(
          Circle(
            circleId: CircleId('threat_circle_${threat.id}'),
            center: LatLng(threat.latitude, threat.longitude),
            radius: 50,
            fillColor: circleColor.withOpacity(0.2),
            strokeColor: circleColor,
            strokeWidth: 2,
          ),
        );
      }
    }

    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
    });
  }

  // Update rover path polyline
  void _updateRoverPath() {
    if (_roverPath.length < 2) return;

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('rover_path'),
          points: _roverPath,
          color: const Color(0xFF00F5FF).withOpacity(0.6),
          width: 3,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      };
    });
  }

  // Calculate total distance traveled
  double _calculateDistance() {
    if (_roverPath.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 0; i < _roverPath.length - 1; i++) {
      total += Geolocator.distanceBetween(
        _roverPath[i].latitude,
        _roverPath[i].longitude,
        _roverPath[i + 1].latitude,
        _roverPath[i + 1].longitude,
      );
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        Obx(() => GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _wsService.latitude.value,
                  _wsService.longitude.value,
                ),
                zoom: 16,
              ),
              mapType: MapType.hybrid,
              markers: _markers,
              circles: _circles,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )),

        // Map controls overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildMapControls(),
        ),

        // Distance traveled card
        Positioned(
          top: 20,
          left: 20,
          child: _buildDistanceCard(),
        ),

        // Threat counter
        Positioned(
          top: 20,
          right: 20,
          child: _buildThreatCounter(),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildControlButton(
            Icons.my_location,
            'Center',
            () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(
                    _wsService.latitude.value,
                    _wsService.longitude.value,
                  ),
                  16,
                ),
              );
            },
          ),
          _buildControlButton(
            Icons.layers,
            'Satellite',
            () {
              // Toggle map type
            },
          ),
          _buildControlButton(
            Icons.delete_outline,
            'Clear Path',
            () {
              setState(() {
                _roverPath.clear();
                _polylines.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00F5FF), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    final distance = _calculateDistance();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route,
                color: Color(0xFF00F5FF),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'DISTANCE',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            distance >= 1000
                ? '${(distance / 1000).toStringAsFixed(2)} km'
                : '${distance.toStringAsFixed(0)} m',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatCounter() {
    return Obx(() {
      final activeThreats =
          _wsService.recentThreats.where((t) => !t.neutralized).length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activeThreats > 0
              ? const Color(0xFFFF3366).withOpacity(0.95)
              : const Color(0xFF00FF88).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activeThreats > 0 ? Icons.warning : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'THREATS',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$activeThreats',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
