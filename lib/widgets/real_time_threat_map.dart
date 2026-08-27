import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/websocket_service.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../services/navigation_service.dart';
import '../widgets/live_camera_feed.dart';

class RealTimeThreatMap extends StatefulWidget {
  const RealTimeThreatMap({super.key});

  @override
  State<RealTimeThreatMap> createState() => _RealTimeThreatMapState();
}

class _RealTimeThreatMapState extends State<RealTimeThreatMap> {
  bool _isCameraExpanded = false;
  bool _showRoutePanel = false;
  bool _autonomousActive = false;

  double _remainingDistance = 0;
  double _currentSpeed = 0;
  int _remainingEtaSeconds = 0;

  final NavigationService _navService = Get.find<NavigationService>();
  final WebSocketService _wsService = Get.find<WebSocketService>();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _roverIcon;

  Map<String, dynamic>? _pendingRouteData;
  LatLng? _pendingDestination;

  List<LatLng> _fullRoutePoints = [];
  List<LatLng> _progressRoutePoints = [];

  @override
  void initState() {
    super.initState();

    _autonomousActive = false;
    _showRoutePanel = false;

    _loadCustomMarkers();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ================= MAP TAP =================

  Future<void> _handleMapTap(LatLng destination) async {
    if (_autonomousActive) return;

    final routeData = await _navService.validateRoute(
      _wsService.latitude.value,
      _wsService.longitude.value,
      destination.latitude,
      destination.longitude,
    );

    if (routeData == null) {
      Get.snackbar("Navigation Error", "It is impossible to reach there.");
      return;
    }

    final polylinePoints = _navService.decodePolyline(routeData["polyline"]);

    setState(() {
      _fullRoutePoints = polylinePoints;
      _progressRoutePoints = [];
      _pendingRouteData = routeData;
      _pendingDestination = destination;
      _showRoutePanel = true;
      _drawRoutes();
    });
  }

  void _startAutonomous() {
    if (_pendingDestination == null || _pendingRouteData == null) return;

    _wsService.socket.emit("autonomous_start", {
      "destination": {
        "lat": _pendingDestination!.latitude,
        "lng": _pendingDestination!.longitude,
      },
      "distance": _pendingRouteData!["distanceValue"],
      "eta_seconds": _pendingRouteData!["durationValue"],
    });

    setState(() {
      _autonomousActive = true;
      _showRoutePanel = false;
    });
  }

  void _cancelAutonomous() {
    _wsService.socket.emit("autonomous_cancel");

    setState(() {
      _autonomousActive = false;
      _polylines.clear();
      _fullRoutePoints.clear();
      _progressRoutePoints.clear();
    });
  }

  // ================= ROUTES =================

  void _drawRoutes() {
    _polylines.removeWhere((p) => p.polylineId.value.contains("route"));

    if (_fullRoutePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_full'),
          points: _fullRoutePoints,
          color: const Color(0xFF662222),
          width: 6,
        ),
      );
    }

    if (_progressRoutePoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_progress'),
          points: _progressRoutePoints,
          color: const Color(0xFFFF3366),
          width: 8,
        ),
      );
    }
  }

  // ================= TRACKING =================

  void _startLocationTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) {
      _wsService.latitude.value = position.latitude;
      _wsService.longitude.value = position.longitude;

      _currentSpeed = position.speed * 3.6;

      _updateRouteProgress(position.latitude, position.longitude);
      _updateMarkers();
    });
  }

  void _updateRouteProgress(double lat, double lng) {
    if (!_autonomousActive || _fullRoutePoints.isEmpty) return;

    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _fullRoutePoints.length; i++) {
      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        _fullRoutePoints[i].latitude,
        _fullRoutePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    double remaining = 0;

    for (int i = closestIndex; i < _fullRoutePoints.length - 1; i++) {
      remaining += Geolocator.distanceBetween(
        _fullRoutePoints[i].latitude,
        _fullRoutePoints[i].longitude,
        _fullRoutePoints[i + 1].latitude,
        _fullRoutePoints[i + 1].longitude,
      );
    }

    _progressRoutePoints = _fullRoutePoints.sublist(0, closestIndex);

    _remainingDistance = remaining;

    if (_currentSpeed > 1) {
      _remainingEtaSeconds =
          (_remainingDistance / (_currentSpeed / 3.6)).toInt();
    }

    _drawRoutes();
    setState(() {});
  }

  // ================= MARKERS =================

  Future<void> _loadCustomMarkers() async {
    _roverIcon = await _createCustomMarker(
      Icons.precision_manufacturing,
      const Color(0xFF00F5FF),
      100,
    );
  }

  void _updateMarkers() {
    if (_roverIcon == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('rover'),
          position: LatLng(
            _wsService.latitude.value,
            _wsService.longitude.value,
          ),
          icon: _roverIcon!,
        ),
      };
    });
  }

  Future<BitmapDescriptor> _createCustomMarker(
      IconData icon, Color color, int size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

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
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (_autonomousActive && _isCameraExpanded) {
      return Stack(
        children: [
          const LiveCameraFeed(),
          _autonomousOverlay(),
        ],
      );
    }

    return Stack(
      children: [
        _buildFullMap(),
        if (_autonomousActive) _autonomousOverlay(),
        if (_showRoutePanel)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildRoutePanel(),
          ),
      ],
    );
  }

  Widget _autonomousOverlay() {
    return Stack(
      children: [
        Positioned(
          top: 30,
          left: 20,
          right: 20,
          child: _buildAutonomousBanner(),
        ),
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: _buildTelemetryHUD(),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          child: _buildCancelButton(),
        ),
      ],
    );
  }

  Widget _buildTelemetryHUD() {
    String distanceText = _remainingDistance >= 1000
        ? "${(_remainingDistance / 1000).toStringAsFixed(2)} km"
        : "${_remainingDistance.toStringAsFixed(0)} m";

    String etaText =
        _remainingEtaSeconds > 0 ? "${(_remainingEtaSeconds ~/ 60)} min" : "--";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3366)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hudItem("DISTANCE", distanceText),
          _hudItem("ETA", etaText),
          _hudItem("SPEED", "${_currentSpeed.toStringAsFixed(1)} km/h"),
        ],
      ),
    );
  }

  Widget _hudItem(String label, String value) {
    const TextStyle cancelFont = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400, // EXACT default weight
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: cancelFont),
        const SizedBox(height: 4),
        Text(value, style: cancelFont),
      ],
    );
  }

  Widget _buildAutonomousBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3366)),
      ),
      child: const Text(
        "AUTONOMOUS NAVIGATION IN PROGRESS...",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400, // match cancel exactly
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: _cancelAutonomous,
        child: const Text(
          "CANCEL",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFullMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_wsService.latitude.value, _wsService.longitude.value),
        zoom: 16,
      ),
      mapType: MapType.hybrid,
      markers: _markers,
      polylines: _polylines,
      zoomControlsEnabled: false,
      onMapCreated: (c) => _mapController = c,
      onTap: _handleMapTap,
    );
  }

  Widget _buildRoutePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF151B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Distance: ${_pendingRouteData!["distanceText"]}",
              style: const TextStyle(color: Colors.white)),
          Text("ETA: ${_pendingRouteData!["durationText"]}",
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _polylines.clear();
                      _fullRoutePoints.clear();
                      _progressRoutePoints.clear();
                      _showRoutePanel = false;
                    });
                  },
                  child: const Text("CANCEL"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _startAutonomous,
                  child: const Text("CONFIRM"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
