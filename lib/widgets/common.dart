import 'package:flutter/material.dart';

import '../health.dart';
import '../theme.dart';

/// Status indicator: filled square = up, hollow = down, half = degraded.
class StatusDot extends StatelessWidget {
  const StatusDot(this.health, {super.key});
  final Health health;

  @override
  Widget build(BuildContext context) {
    if (health == Health.checking) {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(
          color: health == Health.unknown ? Mono.line : Mono.white,
        ),
        color: health == Health.up ? Mono.white : null,
        gradient: health == Health.degraded
            ? const LinearGradient(
                colors: [Mono.white, Mono.white, Mono.black, Mono.black],
                stops: [0, .5, .5, 1],
              )
            : null,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Mono.dim)),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String body,
    {String action = 'DELETE'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
      ],
    ),
  );
  return ok ?? false;
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
