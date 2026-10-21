import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

enum Health { unknown, checking, up, degraded, down }

class ServiceStatus {
  const ServiceStatus(
    this.health, {
    this.resolvedUrl,
    this.viaLan = false,
    this.ms,
  });
  final Health health;
  final String? resolvedUrl;
  final bool viaLan;
  final int? ms;
}

/// Probes services and decides which address (LAN or public) to use.
class HealthMonitor extends ChangeNotifier {
  final Map<String, ServiceStatus> _status = {};

  ServiceStatus statusOf(Service s) =>
      _status[s.id] ?? const ServiceStatus(Health.unknown);

  /// Any HTTP response counts as reachable: auth walls (401/403) and
  /// redirects to a login page mean the service is up. 5xx is degraded.
  static Future<(Health, int)> probe(String url, Duration timeout) async {
    final sw = Stopwatch()..start();
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))..followRedirects = false;
      final res = await client.send(req).timeout(timeout);
      unawaited(res.stream.drain<void>().catchError((_) {}));
      return (
        res.statusCode >= 500 ? Health.degraded : Health.up,
        sw.elapsedMilliseconds,
      );
    } catch (_) {
      return (Health.down, sw.elapsedMilliseconds);
    } finally {
      client.close();
    }
  }

  Future<void> check(Service s, NetworkMode mode) async {
    _status[s.id] = const ServiceStatus(Health.checking);
    notifyListeners();
    final hasLan = s.lanUrl.trim().isNotEmpty;

    if (hasLan && mode != NetworkMode.remote) {
      final (h, ms) = await probe(s.lanUrl, const Duration(milliseconds: 1500));
      if (h != Health.down || mode == NetworkMode.local) {
        _status[s.id] = ServiceStatus(
          h,
          resolvedUrl: s.lanUrl,
          viaLan: true,
          ms: ms,
        );
        notifyListeners();
        return;
      }
    }
    final url = s.url.trim().isNotEmpty ? s.url : s.lanUrl;
    final (h, ms) = await probe(url, const Duration(seconds: 6));
    _status[s.id] = ServiceStatus(
      h,
      resolvedUrl: url,
      viaLan: url == s.lanUrl,
      ms: ms,
    );
    notifyListeners();
  }

  Future<void> checkAll(List<Service> services, NetworkMode mode) =>
      Future.wait(services.map((s) => check(s, mode)));

  /// Address to open right now, falling back to the configured addresses
  /// before any probe has completed.
  String urlFor(Service s, NetworkMode mode) {
    final resolved = _status[s.id]?.resolvedUrl;
    if (resolved != null) return resolved;
    if (mode == NetworkMode.local && s.lanUrl.isNotEmpty) return s.lanUrl;
    return s.url.isNotEmpty ? s.url : s.lanUrl;
  }
}
