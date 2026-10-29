import 'package:geolocator/geolocator.dart';

/// Result of a location attempt: either a position, or one of the specific
/// failure reasons the Prières screen needs to show a useful message for
/// (mirrors the web app's getCurrentPosition error-code handling, but with
/// named cases instead of raw GeolocationPositionError codes).
sealed class LocationResult {
  const LocationResult();
}

class LocationSuccess extends LocationResult {
  final double lat;
  final double lng;
  const LocationSuccess(this.lat, this.lng);
}

class LocationFailure extends LocationResult {
  final LocationFailureReason reason;
  const LocationFailure(this.reason);
}

enum LocationFailureReason { serviceDisabled, permissionDenied, permissionDeniedForever, unavailable }

/// Requests the device's current GPS position, handling the
/// service-enabled and permission dance Geolocator requires before calling
/// getCurrentPosition. Equivalent to the web app's requestLocation(), minus
/// the UI side (the caller decides what to show for each failure case).
Future<LocationResult> getCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return const LocationFailure(LocationFailureReason.serviceDisabled);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationFailure(LocationFailureReason.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationFailure(LocationFailureReason.permissionDeniedForever);
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );
    return LocationSuccess(pos.latitude, pos.longitude);
  } catch (_) {
    return const LocationFailure(LocationFailureReason.unavailable);
  }
}
