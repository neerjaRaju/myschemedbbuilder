import '../logic/filters.dart';
import '../models/scheme.dart';

/// Answers collected by the eligibility questionnaire.
class EligibilityProfile {
  final int? age;
  final String gender; // 'female' | 'male' | ''
  final String state; // exact state name or ''
  final int? annualIncome; // rupees
  final String occupation; // one of SmartFilters.kOccupations or ''
  final String casteCategory; // 'sc' | 'st' | 'obc' | ''

  const EligibilityProfile({
    this.age,
    this.gender = '',
    this.state = '',
    this.annualIncome,
    this.occupation = '',
    this.casteCategory = '',
  });

  Map<String, String> toMap() => {
        'age': age?.toString() ?? '',
        'gender': gender,
        'state': state,
        'income': annualIncome?.toString() ?? '',
        'occupation': occupation,
        'caste': casteCategory,
      };

  factory EligibilityProfile.fromMap(Map<String, String> map) =>
      EligibilityProfile(
        age: int.tryParse(map['age'] ?? ''),
        gender: map['gender'] ?? '',
        state: map['state'] ?? '',
        annualIncome: int.tryParse(map['income'] ?? ''),
        occupation: map['occupation'] ?? '',
        casteCategory: map['caste'] ?? '',
      );
}

/// Result of running the checker.
class EligibilityResult {
  final List<Scheme> eligible;

  const EligibilityResult(this.eligible);

  int get count => eligible.length;
}

/// Rule-based eligibility screening over the scheme corpus.
///
/// Eligibility criteria in the data are free text, so this checker excludes
/// schemes whose parsed constraints (age window, income ceiling, gender,
/// state, occupation, social category) clearly conflict with the profile
/// and keeps everything else. Results are therefore "you may be eligible" —
/// the same personalized-discovery approach the official myScheme portal
/// uses, always to be confirmed on the official site.
class EligibilityChecker {
  /// Screens [schemes] against [profile].
  static EligibilityResult run(
    List<Scheme> schemes,
    EligibilityProfile profile,
  ) {
    final filters = SmartFilters(
      state: profile.state,
      age: profile.age,
      gender: profile.gender,
      income: profile.annualIncome,
      occupation: profile.occupation,
      casteCategory: profile.casteCategory,
    );
    final eligible = schemes.where(filters.matches).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return EligibilityResult(eligible);
  }
}
