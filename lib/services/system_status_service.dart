import 'package:get/get.dart';

enum StatusType {
  success,
  error,
  warning, // ← ADD THIS
  info,
}

class SystemStatusService extends GetxController {
  final message = ''.obs;
  final type = StatusType.info.obs;

  void show(String newMessage, StatusType newType) {
    message.value = newMessage;
    type.value = newType;

    // Auto clear after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (message.value == newMessage) {
        message.value = '';
      }
    });
  }
}
