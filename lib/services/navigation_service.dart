import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService {
  static const String _apiKey = "YOUR_GOOGLE_API_KEY";

  Future<Map<String, dynamic>?> validateRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=$originLat,$originLng"
        "&destination=$destLat,$destLng"
        "&mode=driving"
        "&key=$_apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data["status"] == "ZERO_RESULTS") return null;
    if (data["routes"] == null || data["routes"].isEmpty) return null;

    final route = data["routes"][0];
    final leg = route["legs"][0];

    return {
      "distanceText": leg["distance"]["text"],
      "distanceValue": leg["distance"]["value"],
      "durationText": leg["duration"]["text"],
      "durationValue": leg["duration"]["value"],
      "polyline": route["overview_polyline"]["points"],
    };
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
}
