import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/real_time_threat_map.dart';
import '../widgets/rover_status_card.dart';
import '../widgets/threat_alert_card.dart';
import '../widgets/system_stats.dart';
import '../widgets/live_camera_feed.dart';
import '../widgets/enhanced_telemetry_dashboard.dart';
import '../widgets/system_mode_selector.dart';
import '../widgets/camera_overlay.dart';
import '../screens/mission_log_screen.dart';
import '../screens/manual_control_screen.dart';
import '../services/websocket_service.dart';
import '../services/bluetooth_service.dart';
import '../services/connectivity_manager.dart';
import '../services/auth_service.dart';
import '../widgets/system_status_bar.dart';
import '../widgets/tactical_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final RoverBluetoothService _btService = Get.find<RoverBluetoothService>();
  final ConnectivityManager _connManager = Get.find<ConnectivityManager>();
  final AuthService _authService = Get.find<AuthService>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _wsService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0E17), Color(0xFF151B2B)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    TacticalBanner(), // 🔥 ADD THIS LINE
                    _buildHeader(),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),

          // 👇 THIS is the new status bar
          SystemStatusBar(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B).withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF3366).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              /// TITLE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SENTINEL',
                        style: GoogleFonts.orbitron(
                          fontSize: screenWidth * 0.065,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DEFENSE SYSTEM',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.025,
                          color: const Color(0xFF00F5FF),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.gamepad, color: Color(0xFFFF9500)),
                onPressed: () => Get.to(() => const ManualControlScreen()),
              ),

              IconButton(
                icon: const Icon(Icons.description, color: Color(0xFF00F5FF)),
                onPressed: () => Get.to(() => const MissionLogScreen()),
              ),

              /// Connectivity Manager Status
              Obx(() {
                final isConnected = _connManager.connectionStatus.value ==
                    ConnectionStatus.connected;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF00FF88).withOpacity(0.2)
                        : const Color(0xFFFF3366).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isConnected
                          ? const Color(0xFF00FF88)
                          : const Color(0xFFFF3366),
                    ),
                  ),
                  child: Text(
                    _connManager.connectionStatusText,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }),

              const SizedBox(width: 8),

              /// 🔥 WebSocket Status Badge (NEW)
              Obx(() {
                final status = _wsService.roverStatus.value;

                Color color;

                switch (status) {
                  case 'ACTIVE':
                    color = const Color(0xFF00FF88);
                    break;
                  case 'RECONNECTING':
                    color = const Color(0xFFFF9500);
                    break;
                  case 'OFFLINE':
                    color = const Color(0xFFFF3366);
                    break;
                  default:
                    color = Colors.grey;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 16),

          /// THREAT LEVEL BAR (UNCHANGED)
          Obx(() => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _wsService.threatLevel.value == 'CRITICAL'
                      ? const Color(0xFFFF3366).withOpacity(0.2)
                      : _wsService.threatLevel.value == 'HIGH'
                          ? const Color(0xFFFF9500).withOpacity(0.2)
                          : const Color(0xFF00FF88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _wsService.threatLevel.value == 'CRITICAL'
                        ? const Color(0xFFFF3366)
                        : _wsService.threatLevel.value == 'HIGH'
                            ? const Color(0xFFFF9500)
                            : const Color(0xFF00FF88),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _wsService.threatLevel.value == 'CRITICAL'
                          ? Icons.error_outline
                          : _wsService.threatLevel.value == 'HIGH'
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                      color: _wsService.threatLevel.value == 'CRITICAL'
                          ? const Color(0xFFFF3366)
                          : _wsService.threatLevel.value == 'HIGH'
                              ? const Color(0xFFFF9500)
                              : const Color(0xFF00FF88),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'THREAT LEVEL: ${_wsService.threatLevel.value}',
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _wsService.threatsDetected.value > 0
                                ? '${_wsService.threatsDetected.value} hostile drone(s) detected'
                                : 'All systems nominal',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildMapTab();
      case 2:
        return _buildAlertsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Mode Selector
          const SystemModeSelector(),
          const SizedBox(height: 24),

          // Connection mode selector
          _buildConnectionModeSelector(),
          const SizedBox(height: 24),

          Text(
            'LIVE CAMERA FEED',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const CameraOverlayWidget(cameraFeed: LiveCameraFeed()),
          const SizedBox(height: 24),

          Text(
            'TELEMETRY',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const EnhancedTelemetryDashboard(),
          const SizedBox(height: 24),

          Text(
            'ROVER STATUS',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const RoverStatusCard(),
          const SizedBox(height: 24),

          Text(
            'RECENT DETECTIONS',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => _wsService.recentThreats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _wsService.recentThreats.length,
                    itemBuilder: (context, index) {
                      final threat = _wsService.recentThreats[index];
                      return ThreatAlertCard(threat: threat);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return const RealTimeThreatMap();
  }

  Widget _buildAlertsTab() {
    return Obx(
      () => _wsService.recentThreats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _wsService.recentThreats.length,
              itemBuilder: (context, index) {
                final threat = _wsService.recentThreats[index];
                return ThreatAlertCard(threat: threat);
              },
            ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSettingItem(
          'Laser System',
          'Enable/disable primary weapon',
          true,
          Icons.flash_on,
        ),
        _buildSettingItem(
          'Auto-Alert Authorities',
          'Automatically notify emergency services',
          true,
          Icons.notifications_active,
        ),
        _buildSettingItem(
          'Threat Detection',
          'AI-powered drone detection',
          true,
          Icons.radar,
        ),
        _buildSettingItem(
          'Sound Alerts',
          'Audio warnings for threats',
          false,
          Icons.volume_up,
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3366).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFF3366)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {},
            activeThumbColor: const Color(0xFF00FF88),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: const Color(0xFF00FF88).withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'NO THREATS DETECTED',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All systems operational',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionModeSelector() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONNECTION MODE',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildConnectionButton(
                    'WEBSOCKET',
                    Icons.wifi,
                    _btService.connectionMode.value == 'websocket',
                    () => _btService.switchToWebSocket(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildConnectionButton(
                    'BLUETOOTH',
                    Icons.bluetooth,
                    _btService.connectionMode.value == 'bluetooth',
                    () => _btService.switchToBluetooth(),
                  ),
                ),
              ],
            ),
            if (_btService.connectionMode.value == 'bluetooth' &&
                _btService.availableDevices.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...(_btService.availableDevices.map(
                (device) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.router, color: Color(0xFF00F5FF)),
                  title: Text(
                    device.platformName.isEmpty
                        ? 'Unknown Device'
                        : device.platformName,
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _btService.connectToRover(device),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('CONNECT'),
                  ),
                ),
              )),
            ],
            if (_btService.connectionMode.value == 'bluetooth' &&
                !_btService.isConnected.value &&
                _btService.availableDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _btService.startScan,
                    icon: _btService.isScanning.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.radar),
                    label: Text(
                      _btService.isScanning.value
                          ? 'SCANNING...'
                          : 'SCAN FOR ROVERS',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F5FF).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F5FF)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00F5FF) : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF00F5FF) : Colors.white60,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFF3366).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFFFF3366),
        unselectedItemColor: Colors.white.withOpacity(0.4),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, letterSpacing: 1),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'OVERVIEW',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'MAP',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber),
            label: 'ALERTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
