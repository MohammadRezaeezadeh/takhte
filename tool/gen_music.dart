// Procedurally composes the game's music: long, slowly evolving pieces in
// Persian modes with an A/B form, motif variation, a plucked santur-like
// voice, a soft pad and a light daf, plus a "tension" version of each game
// track (same length and form, more drive) for adaptive playback.
//
//   dart run tool/gen_music.dart   (needs ffmpeg on PATH)
//
// Every track's tail is overlap-added onto its head, so the loop point is a
// seamless crossfade. Deterministic: same output every run.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 22050;

class Rand {
  Rand(this._s);
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7FFFFFFF;
    return _s / 0x7FFFFFFF;
  }

  int nextInt(int n) => (next() * n).floor() % n;
  T pick<T>(List<T> l) => l[nextInt(l.length)];
}

/// Modes as semitone offsets from the tonic (12-TET approximations).
const Map<String, List<int>> modes = {
  // Shur-like (D E♭ F G A B♭ C).
  'shur': [0, 1, 3, 5, 7, 8, 10],
  // Homayoun-like (E F G♯ A B C D).
  'homayoun': [0, 1, 4, 5, 7, 8, 10],
  // Mahur-like (major).
  'mahur': [0, 2, 4, 5, 7, 9, 11],
};

double midiHz(num m) => 440 * math.pow(2, (m - 69) / 12).toDouble();

/// Karplus–Strong pluck with a slightly detuned double (santur shimmer).
void pluck(
  Float64List out,
  int start,
  double hz,
  double amp,
  double seconds,
  Rand r,
) {
  for (final detune in [1.0, 1.0035]) {
    final n = math.max(2, (sr / (hz * detune)).round());
    final ring = Float64List(n);
    for (var i = 0; i < n; i++) {
      ring[i] = (r.next() * 2 - 1) * amp * 0.5;
    }
    final len = (seconds * sr).round();
    var idx = 0;
    for (var i = 0; i < len && start + i < out.length; i++) {
      final a = ring[idx];
      final b = ring[(idx + 1) % n];
      final v = (a + b) * 0.4985;
      ring[idx] = v;
      idx = (idx + 1) % n;
      final env = i < 30 ? i / 30 : 1.0;
      out[start + i] += a * env;
    }
  }
}

/// Soft pad: detuned sines with slow attack/release.
void pad(Float64List out, int start, List<double> hzs, double amp, double sec) {
  final len = (sec * sr).round();
  final att = (sr * 1.2).round();
  for (final hz in hzs) {
    for (final d in [0.997, 1.0, 1.004]) {
      final w = 2 * math.pi * hz * d / sr;
      for (var i = 0; i < len && start + i < out.length; i++) {
        final env = i < att ? i / att : (i > len - att ? (len - i) / att : 1.0);
        out[start + i] += math.sin(w * i) * amp * env / 3;
      }
    }
  }
}

/// Daf: a low thump (dum) or a bright slap (tak).
void daf(Float64List out, int start, double amp, Rand r, {required bool low}) {
  final len = (sr * (low ? 0.35 : 0.12)).round();
  for (var i = 0; i < len && start + i < out.length; i++) {
    final t = i / sr;
    final env = math.exp(-t * (low ? 11 : 40));
    final v = low
        ? math.sin(2 * math.pi * (70 - 25 * t) * t)
        : (r.next() * 2 - 1) * 0.6 + math.sin(2 * math.pi * 900 * t) * 0.2;
    out[start + i] += v * env * amp;
  }
}

/// Small Schroeder reverb (4 combs + 2 allpasses), mixed in place.
void reverb(Float64List x, double wet) {
  final combs = [1557, 1617, 1491, 1422];
  final y = Float64List(x.length);
  for (final d in combs) {
    final buf = Float64List(d);
    var i = 0;
    var lp = 0.0;
    for (var n = 0; n < x.length; n++) {
      final o = buf[i];
      lp = o * 0.6 + lp * 0.4;
      buf[i] = x[n] + lp * 0.78;
      i = (i + 1) % d;
      y[n] += o / combs.length;
    }
  }
  for (final d in [225, 556]) {
    final buf = Float64List(d);
    var i = 0;
    for (var n = 0; n < y.length; n++) {
      final b = buf[i];
      final v = y[n] + b * 0.5;
      buf[i] = v;
      y[n] = b - v * 0.5;
      i = (i + 1) % d;
    }
  }
  for (var n = 0; n < x.length; n++) {
    x[n] = x[n] * (1 - wet) + y[n] * wet;
  }
}

