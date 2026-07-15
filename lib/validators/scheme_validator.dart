import '../models/scheme.dart';

class SchemeValidator {
  const SchemeValidator();

  List<String> validate(Scheme scheme) {
    final errors = <String>[];

    if (scheme.id.trim().isEmpty) {
      errors.add("Missing id");
    }

    if (scheme.title.trim().isEmpty) {
      errors.add("Missing title");
    }

    if (scheme.description.trim().isEmpty) {
      errors.add("Missing description");
    }

    if (scheme.category.trim().isEmpty) {
      errors.add("Missing category");
    }

    if (scheme.ministry.trim().isEmpty) {
      errors.add("Missing ministry");
    }

    return errors;
  }

  bool isValid(Scheme scheme) {
    return validate(scheme).isEmpty;
  }
}