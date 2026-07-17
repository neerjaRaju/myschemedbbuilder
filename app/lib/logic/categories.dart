import 'package:flutter/material.dart';

/// A browsable category with the keyword rules that map it onto the
/// free-text `category`, `tags` and content columns of the database.
class SchemeCategory {
  /// Stable key, also used as the localization key.
  final String key;
  final IconData icon;

  /// Keywords matched (case-insensitively) against category/tags/content.
  final List<String> keywords;

  const SchemeCategory(this.key, this.icon, this.keywords);
}

/// The fifteen home-screen categories.
const List<SchemeCategory> kCategories = [
  SchemeCategory('agriculture', Icons.agriculture, [
    'agriculture',
    'farmer',
    'crop',
    'kisan',
    'irrigation',
    'horticulture',
  ]),
  SchemeCategory('women', Icons.woman, [
    'women',
    'woman',
    'girl',
    'mahila',
    'mother',
    'maternity',
  ]),
  SchemeCategory('students', Icons.school, [
    'student',
    'education',
    'school',
    'college',
    'learning',
  ]),
  SchemeCategory('seniorCitizens', Icons.elderly, [
    'senior citizen',
    'old age',
    'elderly',
    'pension',
  ]),
  SchemeCategory('business', Icons.storefront, [
    'business',
    'msme',
    'enterprise',
    'self-employ',
    'entrepreneur',
    'udyam',
  ]),
  SchemeCategory('health', Icons.local_hospital, [
    'health',
    'medical',
    'hospital',
    'wellness',
    'treatment',
    'ayushman',
  ]),
  SchemeCategory('housing', Icons.home, [
    'housing',
    'house',
    'awas',
    'shelter',
    'local services',
  ]),
  SchemeCategory('employment', Icons.work, [
    'employment',
    'job',
    'rozgar',
    'wage',
    'unemploy',
  ]),
  SchemeCategory('pension', Icons.savings, [
    'pension',
    'retirement',
    'annuity',
  ]),
  SchemeCategory('insurance', Icons.verified_user, [
    'insurance',
    'bima',
    'assurance',
    'cover',
  ]),
  SchemeCategory('scholarships', Icons.emoji_events, [
    'scholarship',
    'fellowship',
    'stipend',
  ]),
  SchemeCategory('disabled', Icons.accessible, [
    'disabilit',
    'divyang',
    'handicap',
    'pwd',
  ]),
  SchemeCategory('ruralDevelopment', Icons.landscape, [
    'rural',
    'village',
    'panchayat',
    'gram',
  ]),
  SchemeCategory('startup', Icons.rocket_launch, [
    'startup',
    'start-up',
    'incubat',
    'innovation',
  ]),
  SchemeCategory('skillDevelopment', Icons.construction, [
    'skill',
    'training',
    'apprentice',
    'vocational',
    'kaushal',
  ]),
];

SchemeCategory categoryByKey(String key) =>
    kCategories.firstWhere((c) => c.key == key);
