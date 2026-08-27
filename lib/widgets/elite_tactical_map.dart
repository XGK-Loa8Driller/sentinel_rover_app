import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../services/rover_state_controller.dart';
import 'dart:async';
import 'dart:ui' as ui;

/// L5 - ELITE TACTICAL MAP SYSTEM
/// Professional battlefield visualization with:
/// - Multi-layer system (GPS, Threats, Routes)
/// - Custom tactical markers
/// - Path history with fade
/// - Detection radius zones
/// - Timestamp overlays
/// - Threat aging system

enum MapLayer { gps, threats, routes, detectionZone, history }

class EliteTacticalMap extends StatefulWidget {
  const EliteTacticalMap({super.key});

  @override
  State<EliteTacticalMap> createState() => _EliteTacticalMapState();
}

class _EliteTacticalMapState extends State<EliteTacticalMap> {
  final RoverStateController _rover = Get.find<RoverStateController>();
  
  GoogleMapController? _mapController;
  
  // Map state
  final activeLayersvalue = <MapLayer>{
    MapLayer.gps,
    MapLayer.threats,
    MapLayer.detectionZone,
  }.obs;
  
  final followRover = true.obs;
  final mapType = MapType.hybrid.obs;
  
  // Custom markers
  BitmapDescriptor? _roverMarker;
  BitmapDescriptor? _threatCritical;
  BitmapDescriptor? _threatHigh;
  BitmapDescriptor? _threatMedium;
  BitmapDescriptor? _threatLow;
  BitmapDescriptor? _threatNeutralized;
  BitmapDescriptor? _waypointMarker;
  
  // Visual elements
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  
  Timer? _updateTimer;
  Timer? _threatAgingTimer;
  
  @override
  void onInit() {
    super.initState();
    _loadCustomMarkers();
    _startAutoUpdate();
    _startThreatAging();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _threatAgingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  // ============================================================================
  // CUSTOM MARKER CREATION
  // ============================================================================
  
  Future<void> _loadCustomMarkers() async {
    _roverMarker = await _createTacticalMarker(
      Icons.navigation,
      const Color(0xFF00F5FF),
      120,
      hasPulse: true,
    );
    
    _threatCritical = await _createThreatMarker(
      const Color(0xFFFF3366),
      100,
    );
    
    _threatHigh = await _createThreatMarker(
      const Color(0xFFFF9500),
      90,
    );
    
    _threatMedium = await _createThreatMarker(
      const Color(0xFFFFCC00),
      80,
    );
    
    _threatLow = await _createThreatMarker(
      const Color(0xFF00FF88),
      70,
    );
    
    _threatNeutralized = await _createNeutralizedMarker(60);
    
    _waypointMarker = await _createWaypointMarker(70);
    
    setState(() {}); // Trigger rebuild with markers loaded
  }
  
  Future<BitmapDescriptor> _createTacticalMarker(
    IconData icon,
    Color color,
    int size, {
    bool hasPulse = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Outer pulse circle
    if (hasPulse) {
      final pulsePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 1.5,
        pulsePaint,
      );
    }
    
    // Main circle
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      mainPaint,
    );
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );
    
    // Icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
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
  
