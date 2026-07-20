// Recorder (Katalog: `RecorderScreen`) — der Lauf-Aufnehmer.
// Nach dem Original-Storyboard (Durchlauf 3): spot evaluation -> recording ->
// Warnung bei zu langsam -> Beenden-Bestaetigung.
//
// WICHTIG: Die Live-Anzeige hier (Tempo, Aktivitaetstyp, Warnung) ist BERATENDES
// Client-Feedback. Die verbindliche Wertung „zaehlt der Lauf fuer die Wette?"
// macht spaeter der SERVER ueber die (signierten) Rohdaten. Die Bewegungsdaten
// sind hier SIMULIERT (beschleunigt) — ein Lauf wird als Buendel roher `RunSample`
// gesammelt; der Wechsel zu echten Sensoren/Server ist nur ein Quellen-Austausch.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/my_bets_store.dart';
import '../models/bet.dart';
import '../models/run.dart';
import '../theme/app_theme.dart';

const _walkColor = Color(0xFF9BA3AE); // grau
const _jogColor = Color(0xFFEC5E2A); // orange
const _runColor = Color(0xFF3FA9E0); // blau

Color _activityColor(ActivityType t) => switch (t) {
      ActivityType.walking => _walkColor,
      ActivityType.jogging => _jogColor,
      ActivityType.running => _runColor,
    };

IconData _activityIcon(ActivityType t) =>
    t == ActivityType.walking ? Icons.directions_walk : Icons.directions_run;

