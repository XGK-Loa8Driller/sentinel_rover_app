class AppConfig {
  static const bool isProduction = false;

  static String get baseUrl {
    if (isProduction) {
      return 'http://192.168.1.100:3000';
      // Jetson IP later
    } else {
      return 'http://10.0.2.2:3000';
    }
  }
}
