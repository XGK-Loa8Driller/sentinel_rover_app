import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/system_status_service.dart';

class SystemStatusBar extends StatelessWidget {
  SystemStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final statusService = Get.find<SystemStatusService>();

    return Obx(() {
      if (statusService.message.value.isEmpty) {
        return const SizedBox();
      }

      Color bgColor;

      switch (statusService.type.value) {
        case StatusType.success:
          bgColor = const Color(0xFF00FF88);
          break;
        case StatusType.error:
          bgColor = const Color(0xFFFF3366);
          break;
        case StatusType.info:
        default:
          bgColor = const Color(0xFF00F5FF);
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.15),
          border: Border(
            top: BorderSide(color: bgColor, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: bgColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                statusService.message.value,
                style: TextStyle(
                  color: bgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
