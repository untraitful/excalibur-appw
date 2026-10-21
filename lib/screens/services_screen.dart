import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../health.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'service_edit_screen.dart';
import 'webview_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, required this.store, required this.health});
  final AppStore store;
  final HealthMonitor health;

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with WidgetsBindingObserver {
  Timer? _timer;
  String _filter = '';

  AppStore get store => widget.store;
  HealthMonitor get health => widget.health;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Network may have changed (wifi <-> mobile) while in the background.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() => health.checkAll(store.services, store.networkMode);

  Future<void> _open(Service s) async {
    final url = health.urlFor(s, store.networkMode);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      toast(context, 'Invalid URL: $url');
      return;
    }
    if (s.openExternal) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WebViewScreen(title: s.name, url: url)),
      );
    }
  }

  Future<void> _edit([Service? s]) async {
    final result = await Navigator.push<Service>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceEditScreen(service: s, categories: store.categories),
      ),
    );
    if (result != null) {
      await store.upsertService(result);
      unawaited(health.check(result, store.networkMode));
    }
  }

  void _actions(Service s) {
    final url = health.urlFor(s, store.networkMode);
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.name, style: const TextStyle(letterSpacing: 1)),
              subtitle: Text(url, style: const TextStyle(color: Mono.dim)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(c);
                _edit(s);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open in browser'),
              onTap: () {
                Navigator.pop(c);
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(c);
                Clipboard.setData(ClipboardData(text: url));
                toast(context, 'Copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(c);
                if (await confirm(context, 'Delete ${s.name}?', 'This cannot be undone.')) {
                  await store.deleteService(s);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXCALIBUR'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh, tooltip: 'Check all'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        tooltip: 'Add service',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, health]),
        builder: (context, _) {
          if (store.services.isEmpty) {
            return const EmptyState(
              icon: Icons.grid_view,
              title: 'NO SERVICES',
              body: 'Tap + to add a link to a service in your homelab.\n'
                  'Settings > Import restores a backup.',
            );
          }
          final q = _filter.toLowerCase();
          final visible = store.services
              .where((s) => q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  s.category.toLowerCase().contains(q))
              .toList();
          final up = store.services
              .where((s) => health.statusOf(s).health == Health.up)
              .length;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: Mono.black,
            backgroundColor: Mono.white,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              onChanged: (v) => setState(() => _filter = v),
                              decoration: const InputDecoration(
                                hintText: 'filter',
                                prefixIcon: Icon(Icons.search, size: 18),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text('$up/${store.services.length} UP',
                            style: const TextStyle(letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
                for (final cat in {for (final s in visible) s.category}) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(cat.toUpperCase(),
                          style: const TextStyle(color: Mono.dim, letterSpacing: 3, fontSize: 12)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.extent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.35,
                      children: [
                        for (final s in visible.where((s) => s.category == cat))
                          _ServiceTile(
                            service: s,
                            status: health.statusOf(s),
                            onTap: () => _open(s),
                            onLongPress: () => _actions(s),
                          ),
                      ],
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.status,
    required this.onTap,
    required this.onLongPress,
  });

  final Service service;
  final ServiceStatus status;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final down = status.health == Health.down;
    final label = switch (status.health) {
      Health.up => '${status.viaLan ? 'LAN' : 'WAN'} ${status.ms}ms',
      Health.degraded => 'ERROR',
      Health.down => 'OFFLINE',
      Health.checking => '...',
      Health.unknown => '',
    };
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconFor(service.icon), color: down ? Mono.dim : Mono.white),
                  const Spacer(),
                  StatusDot(status.health),
                ],
              ),
              const Spacer(),
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: down ? Mono.dim : Mono.white),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10, color: Mono.dim, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