/// A 2-bar motif: scale degrees and durations (in beats).
class Motif {
  Motif(this.degrees, this.beats);

  factory Motif.random(Rand r, {required double beatsTotal}) {
    final d = <int>[];
    final b = <double>[];
    var used = 0.0;
    var deg = r.pick([0, 2, 4]);
    while (used < beatsTotal - 0.01) {
      final dur = math.min(
        beatsTotal - used,
        r.pick<double>([0.5, 0.5, 1.0, 1.0, 1.5, 2.0]),
      );
      d.add(deg);
      b.add(dur);
      used += dur;
      deg += r.pick([-2, -1, -1, 1, 1, 2, 0, 3]);
      deg = deg.clamp(-3, 9);
    }
    return Motif(d, b);
  }
  final List<int> degrees;
  final List<double> beats;

  Motif varied(Rand r) {
    final d = List<int>.of(degrees);
    final b = List<double>.of(beats);
    switch (r.nextInt(4)) {
      case 0: // transpose
        final t = r.pick([-2, -1, 1, 2]);
        for (var i = 0; i < d.length; i++) {
          d[i] += t;
        }
      case 1: // invert around the first note
        final p = d.first;
        for (var i = 0; i < d.length; i++) {
          d[i] = p - (d[i] - p);
        }
      case 2: // ornament: split a long note into a turn
        final i = r.nextInt(d.length);
        if (b[i] >= 1) {
          b
            ..[i] = b[i] / 2
            ..insert(i + 1, b[i]);
          d.insert(i + 1, d[i] + r.pick([1, -1]));
        }
      default: // new ending
        d[d.length - 1] = d.first + r.pick([0, 2, 4, -3]);
    }
    return Motif(d, b);
  }
}

Float64List compose({
  required int seed,
  required String mode,
  required int tonic,
  required double bpm,
  required double seconds,
  required bool drums,
  bool tension = false,
}) {
  final r = Rand(seed);
  // Drums get their own stream so the base and tension versions keep the
  // exact same melody and can be crossfaded at the same position.
  final rd = Rand(seed + 9973);
  final scale = modes[mode]!;
  final out = Float64List((seconds * sr).round() + sr * 6);
  final beat = 60 / bpm;
  final bar = beat * 4;
  int degToMidi(int deg) {
    final o = (deg / scale.length).floor();
    final i = deg - o * scale.length;
    return tonic + 12 * o + scale[i];
  }

  // Sections: A, B, A', B'' ... until the piece is long enough. Each section
  // is 8 bars = 4 motifs; B uses new motifs, primes vary the old ones.
  final aMotifs = [for (var i = 0; i < 2; i++) Motif.random(r, beatsTotal: 8)];
  final bMotifs = [for (var i = 0; i < 2; i++) Motif.random(r, beatsTotal: 8)];
  final chordsA = [0, -2, -3, 0];
  final chordsB = [3, 2, 0, -2];
  var t = 0.0;
  var section = 0;
  while (t < seconds) {
    final isB = section.isOdd;
    final round = section ~/ 2;
    final motifs = isB ? bMotifs : aMotifs;
    final chords = isB ? chordsB : chordsA;
    for (var phrase = 0; phrase < 4 && t < seconds; phrase++) {
      var m = motifs[phrase % 2];
      // Later rounds and second halves vary the motif, so nothing repeats
      // verbatim: no fixed hook.
      for (var k = 0; k < round + (phrase >= 2 ? 1 : 0); k++) {
        m = m.varied(r);
      }
      final start = t;
      // Pad chord under the phrase.
      final root = degToMidi(chords[phrase]) - 12;
      pad(
        out,
        (start * sr).round(),
        [midiHz(root), midiHz(root + 7), midiHz(root + 12)],
        tension ? 0.05 : 0.07,
        bar * 2 + 1,
      );
      // Melody (rests sometimes, to breathe).
      var bt = start;
      for (var i = 0; i < m.degrees.length; i++) {
        final dur = m.beats[i] * beat;
        if (r.next() > 0.12 || i == 0) {
          pluck(
            out,
            (bt * sr).round(),
            midiHz(degToMidi(m.degrees[i]) + 12),
            0.42,
            math.min(2.5, dur + 1.2),
            r,
          );
        }
        bt += dur;
      }
      // Daf pattern: dum . tak . | dum dum tak .
      if (drums) {
        final hits = tension
            ? const [
                (0.0, true),
                (1.0, false),
                (1.5, false),
                (2.0, true),
                (2.5, true),
                (3.0, false),
                (3.5, false),
              ]
            : const [
                (0.0, true),
                (1.0, false),
                (2.0, true),
                (2.5, true),
                (3.0, false),
              ];
        for (var b = 0; b < 2; b++) {
          for (final (pos, low) in hits) {
            daf(
              out,
              ((start + b * bar + pos * beat) * sr).round(),
              low ? 0.35 : 0.14,
              rd,
              low: low,
            );
          }
        }
      }
      // Tension: a pulsing low drone an octave down.
      if (tension) {
        final hz = midiHz(degToMidi(chords[phrase]) - 24);
        final len = (bar * 2 * sr).round();
        final w = 2 * math.pi * hz / sr;
        final s0 = (start * sr).round();
        for (var i = 0; i < len && s0 + i < out.length; i++) {
          final pulse = 0.6 + 0.4 * math.sin(2 * math.pi * (bpm / 60) * i / sr);
          out[s0 + i] += math.sin(w * i) * 0.09 * pulse;
        }
      }
      t += bar * 2;
    }
    section++;
  }
  reverb(out, 0.28);
  // Seamless loop: overlap-add the tail (after `seconds`) onto the head with
  // an equal-power crossfade, then cut to length.
  final n = (seconds * sr).round();
  const fade = sr * 4;
  for (var i = 0; i < fade && n + i < out.length; i++) {
    final f = i / fade;
    out[i] =
        out[i] * math.sin(f * math.pi / 2) +
        out[n + i] * math.cos(f * math.pi / 2);
  }
  return Float64List.sublistView(out, 0, n);
}

