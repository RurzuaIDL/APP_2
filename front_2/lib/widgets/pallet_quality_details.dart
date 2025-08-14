import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PalletQualityDetails extends StatefulWidget {
  const PalletQualityDetails({
    super.key,
    required this.dt,
    required this.cliente,
    required this.puerta,
  });

  final String dt;
  final String cliente;
  final String puerta;

  @override
  State<PalletQualityDetails> createState() => _PalletQualityDetailsState();
}

class _PalletQualityDetailsState extends State<PalletQualityDetails> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _loading = true;
  bool _saving = false;

  static const List<String> _incidencias = [
    'Sin incidencia',
    'Embalaje dañado',
    'Humedad alta',
    'Etiquetado ilegible',
    'Faltante',
    'Golpes visibles',
  ];

  late List<_RowData> _rows;
  final List<File> _photos = [];

  String get _prefsKey => 'pallet_quality_${widget.dt}';

  @override
  void initState() {
    super.initState();
    _loadOrSeed();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.camadaCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOrSeed() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_prefsKey);

    if (raw != null) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final List items = (m['items'] ?? []) as List;

      _rows = items.map<_RowData>((e) {
        final sku = e['sku']?.toString() ?? '';
        final inc = e['incidencia']?.toString() ?? _incidencias.first;
        final camada = (e['camada'] ?? 0).toString();
        return _RowData(
          sku: sku,
          incidencia: _incidencias.contains(inc) ? inc : _incidencias.first,
          camadaCtrl: TextEditingController(text: camada),
        );
      }).toList();

      final List paths = (m['photos'] ?? []) as List;
      for (final p in paths) {
        final f = File(p as String);
        if (await f.exists()) _photos.add(f);
      }
    } else {
      final digits = widget.dt.replaceAll(RegExp(r'[^0-9]'), '');
      _rows = List.generate(10, (i) {
        final n = (i + 1).toString().padLeft(2, '0');
        return _RowData(
          sku: 'SKU-$digits-$n',
          incidencia: _incidencias.first,
          camadaCtrl: TextEditingController(text: '1'),
        );
      });
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (x == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/pallet_quality/${widget.dt}');
      await dir.create(recursive: true);
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await File(x.path).copy('${dir.path}/$fileName');

      if (!mounted) return;
      setState(() => _photos.add(saved));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imagen agregada')));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir cámara/galería: ${e.code}')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final items = _rows.map((r) {
        final camada = int.tryParse(r.camadaCtrl.text.trim()) ?? 0;
        return {'sku': r.sku, 'incidencia': r.incidencia, 'camada': camada};
      }).toList();

      final data = {
        'dt': widget.dt,
        'cliente': widget.cliente,
        'puerta': widget.puerta,
        'items': items,
        'photos': _photos.map((f) => f.path).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey, jsonEncode(data));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardado local')));
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Detalle de calidad · ${widget.dt}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Identificación (DT + Cliente + Puerta)
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 520;
                    final info = [
                      _InfoTile(
                        icon: Icons.confirmation_number_outlined,
                        label: 'DT',
                        value: widget.dt,
                      ),
                      _InfoTile(
                        icon: Icons.person_outline,
                        label: 'Cliente',
                        value: widget.cliente,
                      ),
                      _InfoTile(
                        icon: Icons.door_front_door_outlined,
                        label: 'Puerta',
                        value: widget.puerta,
                      ),
                    ];
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: info
                            .map(
                              (w) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: w,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: info[0]),
                        const SizedBox(width: 12),
                        Expanded(child: info[1]),
                        const SizedBox(width: 12),
                        Expanded(child: info[2]),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Cabecera de tabla
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: _HeaderRow(),
              ),
            ),
            const SizedBox(height: 8),

            // Filas
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, i) => _DataRowWidget(
                    index: i,
                    data: _rows[i],
                    incidencias: _incidencias,
                    onChangedIncidencia: (val) =>
                        setState(() => _rows[i].incidencia = val),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Fotos
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _photos.isEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fotos', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text('Sin fotos. Usa “Agregar foto” abajo.'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fotos (${_photos.length})',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _photos.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemBuilder: (ctx, i) {
                              final f = _photos[i];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(f, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: IconButton(
                                        iconSize: 18,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () =>
                                            setState(() => _photos.removeAt(i)),
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        tooltip: 'Quitar',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 96), // espacio para footer
          ],
        ),
      ),

      // Footer
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _showAddMenu,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Agregar foto'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: const Text('Finalizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ====== Auxiliares ====== */

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: t.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: t.titleSmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Header y filas (versión responsive sin overflow) ----

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final narrow = w < 420;
        final h = Theme.of(context).textTheme.labelLarge;

        if (narrow) {
          return Row(
            children: [
              const SizedBox(width: 28, child: Text('#')),
              const SizedBox(width: 8),
              Expanded(flex: 6, child: Text('SKU', style: h)),
              const SizedBox(width: 8),
              Expanded(flex: 6, child: Text('Incidencia', style: h)),
              const SizedBox(width: 8),
              SizedBox(width: 72, child: Text('Cam.', style: h)),
            ],
          );
        }

        return Row(
          children: [
            const SizedBox(width: 28, child: Text('#')),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: Text('SKU', style: h)),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: Text('Incidencia', style: h)),
            const SizedBox(width: 12),
            SizedBox(width: 88, child: Text('N° camada', style: h)),
          ],
        );
      },
    );
  }
}

class _DataRowWidget extends StatelessWidget {
  const _DataRowWidget({
    required this.index,
    required this.data,
    required this.incidencias,
    required this.onChangedIncidencia,
  });

  final int index;
  final _RowData data;
  final List<String> incidencias;
  final ValueChanged<String> onChangedIncidencia;

  InputDecoration get _dec => const InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    border: OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final narrow = w < 420;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(width: 28, child: Text('${index + 1}')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: data.sku,
                      readOnly: true,
                      decoration: _dec,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: data.incidencia,
                      items: incidencias
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          onChangedIncidencia(v ?? incidencias.first),
                      decoration: _dec,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: TextFormField(
                      controller: data.camadaCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec,
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Pos';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(width: 28, child: Text('${index + 1}')),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: TextFormField(
                initialValue: data.sku,
                readOnly: true,
                decoration: _dec,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: data.incidencia,
                items: incidencias
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => onChangedIncidencia(v ?? incidencias.first),
                decoration: _dec,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: TextFormField(
                controller: data.camadaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _dec,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Pos';
                  return null;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RowData {
  _RowData({
    required this.sku,
    required this.incidencia,
    required this.camadaCtrl,
  });

  final String sku;
  String incidencia;
  final TextEditingController camadaCtrl;
}
