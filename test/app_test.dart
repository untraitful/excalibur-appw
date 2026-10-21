import 'package:excalibur/models.dart';
import 'package:excalibur/terminal_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyModifiers', () {
    test('ctrl maps letters to control codes', () {
      expect(applyModifiers('c', ctrl: true, alt: false), '\x03');
      expect(applyModifiers('C', ctrl: true, alt: false), '\x03');
      expect(applyModifiers('[', ctrl: true, alt: false), '\x1b');
    });
    test('alt prefixes escape', () {
      expect(applyModifiers('b', ctrl: false, alt: true), '\x1bb');
    });
    test('multi-char text is untouched', () {
      expect(applyModifiers('ls', ctrl: true, alt: true), 'ls');
    });
  });

  test('service json round-trip', () {
    final s = Service(
      name: 'Jellyfin',
      url: 'https://j.example.com',
      lanUrl: 'http://10.0.0.2:8096',
    );
    final r = Service.fromJson(s.toJson());
    expect(r.id, s.id);
    expect(r.lanUrl, s.lanUrl);
  });

  test('host json never contains secrets', () {
    final h = SshHost(name: 'pve', host: 'ssh.example.com', username: 'root');
    final j = h.toJson();
    expect(j.keys, isNot(contains('password')));
    expect(SshHost.fromJson(j).auth, AuthMethod.key);
  });
}
