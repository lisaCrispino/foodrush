import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../../core/monitoring/sentry_service.dart';

class AuthRepository {
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserEmail = 'user_email';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserAddress = 'user_address';

  Future<AppUser> login(String email, String password) async {
    final transaction = SentryService.startTransaction('auth.login', 'user');
    final span = transaction.startChild('validate.credentials');

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (password.length < 6) {
        throw Exception('Senha inválida');
      }

      await span.finish();
      final saveSpan = transaction.startChild('save.session');

      final user = AppUser(
        id: 'user_${email.hashCode.abs()}',
        name: _nameFromEmail(email),
        email: email,
        phone: '(11) 99999-0000',
        address: 'Av. Paulista, 1000 - Bela Vista, São Paulo',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, user.id);
      await prefs.setString(_keyUserName, user.name);
      await prefs.setString(_keyUserEmail, user.email);
      await prefs.setString(_keyUserPhone, user.phone);
      await prefs.setString(_keyUserAddress, user.address);

      await saveSpan.finish();

      await SentryService.setUser(
        id: user.id,
        email: user.email,
        username: user.name,
      );

      SentryService.addBreadcrumb(
        'Login realizado com sucesso',
        category: 'auth',
        level: SentryLevel.info,
        data: {'userId': user.id},
      );

      await transaction.finish(status: const SpanStatus.ok());
      return user;
    } catch (e, st) {
      await span.finish(status: const SpanStatus.internalError());
      await transaction.finish(status: const SpanStatus.internalError());
      await SentryService.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  Future<AppUser> register(String name, String email, String password) async {
    final transaction = SentryService.startTransaction('auth.register', 'user');
    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      final user = AppUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: '',
        address: '',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, user.id);
      await prefs.setString(_keyUserName, user.name);
      await prefs.setString(_keyUserEmail, user.email);
      await prefs.setString(_keyUserPhone, user.phone);
      await prefs.setString(_keyUserAddress, user.address);

      await SentryService.setUser(
        id: user.id,
        email: user.email,
        username: user.name,
      );

      SentryService.addBreadcrumb(
        'Novo usuário cadastrado',
        category: 'auth',
        data: {'userId': user.id},
      );

      await transaction.finish(status: const SpanStatus.ok());
      return user;
    } catch (e, st) {
      await transaction.finish(status: const SpanStatus.internalError());
      await SentryService.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  Future<AppUser?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyUserId);
    if (id == null) return null;

    final user = AppUser(
      id: id,
      name: prefs.getString(_keyUserName) ?? '',
      email: prefs.getString(_keyUserEmail) ?? '',
      phone: prefs.getString(_keyUserPhone) ?? '',
      address: prefs.getString(_keyUserAddress) ?? '',
    );

    await SentryService.setUser(
      id: user.id,
      email: user.email,
      username: user.name,
    );

    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SentryService.clearUser();
    SentryService.addBreadcrumb('Logout realizado', category: 'auth');
  }

  String _nameFromEmail(String email) {
    final parts = email.split('@').first.split('.');
    return parts.map((p) => p[0].toUpperCase() + p.substring(1)).join(' ');
  }
}
