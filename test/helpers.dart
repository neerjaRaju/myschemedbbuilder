import 'package:government_scheme_db_builder/models/scheme.dart';

/// Builds a fully populated scheme for tests, with overridable fields.
Scheme makeScheme({
  String? id,
  String title = 'PM Kisan Samman Nidhi',
  String description = 'Income support for farmer families.',
  String benefits = 'Rs 6000 per year in three installments.',
  String eligibility = 'All landholding farmer families.',
  List<String> requiredDocuments = const ['Aadhaar Card', 'Land Records'],
  String applicationProcess = 'Apply online via the portal.',
  String ministry = 'Ministry of Agriculture and Farmers Welfare',
  String department = 'Department of Agriculture',
  String category = 'Agriculture',
  List<String> tags = const ['farmer', 'income-support'],
  String state = 'Central',
  String officialUrl = 'https://www.myscheme.gov.in/schemes/pm-kisan',
  String helpline = '+91-1555261',
  Map<String, String> faq = const {'Who is eligible?': 'Farmer families.'},
  String lastUpdated = '2026-01-15',
}) {
  return Scheme(
    id: id ?? officialUrl.hashCode.toRadixString(16).padLeft(16, '0'),
    title: title,
    description: description,
    benefits: benefits,
    eligibility: eligibility,
    requiredDocuments: requiredDocuments,
    applicationProcess: applicationProcess,
    ministry: ministry,
    department: department,
    category: category,
    tags: tags,
    state: state,
    officialUrl: officialUrl,
    helpline: helpline,
    faq: faq,
    lastUpdated: lastUpdated,
  );
}
