class AppConfig {
  static const bool isProduction = false;

  static const String googleMapsApiKey =
      "AIzaSyAhv_CJ858WLT8uMUCzw43vclHPbxwRXuA";

  static String get baseUrl {
    if (isProduction) {
      return 'http://192.168.1.100:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }
}
