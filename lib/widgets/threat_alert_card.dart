import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/threat_model.dart';

class ThreatAlertCard extends StatelessWidget {
  final ThreatModel threat;

  const ThreatAlertCard({super.key, required this.threat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getThreatColor().withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getThreatColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getThreatColor(), width: 1),
                ),
                child: Text(
                  threat.severity.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getThreatColor(),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DRONE DETECTED',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Icon(
                threat.neutralized ? Icons.check_circle : Icons.error_outline,
                color: threat.neutralized
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF3366),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            'Location',
            '${threat.latitude.toStringAsFixed(4)}, ${threat.longitude.toStringAsFixed(4)}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.access_time,
            'Detected',
            _formatTime(threat.timestamp),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.speed,
            'Distance',
            '${threat.distance.toStringAsFixed(0)}m',
          ),
          const SizedBox(height: 12),
          _buildConfidenceBar(threat.confidence ?? 0.75),
          if (threat.alertsSent.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF00FF88),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alerts sent: ${threat.alertsSent.join(", ")}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00F5FF), size: 14),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getThreatColor() {
    switch (threat.severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF3366);
      case 'high':
        return const Color(0xFFFF9500);
      case 'medium':
        return const Color(0xFFFFCC00);
      default:
        return const Color(0xFF00FF88);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildConfidenceBar(double confidence) {
    final percentage = (confidence * 100).toStringAsFixed(0);

    Color barColor;

    if (confidence > 0.8) {
      barColor = const Color(0xFF00FF88); // Green
    } else if (confidence > 0.5) {
      barColor = const Color(0xFFFF9500); // Orange
    } else {
      barColor = const Color(0xFFFF3366); // Red
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI CONFIDENCE: $percentage%',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: barColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: confidence.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
