import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../health.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store, required this.health});
  final AppStore store;
  final HealthMonitor health;

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    controller.text = clip?.text ?? '';
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('IMPORT'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            style: const TextStyle(fontSize: 11),
            decoration: const InputDecoration(hintText: 'Paste exported JSON'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('REPLACE ALL'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await store.importJson(controller.text);
      await health.checkAll(store.services, store.networkMode);
      if (context.mounted) {
        toast(
          context,
          'Imported ${store.services.length} services, ${store.hosts.length} hosts',
        );
      }
    } catch (e) {
      if (context.mounted) toast(context, 'Import failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(color: Mono.dim, letterSpacing: 3, fontSize: 12);
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('NETWORK', style: header),
            ),
            RadioGroup<NetworkMode>(
              groupValue: store.networkMode,
              onChanged: (m) async {
                if (m == null) return;
                await store.setNetworkMode(m);
                await health.checkAll(store.services, m);
              },
              child: const Column(
                children: [
                  RadioListTile(
                    value: NetworkMode.auto,
                    title: Text('Auto'),
                    subtitle: Text(
                      'Use LAN URL when it answers, otherwise public URL',
                      style: TextStyle(color: Mono.dim, fontSize: 12),
                    ),
                  ),
                  RadioListTile(
                    value: NetworkMode.remote,
                    title: Text('Always public'),
                    subtitle: Text(
                      'Ignore LAN URLs',
                      style: TextStyle(color: Mono.dim, fontSize: 12),
                    ),
                  ),
                  RadioListTile(
                    value: NetworkMode.local,
                    title: Text('Always LAN'),
                    subtitle: Text(
                      'Prefer LAN URLs even if unreachable',
                      style: TextStyle(color: Mono.dim, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('BACKUP', style: header),
            ),
            ListTile(
              leading: const Icon(Icons.upload_outlined),
              title: const Text('Export to clipboard'),
              subtitle: const Text(
                'Services and hosts as JSON. Passwords and keys are not included.',
                style: TextStyle(color: Mono.dim, fontSize: 12),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: store.exportJson()));
                toast(context, 'Copied to clipboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Import from clipboard'),
              subtitle: const Text(
                'Replaces current services and hosts',
                style: TextStyle(color: Mono.dim, fontSize: 12),
              ),
              onTap: () => _import(context),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('ABOUT', style: header),
            ),
            const ListTile(
              title: Text('Excalibur'),
              subtitle: Text(
                'Homelab dashboard and SSH terminal. Reaches your services directly '
                'over the public internet or LAN, with no VPN client required. '
                'See the README for exposing services safely.',
                style: TextStyle(color: Mono.dim, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
