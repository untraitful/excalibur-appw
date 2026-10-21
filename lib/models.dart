import 'package:flutter/material.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

/// A web service in the homelab (Proxmox, Jellyfin, Home Assistant, ...).
class Service {
  Service({
    String? id,
    required this.name,
    required this.url,
    this.lanUrl = '',
    this.category = 'General',
    this.icon = 'web',
    this.openExternal = false,
  }) : id = id ?? newId();

  final String id;
  String name;

  /// Public address, e.g. https://jellyfin.example.com (Cloudflare Tunnel,
  /// reverse proxy, ...).
  String url;

  /// Optional LAN address, e.g. http://192.168.1.20:8096. Used instead of
  /// [url] when it answers (auto mode) or when local mode is forced.
  String lanUrl;
  String category;
  String icon;

  /// Open in the system browser instead of the in-app viewer.
  bool openExternal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'lanUrl': lanUrl,
    'category': category,
    'icon': icon,
    'openExternal': openExternal,
  };

  factory Service.fromJson(Map<String, dynamic> j) => Service(
    id: j['id'] as String?,
    name: j['name'] as String? ?? 'Unnamed',
    url: j['url'] as String? ?? '',
    lanUrl: j['lanUrl'] as String? ?? '',
    category: j['category'] as String? ?? 'General',
    icon: j['icon'] as String? ?? 'web',
    openExternal: j['openExternal'] as bool? ?? false,
  );
}

enum AuthMethod { password, key }

/// An SSH target. Secrets (password, private key, passphrase) are kept in
/// secure storage, keyed by [id], never in this object's JSON.
class SshHost {
  SshHost({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.auth = AuthMethod.key,
    this.fingerprint = '',
    this.startupCommand = '',
  }) : id = id ?? newId();

  final String id;
  String name;
  String host;
  int port;
  String username;
  AuthMethod auth;

  /// Trusted host key fingerprint (trust on first use).
  String fingerprint;

  /// Optional command to send after the shell opens, e.g. `tmux new -A -s main`.
  String startupCommand;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'username': username,
    'auth': auth.name,
    'fingerprint': fingerprint,
    'startupCommand': startupCommand,
  };

  factory SshHost.fromJson(Map<String, dynamic> j) => SshHost(
    id: j['id'] as String?,
    name: j['name'] as String? ?? 'Unnamed',
    host: j['host'] as String? ?? '',
    port: (j['port'] as num?)?.toInt() ?? 22,
    username: j['username'] as String? ?? 'root',
    auth: AuthMethod.values.firstWhere(
      (a) => a.name == j['auth'],
      orElse: () => AuthMethod.key,
    ),
    fingerprint: j['fingerprint'] as String? ?? '',
    startupCommand: j['startupCommand'] as String? ?? '',
  );
}

class SshSecrets {
  const SshSecrets({
    this.password = '',
    this.privateKey = '',
    this.passphrase = '',
  });
  final String password;
  final String privateKey;
  final String passphrase;
}

enum NetworkMode { auto, remote, local }

/// Monochrome icon set selectable per service.
const Map<String, IconData> serviceIcons = {
  'web': Icons.language,
  'server': Icons.dns_outlined,
  'storage': Icons.storage,
  'media': Icons.movie_outlined,
  'music': Icons.music_note_outlined,
  'photo': Icons.photo_outlined,
  'download': Icons.download_outlined,
  'home': Icons.home_outlined,
  'camera': Icons.videocam_outlined,
  'monitor': Icons.monitor_heart_outlined,
  'chart': Icons.show_chart,
  'network': Icons.router_outlined,
  'shield': Icons.shield_outlined,
  'key': Icons.key_outlined,
  'cloud': Icons.cloud_outlined,
  'code': Icons.code,
  'terminal': Icons.terminal,
  'container': Icons.view_in_ar_outlined,
  'book': Icons.menu_book_outlined,
  'mail': Icons.mail_outline,
  'gear': Icons.settings_outlined,
};

IconData iconFor(String key) => serviceIcons[key] ?? Icons.language;
