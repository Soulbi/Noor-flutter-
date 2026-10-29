import 'dart:async';
import 'package:flutter/material.dart';
import '../core/i18n.dart';
import '../core/location_service.dart';
import '../core/mosques.dart';
import '../core/prayer_times.dart';
import '../core/storage.dart';
import '../theme/app_theme.dart';

/// Prières screen: next-prayer hero card + full day's times, nearby-mosque
/// search (local dataset, see core/mosques.dart) with selection, and the
/// calculation-method / Asr-school settings. A faithful port of the web
/// app's "view-prieres" section (www/index.html) — same storage keys, same
/// default method ("france" — Musulmans de France, 12°/12°), same default
/// Asr school (standard), so a user moving from the old app to this one
/// keeps their saved choices (SharedPreferences reads the same JSON shape
/// the web app wrote to localStorage under the same key names).
class PrieresScreen extends StatefulWidget {
  const PrieresScreen({super.key});

  @override
  State<PrieresScreen> createState() => _PrieresScreenState();
}

class _UserLoc {
  final double lat;
  final double lng;
  final String labelKey; // 'locMine' — always "my location" once GPS succeeds
  const _UserLoc({required this.lat, required this.lng, required this.labelKey});
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng, 'label': labelKey};
  static _UserLoc? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return _UserLoc(lat: (j['lat'] as num).toDouble(), lng: (j['lng'] as num).toDouble(), labelKey: 'locMine');
  }
}

class _PrieresScreenState extends State<PrieresScreen> {
  _UserLoc? _userLoc;
  Mosque? _selectedMosque;
  List<Mosque>? _mosqueList; // null = no search attempted yet, [] = searched, found none
  bool _mosqueSearching = false;
  bool _mosqueFailed = false;
  bool _locating = false;
  PrayerCalcMethod _calcMethod = PrayerCalcMethod.france;
  AsrMethod _asrMethod = AsrMethod.standard;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _calcMethod = prayerCalcMethodFromString(Storage.get<String>('calc-method', 'france'));
    _asrMethod = asrMethodFromInt(Storage.get<int>('asr-method', 1));
    _userLoc = _UserLoc.fromJson(Storage.get<Map<String, dynamic>?>('user-loc', null));
    final storedMosque = Storage.get<Map<String, dynamic>?>('selected-mosque', null);
    if (storedMosque != null) _selectedMosque = Mosque.fromJson(storedMosque);

