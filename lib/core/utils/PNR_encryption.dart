import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:convert/convert.dart';

class Encryption {
  static const String _keyString = 'ShohaghTicketValidator2026Key_AES';
  static const String _ivString = 'ShohaghIV_2026Apr';

  static String? decrypt(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    try {
      final key = encrypt_pkg.Key.fromUtf8(_keyString);
      final iv = encrypt_pkg.IV.fromUtf8(_ivString);

      Uint8List encryptedBytes;
      try {
        String normalized = trimmed.replaceAll('-', '+').replaceAll('_', '/');
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }
        encryptedBytes = base64.decode(normalized);
      } catch (_) {
        try {
          encryptedBytes = Uint8List.fromList(hex.decode(trimmed));
        } catch (_) {
          return null;
        }
      }

      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key,
          mode: encrypt_pkg.AESMode.cbc, padding: 'PKCS7'));

      final decrypted = encrypter.decrypt(
        encrypt_pkg.Encrypted(encryptedBytes),
        iv: iv,
      );

      if (_isValidDecryptedText(decrypted)) {
        return decrypted;
      }
    } catch (e) {
      // Ignore decryption errors for failed attempts
    }
    return null;
  }

  static bool _isValidDecryptedText(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    return t.contains(RegExp(r'[A-Za-z0-9]'));
  }

  static Map<String, String>? parseDecryptedData(String decrypted) {
    try {
      final trimmed = decrypted.trim();

      if (trimmed.startsWith('{')) {
        final json = jsonDecode(trimmed);
        return {
          'pnr': (json['pnr'] ?? json['PNR'] ?? json['ticket_no'] ?? '')
              .toString(),
          'pin': (json['pin'] ?? json['PIN'] ?? json['secret_pin'] ?? '')
              .toString(),
        };
      }

      final delimiters = ['|', ':', ';'];
      for (var d in delimiters) {
        if (trimmed.contains(d)) {
          final parts = trimmed.split(d);
          if (parts.length >= 2) {
            return {
              'pnr': parts[0].trim(),
              'pin': parts[1].trim(),
            };
          }
        }
      }

      return {
        'pnr': trimmed,
        'pin': '',
      };
    } catch (_) {}
    return null;
  }
}


