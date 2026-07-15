import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Computes a standard hex-encoded SHA-256 hash of the input payload.
String sha256Hash(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