void writeOgg(String name, Float64List b, {double gain = 0.8}) {
  var peak = 1e-9;
  for (final v in b) {
    if (v.abs() > peak) peak = v.abs();
  }
  final scale = gain / peak;
  final data = ByteData(44 + b.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + b.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sr, Endian.little)
    ..setUint32(28, sr * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, b.length * 2, Endian.little);
  for (var i = 0; i < b.length; i++) {
    final s = (b[i] * scale).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (s * 32767).round(), Endian.little);
  }
  final wav = File('build/music/$name.wav')..createSync(recursive: true);
  wav.writeAsBytesSync(data.buffer.asUint8List());
  final res = Process.runSync('ffmpeg', [
    ...['-loglevel', 'error', '-y', '-i', wav.path],
    ...['-c:a', 'libvorbis', '-q:a', '1', 'assets/audio/$name.ogg'],
  ]);
  if (res.exitCode != 0) throw StateError('ffmpeg: ${res.stderr}');
  print('assets/audio/$name.ogg  ${(b.length / sr).toStringAsFixed(0)}s');
}

void main() {
  final sw = Stopwatch()..start();
  writeOgg(
    'music_menu',
    compose(
      seed: 11,
      mode: 'mahur',
      tonic: 57,
      bpm: 66,
      seconds: 150,
      drums: false,
    ),
    gain: 0.7,
  );
  for (final (name, seed, mode, tonic, bpm) in [
    ('music_game_a', 23, 'shur', 50, 84.0),
    ('music_game_b', 37, 'homayoun', 52, 92.0),
  ]) {
    writeOgg(
      name,
      compose(
        seed: seed,
        mode: mode,
        tonic: tonic,
        bpm: bpm,
        seconds: 180,
        drums: true,
      ),
    );
    writeOgg(
      '${name}_tension',
      compose(
        seed: seed,
        mode: mode,
        tonic: tonic,
        bpm: bpm,
        seconds: 180,
        drums: true,
        tension: true,
      ),
    );
  }
  print('done in ${sw.elapsed.inSeconds}s');
}
