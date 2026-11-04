import 'package:haftnard/core/ai/eval.dart';
import 'package:haftnard/core/effects/cards.dart';

enum Difficulty { beginner, easy, medium, hard, master }

/// A named AI opponent style.
class AiPersonality {
  const AiPersonality({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    required this.taglineEn,
    required this.taglineFa,
    this.weights = EvalWeights.standard,
    this.categoryBias = const {},
    this.riskLove = 0,
    this.avatarSeed = 0,
    this.hue = 0,
  });

  final String id;
  final String nameEn;
  final String nameFa;
  final String taglineEn;
  final String taglineFa;
  final EvalWeights weights;

  /// Multipliers on card value per category.
  final Map<CardCategory, double> categoryBias;

  /// 0 = cautious, 1 = loves risky cards.
  final double riskLove;
  final int avatarSeed;

  /// Accent hue (degrees) for the procedurally drawn avatar.
  final double hue;

  String name(String lang) => lang == 'fa' ? nameFa : nameEn;
  String tagline(String lang) => lang == 'fa' ? taglineFa : taglineEn;
}

const List<AiPersonality> kPersonalities = [
  AiPersonality(
    id: 'sage',
    nameEn: 'Mehri the Sage',
    nameFa: 'مهریِ فرزانه',
    taglineEn: 'Patient, balanced, rarely wrong.',
    taglineFa: 'صبور و متعادل؛ کمتر اشتباه می‌کند.',
    avatarSeed: 11,
    hue: 200,
  ),
  AiPersonality(
    id: 'hammer',
    nameEn: 'Dariush the Hammer',
    nameFa: 'داریوشِ چکش',
    taglineEn: 'Hits everything that moves.',
    taglineFa: 'هر مهره‌ای را که تنها ببیند می‌زند.',
    weights: EvalWeights(blot: 0.6, oppBar: 1.25, hitBonus: 0.55),
    categoryBias: {CardCategory.sabotage: 1.35, CardCategory.trap: 1.1},
    riskLove: 0.4,
    avatarSeed: 23,
    hue: 8,
  ),
  AiPersonality(
    id: 'builder',
    nameEn: 'Shirin the Builder',
    nameFa: 'شیرینِ معمار',
    taglineEn: 'Walls, primes and patience.',
    taglineFa: 'دیوار می‌سازد و منتظر می‌ماند.',
    weights: EvalWeights(blot: 1.5, prime: 0.5, homePoint: 0.7, point: 0.32),
    categoryBias: {CardCategory.checker: 1.4},
    avatarSeed: 37,
    hue: 140,
  ),
  AiPersonality(
    id: 'gambler',
    nameEn: 'Kian the Gambler',
    nameFa: 'کیانِ قمارباز',
    taglineEn: 'Never met a coin he would not flip.',
    taglineFa: 'هیچ سکه‌ای را بی‌پرتاب رها نمی‌کند.',
    weights: EvalWeights(blot: 0.85),
    categoryBias: {CardCategory.tempo: 1.4, CardCategory.dice: 1.2},
    riskLove: 1,
    avatarSeed: 41,
    hue: 45,
  ),
  AiPersonality(
    id: 'fox',
    nameEn: 'Bahram the Fox',
    nameFa: 'بهرامِ روباه',
    taglineEn: 'The board is full of surprises. His.',
    taglineFa: 'تخته پر از غافلگیری است؛ همه‌اش کار اوست.',
    weights: EvalWeights(anchor: 0.6),
    categoryBias: {CardCategory.trap: 1.5, CardCategory.sabotage: 1.15},
    riskLove: 0.3,
    avatarSeed: 53,
    hue: 280,
  ),
];

AiPersonality personalityById(String id) => kPersonalities.firstWhere(
  (p) => p.id == id,
  orElse: () => kPersonalities.first,
);
