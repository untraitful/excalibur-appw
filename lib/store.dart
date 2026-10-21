import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// App state: services, SSH hosts and settings. Non-secret data lives in
/// shared preferences; SSH credentials live in the Android Keystore-backed
/// secure storage.
class AppStore extends ChangeNotifier {
  AppStore._(this._prefs);

  static const _kServices = 'services';
  static const _kHosts = 'hosts';
  static const _kNetworkMode = 'networkMode';

  final SharedPreferences _prefs;
  final _secure = const FlutterSecureStorage();

  List<Service> services = [];
  List<SshHost> hosts = [];
  NetworkMode networkMode = NetworkMode.auto;

  static Future<AppStore> load() async {
    final store = AppStore._(await SharedPreferences.getInstance());
    store._read();
    return store;
  }

  void _read() {
    services = _decodeList(_prefs.getString(_kServices), Service.fromJson);
    hosts = _decodeList(_prefs.getString(_kHosts), SshHost.fromJson);
    networkMode = NetworkMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_kNetworkMode),
      orElse: () => NetworkMode.auto,
    );
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _kServices, jsonEncode(services.map((s) => s.toJson()).toList()));
    await _prefs.setString(
        _kHosts, jsonEncode(hosts.map((h) => h.toJson()).toList()));
    await _prefs.setString(_kNetworkMode, networkMode.name);
    notifyListeners();
  }

  List<String> get categories {
    final seen = <String>{};
    return [for (final s in services) if (seen.add(s.category)) s.category];
  }

  // Services -----------------------------------------------------------------

  Future<void> upsertService(Service s) {
    final i = services.indexWhere((e) => e.id == s.id);
    i == -1 ? services.add(s) : services[i] = s;
    return _persist();
  }

  Future<void> deleteService(Service s) {
    services.removeWhere((e) => e.id == s.id);
    return _persist();
  }

  // Hosts --------------------------------------------------------------------

  Future<void> upsertHost(SshHost h, {SshSecrets? secrets}) async {
    final i = hosts.indexWhere((e) => e.id == h.id);
    i == -1 ? hosts.add(h) : hosts[i] = h;
    if (secrets != null) await saveSecrets(h.id, secrets);
    await _persist();
  }

  Future<void> deleteHost(SshHost h) async {
    hosts.removeWhere((e) => e.id == h.id);
    for (final k in ['password', 'key', 'passphrase']) {
      await _secure.delete(key: '${h.id}.$k');
    }
    await _persist();
  }

  Future<void> trustFingerprint(SshHost h, String fingerprint) {
    h.fingerprint = fingerprint;
    return _persist();
  }

  Future<void> saveSecrets(String hostId, SshSecrets s) async {
    await _secure.write(key: '$hostId.password', value: s.password);
    await _secure.write(key: '$hostId.key', value: s.privateKey);
    await _secure.write(key: '$hostId.passphrase', value: s.passphrase);
  }

  Future<SshSecrets> loadSecrets(String hostId) async => SshSecrets(
        password: await _secure.read(key: '$hostId.password') ?? '',
        privateKey: await _secure.read(key: '$hostId.key') ?? '',
        passphrase: await _secure.read(key: '$hostId.passphrase') ?? '',
      );

  // Settings -----------------------------------------------------------------

  Future<void> setNetworkMode(NetworkMode m) {
    networkMode = m;
    return _persist();
  }

  // Backup -------------------------------------------------------------------

  /// Exports services and hosts as JSON. Credentials are never exported.
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'services': services.map((s) => s.toJson()).toList(),
        'hosts': hosts.map((h) => h.toJson()).toList(),
      });

  /// Replaces services and hosts with the contents of [raw]. Throws
  /// [FormatException] on malformed input.
  Future<void> importJson(String raw) async {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    services = [
      for (final e in (data['services'] as List? ?? []))
        Service.fromJson(e as Map<String, dynamic>)
    ];
    hosts = [
      for (final e in (data['hosts'] as List? ?? []))
        SshHost.fromJson(e as Map<String, dynamic>)
    ];
    await _persist();
  }
}
