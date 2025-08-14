import 'package:flutter/material.dart';
import 'package:front_2/widgets/pallet_quality_details.dart';

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
  int _page = 0; // página actual (0-based)
  static const int _pageSize = 10;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(BuildContext context, GateItem it) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PalletQualityDetails(
          dt: it.dt,
          cliente: it
              .origen, // usa "origen" como cliente (o cámbialo si tienes 'cliente' real)
          puerta: it.puerta,
        ),
      ),
    );
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

  int _pageCountFor(int total) {
    if (total <= 0) return 1;
    return (total + _pageSize - 1) ~/ _pageSize; // ceil
  }

  void _clampPage(int total) {
    final last = _pageCountFor(total) - 1;
    if (_page > last) _page = last.clamp(0, last);
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
        _clampPage(results.length); // asegura que la página exista

        // ---- Fix robusto: calculamos childAspectRatio en lugar de altura fija ----
        // Ancho real del tile considerando padding y gutters del Grid.
        const gridHPad = 16.0; // padding horizontal del GridView
        const gutter = 12.0; // spacing entre columnas
        final horizontalPadding = gridHPad * 2;
        final gutters = gutter * (crossAxisCount - 1);
        final tileWidth = (w - horizontalPadding - gutters) / crossAxisCount;

        // Altura mínima razonable de la card (según tipografía y compactación)
        final textScale = MediaQuery.textScaleFactorOf(context);
        final minCardHeight =
            (isXS ? 128.0 : 118.0) +
            (textScale - 1.0) * 24.0 +
            2.0; // +2px anti-redondeo
        final ratio = tileWidth / minCardHeight;

        // ---- Slice de la página actual ----
        final start = _page * _pageSize;
        final endExclusive = (start + _pageSize) > results.length
            ? results.length
            : (start + _pageSize);
        final pageItems = (results.isEmpty || start >= results.length)
            ? const <GateItem>[]
            : results.sublist(start, endExclusive);

        final totalPages = _pageCountFor(results.length);
        final showPager = results.isNotEmpty && totalPages > 1;

        return Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() {
                  _query = v;
                  _page = 0; // reset al filtrar
                }),
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
                            setState(() {
                              _query = '';
                              _page = 0;
                            });
                          },
                        ),
                ),
              ),
            ),

            // Contenido + Paginador
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
                  : Column(
                      children: [
                        // Grid paginado
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: pageItems.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: gutter,
                                  mainAxisSpacing: gutter,
                                  childAspectRatio:
                                      ratio, // evita desbordes por redondeo
                                ),

                            itemBuilder: (context, i) => _GateCard(
                              item: pageItems[i],
                              onTap: () => _openDetails(context, pageItems[i]),
                            ),
                          ),
                        ),

                        // Paginador responsiveS
                        if (showPager)
                          _PaginationBar(
                            page: _page,
                            totalPages: totalPages,
                            totalItems: results.length,
                            pageSize: _pageSize,
                            onFirst: _page > 0
                                ? () => setState(() => _page = 0)
                                : null,
                            onPrev: _page > 0
                                ? () => setState(() => _page -= 1)
                                : null,
                            onNext: _page < totalPages - 1
                                ? () => setState(() => _page += 1)
                                : null,
                            onLast: _page < totalPages - 1
                                ? () => setState(() => _page = totalPages - 1)
                                : null,
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/* ---------------------- Paginador (responsive) ---------------------- */

class _PaginationBar extends StatelessWidget {
  final int page; // 0-based
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onFirst;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onLast;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.onFirst,
    this.onPrev,
    this.onNext,
    this.onLast,
  });

  static int _fromItem(int page, int size, int total) {
    if (total == 0) return 0;
    return page * size + 1; // 1-based
  }

  static int _toItem(int page, int size, int total) {
    final end = (page + 1) * size;
    return end > total ? total : end;
  }

  @override
  Widget build(BuildContext context) {
    final pageHuman = page + 1;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isNarrow = w < 420; // breakpoint para apilar
        final isUltraNarrow = w < 340; // etiqueta más corta

        final rangeText = isUltraNarrow
            ? 'Pág $pageHuman/$totalPages · $totalItems'
            : 'Mostrando ${_fromItem(page, pageSize, totalItems)}–${_toItem(page, pageSize, totalItems)} de $totalItems';

        final infoText = Text(
          rangeText,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        );

        final controls = Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: isNarrow ? WrapAlignment.center : WrapAlignment.end,
          children: [
            IconButton.filledTonal(
              tooltip: 'Primera página',
              onPressed: onFirst,
              icon: const Icon(Icons.first_page),
            ),
            IconButton.filledTonal(
              tooltip: 'Anterior',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text('Página $pageHuman de $totalPages'),
            ),
            IconButton.filledTonal(
              tooltip: 'Siguiente',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton.filledTonal(
              tooltip: 'Última página',
              onPressed: onLast,
              icon: const Icon(Icons.last_page),
            ),
          ],
        );

        if (isNarrow) {
          // Columna en pantallas angostas
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: infoText),
                const SizedBox(height: 8),
                controls,
              ],
            ),
          );
        }

        // Fila en pantallas medias/anchas
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // que no desborde
              Expanded(child: infoText),
              const SizedBox(width: 12),
              controls,
            ],
          ),
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
  const _GateCard({required this.item, this.onTap});
  final GateItem item;
  final VoidCallback? onTap;

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
    final hoverTint = Color.alphaBlend(
      scheme.primary.withOpacity(0.05),
      baseColor,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
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
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: _hover ? hoverTint : baseColor,
          child: InkWell(
            onTap: widget.onTap,
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
                  const SizedBox(height: 8),

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
                  const SizedBox(height: 8),

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
  GateItem(dt: 'DT-1011', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1012', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1013', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1014', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1015', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1016', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1017', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1018', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1019', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1020', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1021', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1022', origen: 'Bodega Oeste', puerta: 'E4'),
  GateItem(dt: 'DT-1023', origen: 'Bodega Oeste', puerta: 'E4'),
];