  Future<BitmapDescriptor> _createThreatMarker(Color color, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Threat diamond shape
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size / 2, 0)
      ..lineTo(size, size / 2)
      ..lineTo(size / 2, size)
      ..lineTo(0, size / 2)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, borderPaint);
    
    // Warning icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.warning.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: Icons.warning.fontFamily,
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
  
  Future<BitmapDescriptor> _createNeutralizedMarker(int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Gray X marker
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawLine(
      Offset(size * 0.2, size * 0.2),
      Offset(size * 0.8, size * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size * 0.8, size * 0.2),
      Offset(size * 0.2, size * 0.8),
      paint,
    );
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
  
  Future<BitmapDescriptor> _createWaypointMarker(int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()
      ..color = const Color(0xFF00F5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Waypoint circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 3, paint);
    
    // Center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF00F5FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 10, dotPaint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
  
  // ============================================================================
  // AUTO-UPDATE SYSTEM
  // ============================================================================
  
  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        _updateMapElements();
      }
    });
  }
  
  void _startThreatAging() {
    _threatAgingTimer?.cancel();
    _threatAgingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _ageThreats();
      }
    });
  }
  
  void _ageThreats() {
    // Remove threats older than 30 seconds (unless neutralized)
    final now = DateTime.now();
    _rover.activeThreats.removeWhere((threat) {
      if (threat.neutralized) return false; // Keep neutralized for history
      final age = now.difference(threat.timestamp).inSeconds;
      return age > 30;
    });
  }
  
  // ============================================================================
  // MAP ELEMENT GENERATION
  // ============================================================================
  
  void _updateMapElements() {
    if (_roverMarker == null) return;
    
    final newMarkers = <Marker>{};
    final newCircles = <Circle>{};
    final newPolylines = <Polyline>{};
    
    // Layer 1: Rover marker
    if (activeLayers.contains(MapLayer.gps)) {
      newMarkers.add(_buildRoverMarker());
    }
    
    // Layer 2: Detection zone
    if (activeLayers.contains(MapLayer.detectionZone)) {
      newCircles.addAll(_buildDetectionZones());
    }
    
    // Layer 3: Threat markers
    if (activeLayers.contains(MapLayer.threats)) {
      newMarkers.addAll(_buildThreatMarkers());
      newCircles.addAll(_buildThreatCircles());
    }
    
    // Layer 4: Patrol route
    if (activeLayers.contains(MapLayer.routes)) {
      newMarkers.addAll(_buildWaypointMarkers());
      newPolylines.add(_buildPatrolRoute());
    }
    
    // Layer 5: Path history
    if (activeLayers.contains(MapLayer.history)) {
      newPolylines.add(_buildPathHistory());
    }
    
    setState(() {
      _markers = newMarkers;
      _circles = newCircles;
      _polylines = newPolylines;
    });
    
    // Follow rover if enabled
    if (followRover.value && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_rover.latitude.value, _rover.longitude.value),
        ),
      );
    }
  }
  
  Marker _buildRoverMarker() {
    return Marker(
      markerId: const MarkerId('rover'),
      position: LatLng(_rover.latitude.value, _rover.longitude.value),
      icon: _roverMarker!,
      rotation: _rover.heading.value,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(
        title: 'SENTINEL ROVER',
        snippet: 'Mode: ${_rover.roverMode.value.name.toUpperCase()}\n'
                'Speed: ${_rover.speed.value.toStringAsFixed(1)} m/s\n'
                'Battery: ${_rover.batteryLevel.value.toStringAsFixed(0)}%',
      ),
    );
  }
  
  List<Circle> _buildDetectionZones() {
    return [
      // Inner detection zone (500m)
      Circle(
        circleId: const CircleId('detection_zone'),
        center: LatLng(_rover.latitude.value, _rover.longitude.value),
        radius: 500,
        fillColor: const Color(0xFF00F5FF).withOpacity(0.1),
        strokeColor: const Color(0xFF00F5FF),
        strokeWidth: 2,
      ),
      // Outer warning zone (1000m)
      Circle(
        circleId: const CircleId('warning_zone'),
        center: LatLng(_rover.latitude.value, _rover.longitude.value),
        radius: 1000,
        fillColor: const Color(0xFFFF9500).withOpacity(0.05),
        strokeColor: const Color(0xFFFF9500).withOpacity(0.5),
        strokeWidth: 1,
      ),
    ];
  }
  
  Set<Marker> _buildThreatMarkers() {
    final markers = <Marker>{};
    
    for (var threat in _rover.activeThreats) {
      BitmapDescriptor? icon;
      
      if (threat.neutralized) {
        icon = _threatNeutralized;
      } else {
        switch (threat.severity.toLowerCase()) {
          case 'critical':
            icon = _threatCritical;
            break;
          case 'high':
            icon = _threatHigh;
            break;
          case 'medium':
            icon = _threatMedium;
            break;
          default:
            icon = _threatLow;
        }
      }
      
      if (icon != null) {
        final age = DateTime.now().difference(threat.timestamp).inSeconds;
        
        markers.add(
          Marker(
            markerId: MarkerId('threat_${threat.id}'),
            position: LatLng(threat.latitude, threat.longitude),
            icon: icon,
            alpha: threat.neutralized ? 0.5 : (1.0 - (age / 60).clamp(0.0, 0.5)),
            infoWindow: InfoWindow(
              title: threat.neutralized ? '✓ NEUTRALIZED' : '⚠️ HOSTILE DRONE',
              snippet: 'Severity: ${threat.severity.toUpperCase()}\n'
                      'Distance: ${threat.distance.toStringAsFixed(0)}m\n'
                      'Age: ${age}s',
            ),
          ),
        );
      }
    }
    
    return markers;
  }
  
  Set<Circle> _buildThreatCircles() {
    final circles = <Circle>{};
    
    for (var threat in _rover.activeThreats) {
      if (threat.neutralized) continue;
      
      Color color;
      switch (threat.severity.toLowerCase()) {
        case 'critical':
          color = const Color(0xFFFF3366);
          break;
        case 'high':
          color = const Color(0xFFFF9500);
          break;
        case 'medium':
          color = const Color(0xFFFFCC00);
          break;
        default:
          color = const Color(0xFF00FF88);
      }
      
      circles.add(
        Circle(
          circleId: CircleId('threat_circle_${threat.id}'),
          center: LatLng(threat.latitude, threat.longitude),
          radius: 50,
          fillColor: color.withOpacity(0.2),
          strokeColor: color,
          strokeWidth: 2,
        ),
      );
    }
    
    return circles;
  }
  
  Set<Marker> _buildWaypointMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _rover.patrolWaypoints.length; i++) {
      final wp = _rover.patrolWaypoints[i];
      markers.add(
        Marker(
          markerId: MarkerId('waypoint_$i'),
          position: LatLng(wp.latitude, wp.longitude),
          icon: _waypointMarker!,
          infoWindow: InfoWindow(
            title: 'WAYPOINT ${i + 1}',
          ),
        ),
      );
    }
    
    return markers;
  }
  
  Polyline _buildPatrolRoute() {
    if (_rover.patrolWaypoints.length < 2) {
      return Polyline(polylineId: const PolylineId('patrol_route'));
    }
    
    return Polyline(
      polylineId: const PolylineId('patrol_route'),
      points: _rover.patrolWaypoints
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(),
      color: const Color(0xFF00F5FF),
      width: 3,
      patterns: [PatternItem.dash(15), PatternItem.gap(10)],
    );
  }
  
  Polyline _buildPathHistory() {
    if (_rover.pathHistory.length < 2) {
      return Polyline(polylineId: const PolylineId('path_history'));
    }
    
    return Polyline(
      polylineId: const PolylineId('path_history'),
      points: _rover.pathHistory
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList(),
      color: const Color(0xFF00F5FF).withOpacity(0.6),
      width: 2,
      patterns: [PatternItem.dot],
    );
  }
  
  // ============================================================================
  // UI BUILD
  // ============================================================================
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        Obx(() => GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_rover.latitude.value, _rover.longitude.value),
            zoom: 16,
          ),
          mapType: mapType.value,
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
        _buildMapControls(),
        
        // Layer selector
        _buildLayerSelector(),
        
        // Stats overlay
        _buildStatsOverlay(),
      ],
    );
  }
  
  Widget _buildMapControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          _buildControlButton(
            Icons.my_location,
            followRover.value,
            () => followRover.value = !followRover.value,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            Icons.layers,
            false,
            () {
              mapType.value = mapType.value == MapType.hybrid
                  ? MapType.normal
                  : MapType.hybrid;
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            Icons.delete_outline,
            false,
            () => _rover.clearPath(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF00F5FF).withOpacity(0.3)
              : const Color(0xFF151B2B).withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? const Color(0xFF00F5FF)
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF00F5FF) : Colors.white70,
        ),
      ),
    );
  }
  
  Widget _buildLayerSelector() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2B).withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAYERS',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildLayerToggle('Threats', MapLayer.threats),
            _buildLayerToggle('Routes', MapLayer.routes),
            _buildLayerToggle('History', MapLayer.history),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLayerToggle(String label, MapLayer layer) {
    return Obx(() {
      final isActive = activeLayers.contains(layer);
      return InkWell(
        onTap: () {
          if (isActive) {
            activeLayers.remove(layer);
          } else {
            activeLayers.add(layer);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check_box : Icons.check_box_outline_blank,
                size: 16,
                color: isActive ? const Color(0xFF00F5FF) : Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildStatsOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2B).withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('DISTANCE', '${(_rover.distanceTraveled.value / 1000).toStringAsFixed(2)} km'),
            _buildStatRow('THREATS', '${_rover.activeThreats.length}'),
            _buildStatRow('MODE', _rover.roverMode.value.name.toUpperCase()),
          ],
        )),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.orbitron(
              fontSize: 10,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00F5FF),
            ),
          ),
        ],
      ),
    );
  }
}
