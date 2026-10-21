import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'host_edit_screen.dart';
import 'terminal_screen.dart';

class HostsScreen extends StatelessWidget {
  const HostsScreen({super.key, required this.store});
  final AppStore store;

  Future<void> _edit(BuildContext context, [SshHost? h]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => HostEditScreen(store: store, host: h)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TERMINAL')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context),
        tooltip: 'Add host',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.hosts.isEmpty) {
            return const EmptyState(
              icon: Icons.terminal,
              title: 'NO HOSTS',
              body: 'Tap + to add an SSH host.\nKey authentication is strongly '
                  'recommended for hosts reachable from the internet.',
            );
          }
          return ListView.separated(
            itemCount: store.hosts.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, i) {
              final h = store.hosts[i];
              return ListTile(
                leading: Icon(h.auth == AuthMethod.key ? Icons.key_outlined : Icons.password),
                title: Text(h.name),
                subtitle: Text(
                  '${h.username}@${h.host}:${h.port}',
                  style: const TextStyle(color: Mono.dim),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _edit(context, h),
                ),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => TerminalScreen(store: store, host: h)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