    // Keep the countdown + "next prayer" row fresh, same cadence as the web
    // app's setInterval(renderPrayers, 30000).
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    if (_userLoc != null) {
      _searchMosquesNear(_userLoc!.lat, _userLoc!.lng);
    } else if (_selectedMosque != null) {
      _mosqueList = [_selectedMosque!];
    } else {
      // Silent first-load attempt — no error shown on failure, same as the
      // web app's `if(!userLoc) requestLocation(true)`.
      _requestLocation(silent: true);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _searchMosquesNear(double lat, double lng) async {
    final locale = AppLocaleScope.of(context);
    setState(() {
      _mosqueSearching = true;
      _mosqueFailed = false;
    });
    try {
      final list = await findNearbyMosques(lat, lng, genericName: locale.t('mosqueGeneric'));
      if (!mounted) return;
      setState(() {
        _mosqueList = list;
        _mosqueSearching = false;
        if (_selectedMosque == null && list.isNotEmpty) {
          _selectMosque(list.first);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mosqueSearching = false;
        _mosqueFailed = true;
      });
    }
  }

  void _selectMosque(Mosque m) {
    setState(() => _selectedMosque = m);
    Storage.set('selected-mosque', m.toJson());
  }

  void _useGpsInstead() {
    setState(() => _selectedMosque = null);
    Storage.set('selected-mosque', null);
  }

  Future<void> _requestLocation({required bool silent}) async {
    setState(() => _locating = true);
    final result = await getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    switch (result) {
      case LocationSuccess(:final lat, :final lng):
        final loc = _UserLoc(lat: lat, lng: lng, labelKey: 'locMine');
        setState(() {
          _userLoc = loc;
          _selectedMosque = null;
        });
        Storage.set('user-loc', loc.toJson());
        Storage.set('selected-mosque', null);
        _searchMosquesNear(lat, lng);
      case LocationFailure(:final reason):
        if (!silent && mounted) {
          final key = switch (reason) {
            LocationFailureReason.serviceDisabled => 'locServiceDisabled',
            LocationFailureReason.permissionDenied => 'locPermissionDenied',
            LocationFailureReason.permissionDeniedForever => 'locPermissionDeniedForever',
            LocationFailureReason.unavailable => 'locUnavailable',
          };
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocaleScope.of(context).t(key))));
        }
    }
  }

  void _setCalcMethod(PrayerCalcMethod m) {
    setState(() => _calcMethod = m);
    Storage.set('calc-method', m.name);
  }

  void _setAsrMethod(AsrMethod m) {
    setState(() => _asrMethod = m);
    Storage.set('asr-method', asrMethodToInt(m));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocaleScope.of(context);
    final t = locale.t;
    final p = context.palette;
    final english = locale.lang == AppLang.en;

    double lat, lng;
    String labelText;
    final isMosque = _selectedMosque != null;
    if (_selectedMosque != null) {
      lat = _selectedMosque!.lat;
      lng = _selectedMosque!.lng;
      labelText = _selectedMosque!.name;
    } else if (_userLoc != null) {
      lat = _userLoc!.lat;
      lng = _userLoc!.lng;
      labelText = t(_userLoc!.labelKey);
    } else {
      lat = 48.8566;
      lng = 2.3522;
      labelText = t('locParisExample');
    }

    final times = computePrayerTimes(DateTime.now(), lat, lng, tzOffsetHoursNow(), _calcMethod, _asrMethod.shadowFactor);
    final rows = <MapEntry<String, DateTime>>[
      MapEntry('Fajr', times.fajr),
      MapEntry(t('prayerSunrise'), times.sunrise),
      MapEntry('Dhuhr', times.dhuhr),
      MapEntry('Asr', times.asr),
      MapEntry('Maghrib', times.maghrib),
      MapEntry('Isha', times.isha),
    ];
    final now = DateTime.now();
    MapEntry<String, DateTime>? next;
    for (final row in rows) {
      final isPrayer = row.key != t('prayerSunrise');
      if (isPrayer && row.value.isAfter(now)) {
        next = row;
        break;
      }
    }
    next ??= MapEntry('Fajr', times.fajr.add(const Duration(days: 1)));
    final diffMins = next.value.difference(now).inMinutes.clamp(0, 1 << 30);
    final countdown = diffMins < 60 ? locale.tParams('inMin', {'n': diffMins}) : locale.tParams('inHrMin', {'h': diffMins ~/ 60, 'm': diffMins % 60});

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(t('navPrieres'), style: fraunces(context, fontSize: 22)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 17, color: p.teal),
                      const SizedBox(width: 6),
                      Expanded(child: Text(labelText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _locating ? null : () => _requestLocation(silent: false),
                  child: Text(_locating ? t('locating') : t('prieresLocateBtn'), style: TextStyle(color: p.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            if (isMosque)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _useGpsInstead,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(t('prieresUseGps'), style: TextStyle(color: p.teal, fontWeight: FontWeight.w600, fontSize: 12.5)),
                ),
              ),
            if (_userLoc == null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(12)),
                child: Text(t('prieresLocBanner'), style: TextStyle(fontSize: 12, color: p.inkSoft, height: 1.4)),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [p.teal, p.tealDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('prieresNextEyebrow'), style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: .4)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(next.key, style: fraunces(context, fontSize: 28, weight: FontWeight.w600, color: Colors.white)),
                      Text(_fmtTime(next.value), style: fraunces(context, fontSize: 24, weight: FontWeight.w600, color: const Color(0xFFF5E9D0))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(countdown, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: rows.map((row) {
                  final isPrayer = row.key != t('prayerSunrise');
                  final isNext = isPrayer && identical(row, next);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(row.key, style: TextStyle(fontSize: 14, fontWeight: isNext ? FontWeight.w700 : FontWeight.w500, color: isNext ? p.ink : p.inkSoft)),
                        Text(_fmtTime(row.value), style: TextStyle(fontSize: 14, fontWeight: isNext ? FontWeight.w700 : FontWeight.w500, color: isNext ? p.ink : p.inkSoft, fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Text(t('prieresMosquesTitle'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkSoft, letterSpacing: .4)),
            const SizedBox(height: 10),
            if (_mosqueSearching)
              _MosqueBanner(text: t('mosqueSearching'), p: p)
            else if (_mosqueFailed)
              _MosqueBanner(
                text: t('mosqueError'),
                p: p,
                action: TextButton(
                  onPressed: () => _userLoc != null ? _searchMosquesNear(_userLoc!.lat, _userLoc!.lng) : null,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(t('retry'), style: TextStyle(color: p.teal, decoration: TextDecoration.underline)),
                ),
              )
            else if (_mosqueList != null && _mosqueList!.isEmpty)
              _MosqueBanner(text: t('mosqueNone'), p: p)
            else if (_mosqueList != null)
              Column(
                children: _mosqueList!.map((m) {
                  final isSel = _selectedMosque != null && _selectedMosque!.name == m.name && (_selectedMosque!.lat - m.lat).abs() < 0.0001;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectMosque(m),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSel ? p.teal : p.line, width: isSel ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mosque_outlined, size: 20, color: p.teal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(child: Text(m.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink), overflow: TextOverflow.ellipsis)),
                                      if (isSel) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.check_circle, size: 14, color: p.teal),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [formatDistance(m.distMeters, english: english), if (m.addr.isNotEmpty) m.addr].join(' · '),
                                    style: TextStyle(fontSize: 11.5, color: p.inkSoft),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('prieresCalcTitle'), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkSoft, letterSpacing: .4)),
                  const SizedBox(height: 12),
                  Text(t('prieresCalcAngleLabel'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.ink)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PrayerCalcMethod>(
                    value: _calcMethod,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: p.cardAlt,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    style: TextStyle(fontSize: 12.5, color: p.ink),
                    items: [
                      DropdownMenuItem(value: PrayerCalcMethod.france, child: Text(t('prieresCalcFrance'), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: PrayerCalcMethod.mwl, child: Text(t('prieresCalcMwl'), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: PrayerCalcMethod.isna, child: Text(t('prieresCalcIsna'), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: PrayerCalcMethod.egypt, child: Text(t('prieresCalcEgypt'), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: PrayerCalcMethod.uqu, child: Text(t('prieresCalcUqu'), overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: PrayerCalcMethod.karachi, child: Text(t('prieresCalcKarachi'), overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (m) {
                      if (m != null) _setCalcMethod(m);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(t('prieresCalcAsrLabel'), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.ink)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(t('prieresCalcAsrStandard')),
                        selected: _asrMethod == AsrMethod.standard,
                        onSelected: (_) => _setAsrMethod(AsrMethod.standard),
                        selectedColor: p.teal,
                        labelStyle: TextStyle(color: _asrMethod == AsrMethod.standard ? Colors.white : p.ink, fontWeight: FontWeight.w600, fontSize: 12.5),
                        backgroundColor: p.cardAlt,
                        side: BorderSide.none,
                      ),
                      ChoiceChip(
                        label: Text(t('prieresCalcAsrHanafi')),
                        selected: _asrMethod == AsrMethod.hanafi,
                        onSelected: (_) => _setAsrMethod(AsrMethod.hanafi),
                        selectedColor: p.teal,
                        labelStyle: TextStyle(color: _asrMethod == AsrMethod.hanafi ? Colors.white : p.ink, fontWeight: FontWeight.w600, fontSize: 12.5),
                        backgroundColor: p.cardAlt,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(t('prieresCalcNote'), style: TextStyle(fontSize: 11.5, color: p.inkSoft, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosqueBanner extends StatelessWidget {
  final String text;
  final AppPalette p;
  final Widget? action;
  const _MosqueBanner({required this.text, required this.p, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: p.inkSoft))),
          if (action != null) action!,
        ],
      ),
    );
  }
}

String _fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
