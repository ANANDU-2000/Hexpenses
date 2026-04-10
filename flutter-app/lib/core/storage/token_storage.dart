import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._p);

  final SharedPreferences _p;

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _sessionId = 'session_id';
  static const _userEmail = 'user_email';

  static Future<TokenStorage> create() async {
    final p = await SharedPreferences.getInstance();
    return TokenStorage(p);
  }

  String? get access => _p.getString(_access);
  String? get refresh => _p.getString(_refresh);
  String? get sessionId => _p.getString(_sessionId);
  String? get userEmail => _p.getString(_userEmail);

  Future<void> saveTokens({
    required String access,
    required String refresh,
    String? sessionId,
  }) async {
    await _p.setString(_access, access);
    await _p.setString(_refresh, refresh);
    if (sessionId != null && sessionId.isNotEmpty) {
      await _p.setString(_sessionId, sessionId);
    } else {
      await _p.remove(_sessionId);
    }
  }

  Future<void> setUserEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _p.remove(_userEmail);
    } else {
      await _p.setString(_userEmail, email.trim());
    }
  }

  Future<void> clear() async {
    await _p.remove(_access);
    await _p.remove(_refresh);
    await _p.remove(_sessionId);
    await _p.remove(_userEmail);
  }
}
