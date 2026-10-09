import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';
  static const _kHash = 'user_pass_hash';
  static const _kLoggedIn = 'is_logged_in';

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static Future<void> signUp(
    String name,
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString(_kEmail) == email.toLowerCase()) {
      throw Exception('An account with this email already exists');
    }

    await prefs.setString(_kName, name);
    await prefs.setString(_kEmail, email.toLowerCase());
    await prefs.setString(_kHash, _hash(password));
  }

  static Future<void> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmail);
    final savedHash = prefs.getString(_kHash);

    if (savedEmail == null || savedHash == null) {
      throw Exception('No account found. Please sign up first.');
    }
    if (savedEmail != email.toLowerCase() || savedHash != _hash(password)) {
      throw Exception('Invalid email or password');
    }
    await prefs.setBool(_kLoggedIn, true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) ?? false;
  }

  static Future<String?> userName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, false);
  }
}