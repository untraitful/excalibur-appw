import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'health.dart';
import 'screens/hosts_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';
import 'store.dart';
import 'theme.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    // Release builds otherwise render failed widgets as an empty box.
    ErrorWidget.builder = (details) => _ErrorView(details.exceptionAsString());
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Mono.black,
        systemNavigationBarColor: Mono.black,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    // Draw a frame immediately; load state behind it.
    runApp(const ExcaliburApp());
  }, (error, stack) => debugPrint('Uncaught: $error\n$stack'));
}

class ExcaliburApp extends StatefulWidget {
  const ExcaliburApp({super.key, this.store});

  /// Preloaded store, for tests.
  final AppStore? store;

  @override
  State<ExcaliburApp> createState() => _ExcaliburAppState();
}

class _ExcaliburAppState extends State<ExcaliburApp> {
  late final Future<AppStore> _store = widget.store != null
      ? Future.value(widget.store)
      : AppStore.load().timeout(const Duration(seconds: 10));
  final _health = HealthMonitor();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excalibur',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: FutureBuilder<AppStore>(
        future: _store,
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorView('${snap.error}\n\n${snap.stackTrace}');
          }
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(
                child: Text('EXCALIBUR', style: TextStyle(letterSpacing: 6)),
              ),
            );
          }
          return HomeShell(store: snap.data!, health: _health);
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  _ErrorView(this.message) {
    // Also log it, so the emulator smoke test can detect a startup failure.
    debugPrint('EXCALIBUR_ERROR: $message');
  }
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Mono.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'ERROR\n\n$message',
            style: const TextStyle(
              color: Mono.white,
              fontFamily: Mono.font,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store, required this.health});

  final AppStore store;
  final HealthMonitor health;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ServicesScreen(store: widget.store, health: widget.health),
      HostsScreen(store: widget.store),
      SettingsScreen(store: widget.store, health: widget.health),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Mono.line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view),
              label: 'SERVICES',
            ),
            NavigationDestination(
              icon: Icon(Icons.terminal),
              label: 'TERMINAL',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}
