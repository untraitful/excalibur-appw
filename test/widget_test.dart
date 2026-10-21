import 'dart:convert';

import 'package:excalibur/main.dart';
import 'package:excalibur/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dashboard renders services and tabs', (tester) async {
    SharedPreferences.setMockInitialValues({
      'services': jsonEncode([
        {
          'name': 'Proxmox',
          'url': 'https://pve.example.com',
          'category': 'Infra',
          'icon': 'server',
        },
        {
          'name': 'Jellyfin',
          'url': 'https://jf.example.com',
          'category': 'Media',
          'icon': 'media',
        },
      ]),
    });
    final store = await AppStore.load();
    await tester.pumpWidget(ExcaliburApp(store: store));
    await tester.pump();
    await tester.pump();

    expect(find.text('Proxmox'), findsOneWidget);
    expect(find.text('MEDIA'), findsOneWidget);

    await tester.tap(find.text('TERMINAL'));
    await tester.pumpAndSettle();
    expect(find.text('NO HOSTS'), findsOneWidget);
  });
}
