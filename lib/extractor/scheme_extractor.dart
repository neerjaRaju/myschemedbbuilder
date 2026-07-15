import '../models/scheme.dart';
import 'html_parser.dart';
import '../utils/normalizer.dart';
import '../utils/crypto_utils.dart';

class SchemeExtractor {
  /// Extracts a fully formed Scheme object from a raw HTML string and its metadata context.
  static Scheme extract({
    required String html,
    required String sourceUrl,
    required String defaultState,
    required String defaultMinistry,
  }) {
    final parser = HtmlParser(html);

    // Dynamic selectors targeting standard structures (with common fallbacks)
    final title = parser.selectText(
      'h1, .scheme-title, #scheme-name',
      fallback: 'Untitled Scheme',
    );
    final description = parser.selectText(
      'div.description, .scheme-details, p.about-scheme',
    );
    final benefits = parser.selectText(
      'div.benefits, #benefits, .scheme-benefits',
    );
    final eligibility = parser.selectText(
      'div.eligibility, #eligibility, .scheme-eligibility',
    );

    final documents = parser.selectList(
      'div.documents li, ul.required-docs li, .documents-list item',
    );
    final applicationProcess = parser.selectText(
      'div.application-process, #how-to-apply, .apply-steps',
    );

    final rawMinistry = parser.selectText(
      '.ministry-name, span.ministry, div.authority',
    );
    final ministry = rawMinistry.isNotEmpty ? rawMinistry : defaultMinistry;

    final department = parser.selectText('.department-name, span.department');
    final category = parser.selectText(
      '.scheme-category, .category-badge, a.category',
    );

    final tags = parser.selectList('.tag, .badge, .keywords li');
    final rawState = parser.selectText('.state-name, span.state');
    final state = rawState.isNotEmpty ? rawState : defaultState;

    final helpline = Normalizer.normalizeHelpline(
      parser.selectText('.helpline, .toll-free, #contact'),
    );

    // Extract FAQ blocks dynamically
    final faq = <String, String>{};
    final faqQuestions = parser.selectList('.faq-question, dt.question');
    final faqAnswers = parser.selectList('.faq-answer, dd.answer');
    for (int i = 0; i < faqQuestions.length && i < faqAnswers.length; i++) {
      faq[faqQuestions[i]] = faqAnswers[i];
    }

    final rawDate = parser.selectText('.last-updated, .updated-on, time');
    final lastUpdated = Normalizer.normalizeDate(rawDate);

    // Compute a deterministic, unique UUID based on the normalized URL
    final id = sha256Hash(Normalizer.normalizeUrl(sourceUrl)).substring(0, 16);

    return Scheme(
      id: id,
      title: title,
      description: description,
      benefits: benefits,
      eligibility: eligibility,
      requiredDocuments: documents,
      applicationProcess: applicationProcess,
      ministry: ministry,
      department: department,
      category: category,
      tags: tags,
      state: state,
      officialUrl: Normalizer.normalizeUrl(sourceUrl),
      helpline: helpline,
      faq: faq,
      lastUpdated: lastUpdated,
    );
  }
}
