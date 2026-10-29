import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// Nearby-mosque search — ported from the web app's "Nearby mosques" code
/// (www/index.html). Deliberately simple and entirely offline/local: the
/// full dataset (~1150 mosques across France, built from OpenStreetMap) is
/// bundled with the app as `assets/data/mosques-france.json`, so a search
/// is just an in-memory distance computation — no network call, no cache,
/// no stale-result fallback to get out of sync with the real position.
/// (This directly avoids the staleness bug the old Capacitor app had when
/// its live Overpass-API search failed and silently fell back to whatever
/// the previous successful search had returned.)
class Mosque {
  final String name;
  final double lat;
  final double lng;
  final String addr;
  final double distMeters;
  const Mosque({required this.name, required this.lat, required this.lng, required this.addr, required this.distMeters});

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng, 'addr': addr};

  factory Mosque.fromJson(Map<String, dynamic> json, {double distMeters = 0}) => Mosque(
        name: (json['name'] as String?) ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        addr: (json['addr'] as String?) ?? '',
        distMeters: distMeters,
      );
}

class _RawMosque {
  final String? name;
  final double lat;
  final double lng;
  final String? addr;
  const _RawMosque(this.name, this.lat, this.lng, this.addr);
}

List<_RawMosque>? _dataset;
Future<List<_RawMosque>>? _datasetFuture;

Future<List<_RawMosque>> _loadDataset() {
  if (_dataset != null) return Future.value(_dataset);
  _datasetFuture ??= rootBundle.loadString('assets/data/mosques-france.json').then((raw) {
    final list = (jsonDecode(raw) as List)
        .map((e) => e as Map<String, dynamic>)
        .map((m) => _RawMosque(m['name'] as String?, (m['lat'] as num).toDouble(), (m['lng'] as num).toDouble(), m['addr'] as String?))
        .toList();
    _dataset = list;
    return list;
  }).catchError((Object err) {
    // The bundled dataset failed to load — should never happen since it
    // ships with the app, but let a retry try again rather than caching
    // the failure forever.
    _datasetFuture = null;
    throw err;
  });
  return _datasetFuture!;
}

double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(toRad(lat1)) * math.cos(toRad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

const double mosqueMaxRadiusMeters = 50000;

/// Returns up to 8 mosques within [mosqueMaxRadiusMeters] of (lat, lng),
/// nearest first — fully recomputed from the static dataset every call, so
/// there is nothing to go stale when the position changes.
Future<List<Mosque>> findNearbyMosques(double lat, double lng, {required String genericName}) async {
  final dataset = await _loadDataset();
  final withDist = dataset
      .map((m) => Mosque(
            name: (m.name != null && m.name!.isNotEmpty) ? m.name! : genericName,
            lat: m.lat,
            lng: m.lng,
            addr: m.addr ?? '',
            distMeters: haversineMeters(lat, lng, m.lat, m.lng),
          ))
      .where((m) => m.distMeters <= mosqueMaxRadiusMeters)
      .toList();
  withDist.sort((a, b) => a.distMeters.compareTo(b.distMeters));
  return withDist.take(8).toList();
}

String formatDistance(double meters, {required bool english}) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  final text = km.toStringAsFixed(1);
  return '${english ? text : text.replaceFirst('.', ',')} km';
}
