import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:verdant/data/api_client.dart';
import 'package:verdant/data/app_data.dart';
import 'package:verdant/data/storage.dart';
import 'package:verdant/data/sync.dart';
import 'package:verdant/l10n/i18n.dart';

/// The signed-in account.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.location = '',
  });

  final int id;
  final String email;
  final String name;
  final String location;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'location': location,
  };

  factory AppUser.fromJson(Map json) => AppUser(
    id: json['id'] as int,
    email: json['email'] as String,
    name: json['name'] as String,
    location: json['location'] as String? ?? '',
  );
}

/// Form checks shared by the sign-in and account pages.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? v) =>
      (v ?? '').trim().isEmpty ? 'What should we call you?'.tr : null;

  static String? email(String? v) => _email.hasMatch((v ?? '').trim())
      ? null
      : 'Enter a valid email address.'.tr;

  static String? newPassword(String? v) =>
      (v ?? '').length < 8 ? 'Use at least 8 characters.'.tr : null;

  static String? password(String? v) =>
      (v ?? '').isEmpty ? 'Enter your password.'.tr : null;
}

/// The session: who is signed in, and the actions that change it.
class AuthStore extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _secure = FlutterSecureStorage();

  AppUser? _user;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// Restores the saved session. Works offline; the server is checked after.
  Future<void> init() async {
    api.onSessionExpired = () => unawaited(_endSession());
    String? token;
    try {
      token = await _secure.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Secure storage unavailable: $e');
    }
    final cached = Storage.read(StorageKeys.user);
    if (token == null || cached is! Map) return;

    api.token = token;
    _user = AppUser.fromJson(cached);
    syncService.start();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      _setUser(AppUser.fromJson(await api.get('/me') as Map));
      await syncService.pull();
    } on ApiException catch (e) {
      debugPrint('Session refresh skipped: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _start('/auth/login', {'email': email.trim(), 'password': password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _start('/auth/register', {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
  });

  Future<void> _start(String path, Map<String, Object?> body) async {
    final data = await api.post(path, body) as Map;
    final token = data['token'] as String;
    api.token = token;
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Session will not survive a restart: $e');
    }
    syncService.start();
    _setUser(AppUser.fromJson(data['user'] as Map));
    // The account is usable even if the first download fails.
    try {
      await syncService.pull(adoptLocal: true);
    } on ApiException catch (e) {
      debugPrint('First sync postponed: $e');
    }
  }

  Future<void> updateProfile({
    required String name,
    required String location,
  }) async {
    final data = await api.patch('/me', {
      'name': name.trim(),
      'location': location.trim(),
    });
    _setUser(AppUser.fromJson(data as Map));
  }

  Future<void> changePassword({
    required String current,
    required String next,
  }) => api.post('/me/password', {
    'currentPassword': current,
    'newPassword': next,
  });

  /// Uploads pending changes, closes the session and clears this phone.
  Future<void> signOut() async {
    try {
      await syncService.flush().timeout(const Duration(seconds: 4));
      await api.post('/auth/logout');
    } on TimeoutException {
      // Offline: the phone is still cleared below.
    } on ApiException catch (e) {
      debugPrint('Sign-out request failed: $e');
    }
    await _endSession();
  }

  Future<void> deleteAccount(String password) async {
    await api.delete('/me', {'password': password});
    await _endSession();
  }

  /// Saves the profile again after the phone's data was erased.
  void rememberUser() {
    if (_user != null) Storage.writeLocal(StorageKeys.user, _user!.toJson());
  }

  void _setUser(AppUser user) {
    _user = user;
    rememberUser();
    notifyListeners();
  }

  Future<void> _endSession() async {
    if (_user == null && api.token == null) return;
    syncService.stop();
    api.token = null;
    _user = null;
    try {
      await _secure.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Could not remove the saved session: $e');
    }
    await Storage.clearAll();
    resetStores();
    notifyListeners();
  }
}

final authStore = AuthStore();
