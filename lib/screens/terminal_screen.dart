import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../models.dart';
import '../store.dart';
import '../terminal_keys.dart';
import '../theme.dart';

enum _Conn { connecting, connected, closed }

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.store, required this.host});
  final AppStore store;
  final SshHost host;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _terminal = Terminal(maxLines: 10000);
  final _termController = TerminalController();
  SSHClient? _client;
  SSHSession? _session;
  _Conn _state = _Conn.connecting;
  bool _ctrl = false;
  bool _alt = false;
  double _fontSize = 13;

  SshHost get host => widget.host;

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) {
      final out = applyModifiers(data, ctrl: _ctrl, alt: _alt);
      if (_ctrl || _alt) setState(() => _ctrl = _alt = false);
      _session?.write(Uint8List.fromList(utf8.encode(out)));
    };
    _terminal.onResize = (w, h, pw, ph) =>
        _session?.resizeTerminal(w, h, pw, ph);
    _connect();
  }

  @override
  void dispose() {
    _session?.close();
    _client?.close();
    _termController.dispose();
    super.dispose();
  }

  void _status(String msg) => _terminal.write('\x1b[2m$msg\x1b[0m\r\n');

  Future<void> _connect() async {
    setState(() => _state = _Conn.connecting);
    _status('connecting to ${host.username}@${host.host}:${host.port} ...');
    try {
      final secrets = await widget.store.loadSecrets(host.id);
      final socket = await SSHSocket.connect(
        host.host,
        host.port,
        timeout: const Duration(seconds: 10),
      );
      final client = SSHClient(
        socket,
        username: host.username,
        onVerifyHostKey: _verifyHostKey,
        identities: host.auth == AuthMethod.key && secrets.privateKey.isNotEmpty
            ? SSHKeyPair.fromPem(
                secrets.privateKey,
                secrets.passphrase.isEmpty ? null : secrets.passphrase,
              )
            : null,
        onPasswordRequest: secrets.password.isNotEmpty
            ? () => secrets.password
            : null,
        onUserauthBanner: (b) => _terminal.write(b.replaceAll('\n', '\r\n')),
      );
      _client = client;
      await client.authenticated;

      final session = await client.shell(
        pty: SSHPtyConfig(
          type: 'xterm-256color',
          width: _terminal.viewWidth,
          height: _terminal.viewHeight,
        ),
      );
      _session = session;
      if (!mounted) return;
      setState(() => _state = _Conn.connected);

      session.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);
      session.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(_terminal.write);

      if (host.startupCommand.isNotEmpty) {
        session.write(
          Uint8List.fromList(utf8.encode('${host.startupCommand}\n')),
        );
      }

      await session.done;
      _closed('session ended');
    } catch (e) {
      _closed('error: $e');
    }
  }

  void _closed(String reason) {
    _session = null;
    _client?.close();
    _client = null;
    if (!mounted) return;
    _status('\r\n[$reason]');
    setState(() => _state = _Conn.closed);
  }

  /// Trust on first use. A changed key is treated as a possible MITM.
  Future<bool> _verifyHostKey(String type, Uint8List fp) async {
    final fingerprint = utf8.decode(fp);
    if (host.fingerprint == fingerprint) return true;
    if (!mounted) return false;
    final changed = host.fingerprint.isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(changed ? 'HOST KEY CHANGED' : 'UNKNOWN HOST'),
        content: SelectableText(
          changed
              ? 'The host key for ${host.host} does not match the trusted key.\n\n'
                    'This could mean someone is intercepting the connection, or the '
                    'server was reinstalled.\n\n'
                    'Trusted:\n${host.fingerprint}\n\nReceived ($type):\n$fingerprint'
              : 'First connection to ${host.host}. Verify the fingerprint matches '
                    'the server (ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub):\n\n'
                    '$type\n$fingerprint',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('REJECT'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(changed ? 'TRUST NEW KEY' : 'TRUST'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.trustFingerprint(host, fingerprint);
      return true;
    }
    return false;
  }

  void _key(TerminalKey key) {
    final ctrl = _ctrl, alt = _alt;
    // Clear first so onOutput does not apply the modifiers a second time.
    if (ctrl || alt) setState(() => _ctrl = _alt = false);
    _terminal.keyInput(key, ctrl: ctrl, alt: alt);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) _terminal.paste(text);
  }

  void _copy() {
    final sel = _termController.selection;
    if (sel == null) return;
    Clipboard.setData(ClipboardData(text: _terminal.buffer.getText(sel)));
    _termController.clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(host.name.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize - 1).clamp(8, 24)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () =>
                setState(() => _fontSize = (_fontSize + 1).clamp(8, 24)),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copy,
            tooltip: 'Copy selection',
          ),
          if (_state == _Conn.closed)
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: _connect,
              tooltip: 'Reconnect',
            )
          else if (_state == _Conn.connecting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TerminalView(
                _terminal,
                controller: _termController,
                theme: monoTerminalTheme,
                textStyle: TerminalStyle(
                  fontSize: _fontSize,
                  fontFamily: Mono.font,
                ),
                padding: const EdgeInsets.all(4),
                autofocus: true,
                keyboardType: TextInputType.visiblePassword,
                deleteDetection: true,
              ),
            ),
            _ExtraKeys(
              ctrl: _ctrl,
              alt: _alt,
              onCtrl: () => setState(() => _ctrl = !_ctrl),
              onAlt: () => setState(() => _alt = !_alt),
              onKey: _key,
              onText: (t) => _terminal.textInput(t),
              onPaste: _paste,
            ),
          ],
        ),
      ),
    );
  }
}

/// Keys missing from phone keyboards. CTRL and ALT are sticky for one press.
class _ExtraKeys extends StatelessWidget {
  const _ExtraKeys({
    required this.ctrl,
    required this.alt,
    required this.onCtrl,
    required this.onAlt,
    required this.onKey,
    required this.onText,
    required this.onPaste,
  });

  final bool ctrl;
  final bool alt;
  final VoidCallback onCtrl;
  final VoidCallback onAlt;
  final void Function(TerminalKey) onKey;
  final void Function(String) onText;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap, {bool active = false}) =>
        InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44),
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active ? Mono.white : null,
              border: const Border(right: BorderSide(color: Mono.line)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Mono.black : Mono.white,
                fontSize: 13,
              ),
            ),
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Mono.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            key('ESC', () => onKey(TerminalKey.escape)),
            key('TAB', () => onKey(TerminalKey.tab)),
            key('CTRL', onCtrl, active: ctrl),
            key('ALT', onAlt, active: alt),
            key('←', () => onKey(TerminalKey.arrowLeft)),
            key('↑', () => onKey(TerminalKey.arrowUp)),
            key('↓', () => onKey(TerminalKey.arrowDown)),
            key('→', () => onKey(TerminalKey.arrowRight)),
            for (final c in ['|', '-', '/', '~', ':']) key(c, () => onText(c)),
            key('HOME', () => onKey(TerminalKey.home)),
            key('END', () => onKey(TerminalKey.end)),
            key('PGUP', () => onKey(TerminalKey.pageUp)),
            key('PGDN', () => onKey(TerminalKey.pageDown)),
            key('PASTE', onPaste),
          ],
        ),
      ),
    );
  }
}
