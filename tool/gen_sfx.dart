// Procedurally synthesizes every sound effect used by the game as 16-bit mono
// WAV files in assets/audio/. Deterministic: the same output every run.
//
//   dart run tool/gen_sfx.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sr = 22050;

class Noise {
  Noise(this._s);
  int _s;
  double next() {
    _s ^= (_s << 13) & 0xFFFFFFFF;
    _s ^= _s >> 17;
    _s ^= (_s << 5) & 0xFFFFFFFF;
    _s &= 0xFFFFFFFF;
    return _s / 0x7FFFFFFF - 1.0;
  }
}

List<double> buf(double seconds) =>
    List<double>.filled((seconds * sr).round(), 0);

double env(double t, double attack, double decay) {
  if (t < 0) return 0;
  if (t < attack) return t / attack;
  return math.exp(-(t - attack) / decay);
}

/// Adds a decaying sine partial.
void tone(
  List<double> b,
  double start,
  double freq,
  double amp,
  double decay, {
  double attack = 0.002,
  double vibrato = 0,
}) {
  final s0 = (start * sr).round();
  var phase = 0.0;
  for (var i = s0; i < b.length; i++) {
    final t = (i - s0) / sr;
    final e = env(t, attack, decay);
    if (t > attack && e < 0.0005) break;
    final f = freq * (1 + vibrato * math.sin(2 * math.pi * 5.5 * t));
    phase += 2 * math.pi * f / sr;
    b[i] += math.sin(phase) * amp * e;
  }
}

/// Bell: inharmonic partials.
void bell(List<double> b, double start, double freq, double amp, double decay) {
  const partials = [1.0, 2.0, 2.76, 5.4, 8.93];
  const amps = [1.0, 0.6, 0.45, 0.25, 0.12];
  for (var k = 0; k < partials.length; k++) {
    tone(b, start, freq * partials[k], amp * amps[k], decay / (1 + k * 0.6));
  }
}

/// Plucked string (santur-like) via Karplus–Strong.
void pluck(List<double> b, double start, double freq, double amp, Noise n) {
  final period = (sr / freq).round();
  final ring = List<double>.generate(period, (_) => n.next());
  final s0 = (start * sr).round();
  var idx = 0;
  final len = (1.6 * sr).round();
  for (var i = 0; i < len && s0 + i < b.length; i++) {
    final a = ring[idx];
    final nxt = ring[(idx + 1) % period];
    ring[idx] = 0.4985 * (a + nxt);
    b[s0 + i] += a * amp;
    idx = (idx + 1) % period;
  }
}

/// Noise burst through a one-pole low-pass filter.
void burst(
  List<double> b,
  double start,
  double dur,
  double amp,
  Noise n, {
  double cutoff = 0.3,
  double decay = 0.03,
}) {
  final s0 = (start * sr).round();
  var y = 0.0;
  final len = (dur * sr).round();
  for (var i = 0; i < len && s0 + i < b.length; i++) {
    final t = i / sr;
    y += cutoff * (n.next() - y);
    b[s0 + i] += y * amp * env(t, 0.001, decay);
  }
}

/// Filtered noise with a moving cutoff (whoosh).
void sweep(
  List<double> b,
  double start,
  double dur,
  double amp,
  Noise n,
  double c0,
  double c1,
) {
  final s0 = (start * sr).round();
  final len = (dur * sr).round();
  var y = 0.0;
  for (var i = 0; i < len && s0 + i < b.length; i++) {
    final u = i / len;
    final c = c0 + (c1 - c0) * u;
    y += c * (n.next() - y);
    final e = math.sin(math.pi * u);
    b[s0 + i] += y * amp * e * e;
  }
}

/// Pitch-dropping sine (thump).
void thump(
  List<double> b,
  double start,
  double f0,
  double f1,
  double amp,
  double dur,
) {
  final s0 = (start * sr).round();
  final len = (dur * sr).round();
  var phase = 0.0;
  for (var i = 0; i < len && s0 + i < b.length; i++) {
    final u = i / len;
    final f = f0 * math.pow(f1 / f0, u);
    phase += 2 * math.pi * f / sr;
    b[s0 + i] += math.sin(phase) * amp * math.exp(-u * 5);
  }
}

void write(String name, List<double> b, {double gain = 0.9}) {
  var peak = 1e-9;
  for (final v in b) {
    peak = math.max(peak, v.abs());
  }
  final scale = gain / peak;
  // Fade the last 5 ms to avoid clicks.
  final fade = (0.005 * sr).round();
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
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sr, Endian.little);
  data.setUint32(28, sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, b.length * 2, Endian.little);
  for (var i = 0; i < b.length; i++) {
    var v = b[i] * scale;
    final fromEnd = b.length - i;
    if (fromEnd < fade) v *= fromEnd / fade;
    final s = (v.clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, s, Endian.little);
  }
  File('assets/audio/$name.wav').writeAsBytesSync(data.buffer.asUint8List());
  print('assets/audio/$name.wav  ${(b.length / sr).toStringAsFixed(2)}s');
}

