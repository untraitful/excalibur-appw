import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HostEditScreen extends StatefulWidget {
  const HostEditScreen({super.key, required this.store, this.host});
  final AppStore store;
  final SshHost? host;

  @override
  State<HostEditScreen> createState() => _HostEditScreenState();
}

class _HostEditScreenState extends State<HostEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.host?.name);
  late final _host = TextEditingController(text: widget.host?.host);
  late final _port = TextEditingController(text: '${widget.host?.port ?? 22}');
  late final _user = TextEditingController(text: widget.host?.username);
  late final _startup = TextEditingController(
    text: widget.host?.startupCommand,
  );
  final _password = TextEditingController();
  final _key = TextEditingController();
  final _passphrase = TextEditingController();
  late AuthMethod _auth = widget.host?.auth ?? AuthMethod.key;
  late String _fingerprint = widget.host?.fingerprint ?? '';
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (widget.host != null) {
      widget.store.loadSecrets(widget.host!.id).then((s) {
        if (!mounted) return;
        _password.text = s.password;
        _key.text = s.privateKey;
        _passphrase.text = s.passphrase;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _host,
      _port,
      _user,
      _startup,
      _password,
      _key,
      _passphrase,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateKey(String? v) {
    if (_auth != AuthMethod.key) return null;
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Paste a private key (OpenSSH or PEM)';
    try {
      SSHKeyPair.fromPem(t, _passphrase.text.isEmpty ? null : _passphrase.text);
    } catch (e) {
      return 'Could not parse key: $e';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final h = SshHost(
      id: widget.host?.id,
      name: _name.text.trim().isEmpty ? _host.text.trim() : _name.text.trim(),
      host: _host.text.trim(),
      port: int.parse(_port.text.trim()),
      username: _user.text.trim(),
      auth: _auth,
      fingerprint: _fingerprint,
      startupCommand: _startup.text.trim(),
    );
    await widget.store.upsertHost(
      h,
      secrets: SshSecrets(
        password: _password.text,
        privateKey: _auth == AuthMethod.key ? _key.text.trim() : '',
        passphrase: _auth == AuthMethod.key ? _passphrase.text : '',
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final h = widget.host!;
    if (await confirm(
      context,
      'Delete ${h.name}?',
      'Stored credentials are erased too.',
    )) {
      await widget.store.deleteHost(h);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final secretToggle = IconButton(
      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host == null ? 'ADD HOST' : 'EDIT HOST'),
        actions: [
          if (widget.host != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(onPressed: _save, child: const Text('SAVE')),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'proxmox',
              ),
            ),
            gap,
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _host,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      hintText: 'ssh.example.com',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _port,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Port'),
                    validator: (v) {
                      final p = int.tryParse((v ?? '').trim());
                      return p == null || p < 1 || p > 65535 ? '1-65535' : null;
                    },
                  ),
                ),
              ],
            ),
            gap,
            TextFormField(
              controller: _user,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            gap,
            SegmentedButton<AuthMethod>(
              style: SegmentedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                selectedBackgroundColor: Mono.white,
                selectedForegroundColor: Mono.black,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: AuthMethod.key,
                  label: Text('PRIVATE KEY'),
                ),
                ButtonSegment(
                  value: AuthMethod.password,
                  label: Text('PASSWORD'),
                ),
              ],
              selected: {_auth},
              onSelectionChanged: (s) => setState(() => _auth = s.first),
            ),
            gap,
            if (_auth == AuthMethod.key) ...[
              TextFormField(
                controller: _key,
                maxLines: 6,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(
                  labelText: 'Private key',
                  hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                  alignLabelWithHint: true,
                ),
                validator: _validateKey,
              ),
              gap,
              TextFormField(
                controller: _passphrase,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Key passphrase (if any)',
                  suffixIcon: secretToggle,
                ),
              ),
            ] else
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: secretToggle,
                ),
              ),
            gap,
            TextFormField(
              controller: _startup,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Run on connect (optional)',
                hintText: 'tmux new -A -s main',
              ),
            ),
            gap,
            Text(
              _fingerprint.isEmpty
                  ? 'HOST KEY: not yet trusted. You will be asked on first connect.'
                  : 'HOST KEY: $_fingerprint',
              style: const TextStyle(color: Mono.dim, fontSize: 12),
            ),
            if (_fingerprint.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _fingerprint = ''),
                  child: const Text('FORGET HOST KEY'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