enum _Phase { ready, recording }

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key, required this.placed});

  final PlacedBet placed;

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  _Phase _phase = _Phase.ready;
  RunSource _source = RunSource.phone;

  int _elapsedSec = 0;
  int _meters = 0;
  int _pace = 0; // momentanes Tempo (Sek/km)
  int _tick = 0;
  bool _reached = false;
  final List<RunSample> _samples = [];
  final _rng = math.Random();
  Timer? _timer;

  late final ActivityType _required =
      requiredActivityForRunning(widget.placed.bet.sport == Sport.running);
  late final int _targetMeters = (widget.placed.bet.distanceKm * 1000).round();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _avgPace => _meters <= 0 ? 0 : (_elapsedSec * 1000 / _meters).round();
  ActivityType get _activity => classifyPace(_pace);
  bool get _slow => _phase == _Phase.recording && !_reached && _activity.index < _required.index;

  void _start() {
    setState(() {
      _phase = _Phase.recording;
      _elapsedSec = 0;
      _meters = 0;
      _tick = 0;
      _reached = false;
      _samples
        ..clear()
        ..add(const RunSample(tSec: 0, meters: 0, paceSecPerKm: 0));
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), _step);
  }

  // Ein simulierter Schritt: 8 Sekunden Laufzeit, Tempo um den geforderten Typ
  // schwankend, mit wiederkehrender Verlangsamung (loest die Warnung aus).
  void _step(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    _tick++;
    const dt = 8;
    final base = _required == ActivityType.running ? 320 : 430;
    double pace = base + 25 * math.sin(_tick / 3.0) + (_rng.nextInt(30) - 15);
    if (_tick % 22 < 4) pace += 230; // Durchhänger
    final p = pace.round().clamp(180, 1200);
    final dm = (dt * 1000 / p).round();
    setState(() {
      _pace = p;
      _elapsedSec += dt;
      _meters += dm;
      if (_meters >= _targetMeters) {
        _meters = _targetMeters;
        _reached = true;
      }
      _samples.add(RunSample(tSec: _elapsedSec, meters: _meters, paceSecPerKm: _pace));
      if (_reached) _timer?.cancel();
    });
  }

  void _confirmFinish() {
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('finish recording?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'You are positive about finishing recording?\n\n${_fmtKm(_meters)} in ${_fmtTime(_elapsedSec)}.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (!_reached) _timer = Timer.periodic(const Duration(milliseconds: 200), _step);
            },
            child: const Text('go on', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
            onPressed: () {
              Navigator.of(ctx).pop();
              _finish();
            },
            child: const Text('finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _finish() {
    _timer?.cancel();
    final run = Run(source: _source, samples: List.of(_samples));
    final qualifies = run.qualifyingMeters(_required) >= _targetMeters;
    myBetsStore.recordRun(widget.placed, run, qualifies: qualifies);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(qualifies
          ? 'Run recorded — activity counted (${_fmtKm(run.qualifyingMeters(_required))} as ${_required.label}).'
          : 'Run recorded, but the ${_required.label} target wasn\'t reached.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            Expanded(child: SingleChildScrollView(child: _body())),
          ],
        ),
      ),
    );
  }

  // ---- Header (orange): Zustand + die drei grossen Kennzahlen ----
  Widget _header(BuildContext context) {
    final recording = _phase == _Phase.recording;
    return Container(
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              if (recording)
                Row(
                  children: [
                    const Text('rec', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ],
                )
              else
                const Text('spot evaluation', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmtPace(_avgPace),
                  style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1)),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 6),
                child: Text('m/km', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('average speed', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _big(_fmtTime(_elapsedSec), 'covered time')),
              Expanded(child: _big(_fmtKm(_meters), 'covered distance', right: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _big(String value, String label, {bool right = false}) {
    return Column(
      crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  // ---- Body (dunkel) ----
  Widget _body() {
    final recording = _phase == _Phase.recording;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Was die Wette verlangt.
          _kv('recording for', '"${widget.placed.bet.name}"'),
          _kv('target', '${_fmtKmPlain(_targetMeters)} km as ${_required.label}'),
          const SizedBox(height: 10),
          if (recording) ...[
            Row(
              children: [
                Icon(_activityIcon(_activity), color: _activityColor(_activity), size: 22),
                const SizedBox(width: 8),
                Text('recorded activity: ${_activity.label}',
                    style: TextStyle(color: _activityColor(_activity), fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            // Warnung: du bist unter dem geforderten Typ.
            if (_slow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFC0392B), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'You are slowing down — now ${_activity.label}. Only ${_required.label} or faster counts.',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            if (_slow) const SizedBox(height: 12),
            // Fortschritt Richtung Ziel (Pillenrinne).
            _progress(),
            const SizedBox(height: 6),
            Text('${(_meters / (_targetMeters == 0 ? 1 : _targetMeters) * 100).clamp(0, 100).round()}% of target',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 14),
            // Segmente nach Aktivitaetstyp (was das Original als Abschnitte zeigt).
            const Text('segments', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _segmentsBar(),
            const SizedBox(height: 6),
            _legend(),
          ],
          if (!recording) ...[
            const SizedBox(height: 8),
            Text('Tap rec to start. Movement is simulated for now — the run is stored as raw sample data.',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.35)),
            const SizedBox(height: 12),
            _sourceToggle(),
          ],
          const SizedBox(height: 22),
          _actionButton(),
        ],
      ),
    );
  }

  Widget _actionButton() {
    if (_phase == _Phase.ready) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, shape: const StadiumBorder()),
          onPressed: _start,
          icon: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
          label: const Text('rec', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ),
      );
    }
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _reached ? AppColors.orange : AppColors.surface,
          shape: const StadiumBorder(),
          side: _reached ? null : const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        onPressed: _confirmFinish,
        icon: Icon(Icons.stop, color: _reached ? Colors.white : AppColors.orange, size: 20),
        label: Text(_reached ? 'target reached · finish' : 'stop',
            style: TextStyle(
                color: _reached ? Colors.white : AppColors.orange, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _sourceToggle() {
    Widget chip(RunSource s, IconData ic) {
      final on = _source == s;
      return GestureDetector(
        onTap: () => setState(() => _source = s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: on ? AppColors.orange.withValues(alpha: 0.16) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppColors.orange : AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ic, size: 16, color: on ? AppColors.orange : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(s.label, style: TextStyle(color: on ? AppColors.textPrimary : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        const Text('source', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(width: 10),
        chip(RunSource.phone, Icons.smartphone),
        chip(RunSource.watch, Icons.watch),
      ],
    );
  }

  Widget _progress() {
    final p = _targetMeters == 0 ? 0.0 : (_meters / _targetMeters).clamp(0.0, 1.0);
    const h = 8.0;
    return Container(
      height: h,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(h / 2)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: p,
        child: Container(decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(h / 2))),
      ),
    );
  }

  Widget _segmentsBar() {
    final segs = Run(source: _source, samples: _samples).segments;
    if (segs.isEmpty) {
      return Container(height: 12, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          for (final s in segs)
            Expanded(
              flex: math.max(1, s.meters),
              child: Container(height: 12, color: _activityColor(s.type)),
            ),
        ],
      ),
    );
  }

  Widget _legend() {
    Widget item(ActivityType t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: _activityColor(t)),
            const SizedBox(width: 4),
            Text(t.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        );
    return Row(
      children: [item(ActivityType.walking), const SizedBox(width: 12), item(ActivityType.jogging), const SizedBox(width: 12), item(ActivityType.running)],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ---- Formatierung ----
  String _fmtPace(int secPerKm) {
    if (secPerKm <= 0) return '0:00';
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtTime(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fmtKm(int meters) => '${(meters / 1000).toStringAsFixed(2)} km';
  String _fmtKmPlain(int meters) => (meters / 1000) == (meters ~/ 1000) ? '${meters ~/ 1000}' : (meters / 1000).toStringAsFixed(1);
}
