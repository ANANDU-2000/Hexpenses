import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/storage/token_storage.dart';

class Session extends Notifier<bool> {
  @override
  bool build() => false;

  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> hydrate() async {
    final t = _storage.access;
    state = t != null && t.isNotEmpty;
  }

  void setLoggedIn(bool v) => state = v;

  Future<void> logout() async {
    await _storage.clear();
    state = false;
  }
}

final sessionProvider = NotifierProvider<Session, bool>(Session.new);
