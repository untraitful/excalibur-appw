import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'health.dart';
import 'screens/hosts_screen.dart';
import 'screens/services_screen.dart';
import 'screens/settings_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Mono.black,
    systemNavigationBarColor: Mono.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final store = await AppStore.load();
  runApp(ExcaliburApp(store: store, health: HealthMonitor()));
}

class ExcaliburApp extends StatelessWidget {
  const ExcaliburApp({super.key, required this.store, required this.health});

  final AppStore store;
  final HealthMonitor health;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excalibur',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeShell(store: store, health: health),
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
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'SERVICES'),
            NavigationDestination(icon: Icon(Icons.terminal), label: 'TERMINAL'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}
