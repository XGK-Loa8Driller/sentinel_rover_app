import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/websocket_service.dart';

class TacticalBanner extends StatelessWidget {
  TacticalBanner({super.key});

  final WebSocketService _ws = Get.find<WebSocketService>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_ws.showBanner.value) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: _ws.bannerColor.value.withOpacity(0.9),
        child: Center(
          child: Text(
            _ws.bannerMessage.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    });
  }
}
