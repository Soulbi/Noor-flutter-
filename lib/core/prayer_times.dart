import 'dart:math' as math;

/// Real astronomical prayer-time calculation — a 1:1 port of the web app's
/// JS implementation (www/index.html, "PRAYER TIMES" section). No external
/// service, works fully offline, same formulas (NOAA-style solar position +
/// standard hour-angle method used by most prayer-time libraries).

/// Calculation method: how many degrees below the horizon the sun must be
/// for Fajr/Isha, or (for Umm al-Qura) a fixed number of minutes after
/// Maghrib for Isha instead of an angle. Matches the `METHODS` table in the
/// web app exactly, including which one is the app's default ("france" —
/// Musulmans de France / ex-UOIF, 12°/12°, used by most mosques in France
/// including on Mawaqit).
enum PrayerCalcMethod { france, mwl, isna, egypt, uqu, karachi }

class _MethodParams {
  final double fajr;
  final double? isha; // degrees below horizon, or null if ishaFixedMinutes is used
  final double? ishaFixedMinutes; // minutes after Maghrib, or null if isha angle is used
  const _MethodParams({required this.fajr, this.isha, this.ishaFixedMinutes});
}

const Map<PrayerCalcMethod, _MethodParams> _methods = {
  PrayerCalcMethod.france: _MethodParams(fajr: 12, isha: 12),
  PrayerCalcMethod.mwl: _MethodParams(fajr: 18, isha: 17),
  PrayerCalcMethod.isna: _MethodParams(fajr: 15, isha: 15),
  PrayerCalcMethod.egypt: _MethodParams(fajr: 19.5, isha: 17.5),
  PrayerCalcMethod.uqu: _MethodParams(fajr: 18.5, ishaFixedMinutes: 90),
  PrayerCalcMethod.karachi: _MethodParams(fajr: 18, isha: 18),
};

/// Asr school: Standard (Shafi'i/Maliki/Hanbali, shadow factor 1) or Hanafi
/// (shadow factor 2) — matches the web app's `asr-method` select (1 or 2).
enum AsrMethod { standard, hanafi }

extension AsrMethodFactor on AsrMethod {
  int get shadowFactor => this == AsrMethod.hanafi ? 2 : 1;
}

class PrayerTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// The six rows in display order, each as (key, DateTime). "sunrise" is
  /// included (shown but never treated as a prayer — same as the web app).
  List<MapEntry<String, DateTime>> get ordered => [
        MapEntry('fajr', fajr),
        MapEntry('sunrise', sunrise),
        MapEntry('dhuhr', dhuhr),
        MapEntry('asr', asr),
        MapEntry('maghrib', maghrib),
        MapEntry('isha', isha),
      ];
}

double _dsin(double d) => math.sin(d * math.pi / 180);
double _dcos(double d) => math.cos(d * math.pi / 180);
double _dtan(double d) => math.tan(d * math.pi / 180);
double _darcsin(double x) => math.asin(x) * 180 / math.pi;
double _darccos(double x) => math.acos(x.clamp(-1.0, 1.0)) * 180 / math.pi;
double _darctan2(double y, double x) => math.atan2(y, x) * 180 / math.pi;

double _fixAngle(double a) {
  a = a % 360;
  if (a < 0) a += 360;
  return a;
}

double _fixHour(double h) {
  h = h % 24;
  if (h < 0) h += 24;
  return h;
}

double _julianDate(int y, int m, int d) {
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floorToDouble() + (30.6001 * (m + 1)).floorToDouble() + d + b - 1524.5;
}

class _SunPosition {
  final double decl;
  final double eqt;
  const _SunPosition(this.decl, this.eqt);
}

_SunPosition _sunPosition(double jd) {
  final dDays = jd - 2451545.0;
  final g = _fixAngle(357.529 + 0.98560028 * dDays);
  final q = _fixAngle(280.459 + 0.98564736 * dDays);
  final l = _fixAngle(q + 1.915 * _dsin(g) + 0.020 * _dsin(2 * g));
  final e = 23.439 - 0.00000036 * dDays;
  final ra = _fixHour(_darctan2(_dcos(e) * _dsin(l), _dcos(l)) / 15);
  final eqt = q / 15 - ra;
  final decl = _darcsin(_dsin(e) * _dsin(l));
  return _SunPosition(decl, eqt);
}

/// Returns the hour-angle (in hours) for the sun to reach [alt] degrees of
/// altitude at [lat]/[decl], or null if the sun never reaches it that day
/// (e.g. near the poles) — same "null = skip this correction" contract as
/// the web app.
double? _hourAngle(double alt, double lat, double decl) {
  final term = (_dsin(alt) - _dsin(lat) * _dsin(decl)) / (_dcos(lat) * _dcos(decl));
  if (term > 1 || term < -1) return null;
  return _darccos(term) / 15;
}

/// Computes the six prayer times for [date] (local calendar day) at
/// [lat]/[lng], given the caller's UTC offset in hours ([tzOffsetHours] —
/// pass a fixed `-DateTime.now().timeZoneOffset` equivalent in hours, same
/// as the web app's `tzOffsetHoursNow()`), a [method] and an Asr
/// [asrShadowFactor] (1 = standard, 2 = Hanafi).
PrayerTimes computePrayerTimes(
  DateTime date,
  double lat,
  double lng,
  double tzOffsetHours,
  PrayerCalcMethod method,
  int asrShadowFactor,
) {
  final params = _methods[method] ?? _methods[PrayerCalcMethod.france]!;
  final jd = _julianDate(date.year, date.month, date.day) + 0.5 - lng / 360;
  final sun = _sunPosition(jd);
  final decl = sun.decl;
  final eqt = sun.eqt;

  final dhuhr = 12 - lng / 15 - eqt + tzOffsetHours;
  final hSun = _hourAngle(-0.833, lat, decl);
  final hFajr = _hourAngle(-params.fajr, lat, decl);
  final asrAlt = _darctan2(1, asrShadowFactor + (_dtan(lat - decl)).abs());
  final hAsr = _hourAngle(asrAlt, lat, decl);
  final maghrib = dhuhr + (hSun ?? 0);

  double isha;
  if (params.ishaFixedMinutes != null) {
    isha = maghrib + params.ishaFixedMinutes! / 60;
  } else {
    final hIsha = _hourAngle(-params.isha!, lat, decl);
    isha = dhuhr + (hIsha ?? 0);
  }

  DateTime toDate(double hours) {
    final h = _fixHour(hours);
    final dd = DateTime(date.year, date.month, date.day);
    return dd.add(Duration(minutes: (h * 60).round()));
  }

  return PrayerTimes(
    fajr: toDate(dhuhr - (hFajr ?? 0)),
    sunrise: toDate(dhuhr - (hSun ?? 0)),
    dhuhr: toDate(dhuhr),
    asr: toDate(dhuhr + (hAsr ?? 0)),
    maghrib: toDate(maghrib),
    isha: toDate(isha),
  );
}

/// The device's current UTC offset in hours (fractional for e.g. UTC+5:30),
/// matching the web app's `tzOffsetHoursNow()`.
double tzOffsetHoursNow() => DateTime.now().timeZoneOffset.inMinutes / 60.0;

PrayerCalcMethod prayerCalcMethodFromString(String s) {
  for (final m in PrayerCalcMethod.values) {
    if (m.name == s) return m;
  }
  return PrayerCalcMethod.france;
}

AsrMethod asrMethodFromInt(int i) => i == 2 ? AsrMethod.hanafi : AsrMethod.standard;
int asrMethodToInt(AsrMethod m) => m == AsrMethod.hanafi ? 2 : 1;