void main() {
  final n = Noise(0x1234567);

  // Dice rattle: a dozen irregular clicks thinning out.
  var b = buf(0.75);
  var t = 0.0;
  for (var k = 0; k < 14; k++) {
    burst(b, t, 0.03, 0.7 - k * 0.04, n, cutoff: 0.55, decay: 0.006);
    tone(b, t, 2400 + (k * 377) % 900, 0.25, 0.01);
    t += 0.025 + (k * 0.007) + (n.next().abs() * 0.02);
  }
  write('dice_roll', b);

  b = buf(0.25);
  thump(b, 0, 220, 90, 0.8, 0.15);
  burst(b, 0, 0.05, 0.5, n, cutoff: 0.4, decay: 0.01);
  tone(b, 0, 1900, 0.3, 0.02);
  write('dice_land', b);

  // Checker clacks (wood on wood) in three pitches.
  for (var v = 0; v < 3; v++) {
    b = buf(0.18);
    burst(b, 0, 0.04, 0.9, n, cutoff: 0.6, decay: 0.004);
    tone(b, 0, 1150.0 + v * 140, 0.6, 0.025);
    tone(b, 0, 2650.0 + v * 210, 0.3, 0.012);
    thump(b, 0, 300, 140, 0.35, 0.06);
    write('clack_$v', b);
  }

  b = buf(0.22);
  sweep(b, 0, 0.2, 0.6, n, 0.05, 0.25);
  write('slide', b);

  // Hit: heavy thump, crack and a short low ring.
  b = buf(0.55);
  thump(b, 0, 160, 45, 1, 0.35);
  burst(b, 0, 0.12, 0.8, n, cutoff: 0.7, decay: 0.02);
  tone(b, 0.01, 620, 0.25, 0.12);
  tone(b, 0.01, 930, 0.15, 0.08);
  write('hit', b);

  // Bear-off chime.
  b = buf(1.2);
  bell(b, 0, 880, 0.5, 0.5);
  bell(b, 0.07, 1318.5, 0.35, 0.45);
  write('bear_off', b);

  // 7–7 fanfare: rising santur plucks in a Shur-like mode, then bells.
  b = buf(2.4);
  const mode = [293.66, 311.13, 349.23, 392.0, 440.0, 466.16, 523.25, 587.33];
  for (var k = 0; k < mode.length; k++) {
    pluck(b, k * 0.075, mode[k], 0.55, n);
  }
  bell(b, 0.62, 587.33, 0.6, 0.9);
  bell(b, 0.62, 880, 0.45, 0.9);
  bell(b, 0.64, 1174.66, 0.3, 0.8);
  sweep(b, 0.55, 1.2, 0.18, n, 0.02, 0.5);
  write('seven_fanfare', b);

  b = buf(0.45);
  sweep(b, 0, 0.4, 0.8, n, 0.03, 0.6);
  write('card_whoosh', b);

  b = buf(0.12);
  burst(b, 0, 0.05, 0.8, n, cutoff: 0.8, decay: 0.005);
  tone(b, 0, 3200, 0.2, 0.01);
  write('card_flip', b);

  b = buf(0.6);
  bell(b, 0, 659.25, 0.4, 0.3);
  bell(b, 0.09, 987.77, 0.4, 0.35);
  sweep(b, 0, 0.3, 0.12, n, 0.2, 0.7);
  write('card_pick', b);

  b = buf(0.06);
  tone(b, 0, 1800, 0.6, 0.008);
  burst(b, 0, 0.01, 0.2, n, cutoff: 0.9, decay: 0.002);
  write('ui_tick', b);

  b = buf(0.3);
  tone(b, 0, 784, 0.5, 0.06);
  tone(b, 0.07, 1175, 0.5, 0.09);
  write('ui_confirm', b);

  b = buf(0.3);
  tone(b, 0, 660, 0.45, 0.06);
  tone(b, 0.07, 440, 0.45, 0.09);
  write('ui_back', b);

  b = buf(0.7);
  bell(b, 0, 1568, 0.45, 0.2);
  bell(b, 0.06, 2093, 0.35, 0.25);
  write('coin', b);

  b = buf(2.2);
  const win = [392.0, 493.88, 587.33, 783.99];
  for (var k = 0; k < win.length; k++) {
    pluck(b, k * 0.12, win[k], 0.5, n);
    bell(b, k * 0.12, win[k] * 2, 0.15, 0.4);
  }
  bell(b, 0.55, 783.99, 0.5, 1);
  bell(b, 0.55, 1174.66, 0.35, 0.9);
  write('win', b);

  b = buf(1.6);
  const lose = [440.0, 392.0, 349.23, 293.66];
  for (var k = 0; k < lose.length; k++) {
    pluck(b, k * 0.18, lose[k], 0.5, n);
  }
  write('lose', b);

  b = buf(1);
  thump(b, 0, 120, 30, 1, 0.7);
  burst(b, 0, 0.6, 0.9, n, cutoff: 0.25, decay: 0.15);
  write('mine', b);

  b = buf(1.2);
  for (var k = 0; k < 4; k++) {
    tone(b, k * 0.05, 300.0 + k * 220, 0.3, 0.3, vibrato: 0.02);
  }
  sweep(b, 0, 1, 0.3, n, 0.01, 0.15);
  write('magic', b);

  b = buf(0.4);
  thump(b, 0, 700, 1500, 0.6, 0.3);
  write('pop', b);

  // Ambient loop: a soft drone with occasional santur plucks (8 s, loops).
  b = buf(8);
  for (final f in [73.375, 110.0, 146.75]) {
    const s0 = 0;
    var phase = 0.0;
    for (var i = s0; i < b.length; i++) {
      final u = i / b.length;
      phase += 2 * math.pi * f / sr;
      b[i] +=
          math.sin(phase) * 0.08 * (0.75 + 0.25 * math.sin(2 * math.pi * u));
    }
  }
  const melody = [587.33, 523.25, 466.16, 440.0, 392.0, 440.0, 349.23, 293.66];
  for (var k = 0; k < melody.length; k++) {
    pluck(b, 0.3 + k * 0.92, melody[k], 0.18, n);
  }
  write('ambient', b, gain: 0.5);
}
