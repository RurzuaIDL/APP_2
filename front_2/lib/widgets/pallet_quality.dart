import 'package:flutter/material.dart';

class GateSearchGrid extends StatefulWidget {
  const GateSearchGrid({
    super.key,
    this.items = demoGateItems, // 10 demo items por defecto
  });

  final List<GateItem> items;

  @override
  State<GateSearchGrid> createState() => _GateSearchGridState();
}

class _GateSearchGridState extends State<GateSearchGrid> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<GateItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((e) {
      return e.dt.toLowerCase().contains(q) ||
          e.origen.toLowerCase().contains(q) ||
          e.puerta.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isXS = w < 480;
        final isSM = w >= 480 && w < 720;
        final crossAxisCount = w >= 960 ? 4 : (w >= 720 ? 3 : (isSM ? 2 : 1));

        final results = _filtered;

        // ---- Fix robusto: calculamos childAspectRatio en lugar de altura fija ----
        // Ancho real del tile considerando padding y gutters del Grid.
        const gridHPad = 16.0; // padding horizontal del GridView
        const gutter = 12.0;   // spacing entre columnas
        final horizontalPadding = gridHPad * 2;
        final gutters = gutter * (crossAxisCount - 1);
        final tileWidth = (w - horizontalPadding - gutters) / crossAxisCount;

        // Altura mínima razonable de la card (según tipografía y compactación)
        final textScale = MediaQuery.textScaleFactorOf(context);
        final minCardHeight =
            (isXS ? 128.0 : 118.0) + (textScale - 1.0) * 24.0 + 2.0; // +2px anti-redondeo
        final ratio = tileWidth / minCardHeight;

        return Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar por DT, Origen o Puerta...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Sin resultados',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Intenta con otro término de búsqueda.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: results.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: gutter,
                        mainAxisSpacing: gutter,
                        childAspectRatio: ratio, // <-- evita desbordes por redondeo
                      ),
                      itemBuilder: (context, i) => _GateCard(item: results[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/* ---------------------- Model ---------------------- */

class GateItem {
  const GateItem({
    required this.dt,
    required this.origen,
    required this.puerta,
  });

  final String dt; // Número DT
  final String origen; // Origen
  final String puerta; // Puerta
}

/* ---------------------- Card (con hover) ---------------------- */

class _GateCard extends StatefulWidget {
  const _GateCard({required this.item});

  final GateItem item;

  @override
  State<_GateCard> createState() => _GateCardState();
}

class _GateCardState extends State<_GateCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baseColor = theme.cardColor;
    final hoverTint = Color.alphaBlend(scheme.primary.withOpacity(0.05), baseColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hover ? -2.0 : 0.0)
          ..scale(_hover ? 1.01 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Card(
          elevation: 0, // la sombra la maneja el AnimatedContainer
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: _hover ? hoverTint : baseColor,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DT
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'DT: ${widget.item.dt}',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Origen
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.item.origen,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Puerta
                Row(
                  children: [
                    const Icon(Icons.door_front_door_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Puerta ${widget.item.puerta}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------- Demo data (10) ---------------------- */

const demoGateItems = <GateItem>[
  GateItem(dt: 'DT-1001', origen: 'Bodega Norte', puerta: 'A1'),
  GateItem(dt: 'DT-1002', origen: 'Bodega Sur', puerta: 'B3'),
  GateItem(dt: 'DT-1003', origen: 'Puerto Central', puerta: 'C2'),
  GateItem(dt: 'DT-1004', origen: 'Bodega Este', puerta: 'D4'),
  GateItem(dt: 'DT-1005', origen: 'Zona Franca', puerta: 'E1'),
  GateItem(dt: 'DT-1006', origen: 'Terminal 1', puerta: 'A3'),
  GateItem(dt: 'DT-1007', origen: 'Terminal 2', puerta: 'B1'),
  GateItem(dt: 'DT-1008', origen: 'Puerto Seco', puerta: 'C5'),
  GateItem(dt: 'DT-1009', origen: 'Depósito Central', puerta: 'D2'),
  GateItem(dt: 'DT-1010', origen: 'Bodega Oeste', puerta: 'E4'),
];
