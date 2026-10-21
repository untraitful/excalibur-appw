import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class ServiceEditScreen extends StatefulWidget {
  const ServiceEditScreen({super.key, this.service, required this.categories});
  final Service? service;
  final List<String> categories;

  @override
  State<ServiceEditScreen> createState() => _ServiceEditScreenState();
}

class _ServiceEditScreenState extends State<ServiceEditScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.service?.name);
  late final _url = TextEditingController(text: widget.service?.url);
  late final _lan = TextEditingController(text: widget.service?.lanUrl);
  late final _cat = TextEditingController(text: widget.service?.category ?? 'General');
  late String _icon = widget.service?.icon ?? 'web';
  late bool _external = widget.service?.openExternal ?? false;

  @override
  void dispose() {
    for (final c in [_name, _url, _lan, _cat]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _validateUrl(String? v, {required bool required}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return required ? 'Required' : null;
    final u = Uri.tryParse(t);
    if (u == null || !(u.isScheme('http') || u.isScheme('https')) || u.host.isEmpty) {
      return 'Must start with http:// or https://';
    }
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final s = Service(
      id: widget.service?.id,
      name: _name.text.trim(),
      url: _url.text.trim(),
      lanUrl: _lan.text.trim(),
      category: _cat.text.trim().isEmpty ? 'General' : _cat.text.trim(),
      icon: _icon,
      openExternal: _external,
    );
    Navigator.pop(context, s);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service == null ? 'ADD SERVICE' : 'EDIT SERVICE'),
        actions: [TextButton(onPressed: _save, child: const Text('SAVE'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            gap,
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Public URL',
                hintText: 'https://jellyfin.example.com',
              ),
              // Either address is enough, but at least one is needed.
              validator: (v) => _validateUrl(v, required: _lan.text.trim().isEmpty),
            ),
            gap,
            TextFormField(
              controller: _lan,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'LAN URL (optional)',
                hintText: 'http://192.168.1.20:8096',
                helperText: 'Used automatically when reachable',
                helperStyle: TextStyle(color: Mono.dim),
              ),
              validator: (v) => _validateUrl(v, required: false),
            ),
            gap,
            TextFormField(
              controller: _cat,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in widget.categories)
                    ActionChip(
                      label: Text(c),
                      shape: const RoundedRectangleBorder(),
                      onPressed: () => setState(() => _cat.text = c),
                    ),
                ],
              ),
            ],
            gap,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open in external browser'),
              subtitle: const Text(
                'For services that need passkeys, downloads or SSO the in-app viewer cannot handle',
                style: TextStyle(color: Mono.dim, fontSize: 12),
              ),
              value: _external,
              onChanged: (v) => setState(() => _external = v),
            ),
            gap,
            const Text('ICON', style: TextStyle(color: Mono.dim, letterSpacing: 3, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in serviceIcons.entries)
                  InkWell(
                    onTap: () => setState(() => _icon = e.key),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _icon == e.key ? Mono.white : null,
                        border: Border.all(color: _icon == e.key ? Mono.white : Mono.line),
                      ),
                      child: Icon(e.value, color: _icon == e.key ? Mono.black : Mono.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
