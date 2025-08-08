import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final kpis = const [
      _KpiData(title: 'Usuarios', value: '1,248', delta: '+3.2%'),
      _KpiData(title: 'Ventas', value: '\$12.4k', delta: '+1.1%'),
      _KpiData(title: 'Tickets', value: '87', delta: '-4.0%'),
      _KpiData(title: 'Conversión', value: '2.7%', delta: '+0.3%'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 1000;
        final isTablet = c.maxWidth > 700 && c.maxWidth <= 1000;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 KPIs
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kpis.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : (isTablet ? 3 : 2),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 14 / 6,
                ),
                itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
              ),
              const SizedBox(height: 16),

              // 🔹 “Sparkline” + Progreso
              Flex(
                direction: isTablet || isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _SectionCard(
                      title: 'Tráfico últimos 7 días',
                      child: const _MiniSparkline(values: [8, 12, 10, 14, 18, 13, 20]),
                    ),
                  ),
                  const SizedBox(width: 16, height: 16),
                  Expanded(
                    child: _SectionCard(
                      title: 'Progreso de tareas',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _ProgressRow(label: 'Backend', value: 0.75),
                          _ProgressRow(label: 'Frontend', value: 0.55),
                          _ProgressRow(label: 'QA', value: 0.32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _SectionCard(
                title: 'Actividad reciente',
                trailing: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                child: const _RecentActivityTable(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String delta;
  const _KpiData({required this.title, required this.value, required this.delta});
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final up = data.delta.trim().startsWith('+');
    final color = up ? Colors.green : Colors.red;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(data.value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(data.delta, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<num> values;
  const _MiniSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    // Normaliza valores para dibujar barras simples
    final maxVal = (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b)).toDouble();
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final h = maxVal == 0 ? 0.0 : (v.toDouble() / maxVal) * 110;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(.35)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  const _ProgressRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: value, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTable extends StatelessWidget {
  const _RecentActivityTable();

  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['#10234', 'Nuevo usuario', 'hoy 12:30'],
      ['#10233', 'Pago recibido', 'ayer 18:04'],
      ['#10232', 'Ticket asignado', 'ayer 11:27'],
      ['#10231', 'Build desplegado', 'ayer 09:12'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Evento')),
          DataColumn(label: Text('Fecha')),
        ],
        rows: rows
            .map(
              (r) => DataRow(cells: [
                DataCell(Text(r[0])),
                DataCell(Text(r[1])),
                DataCell(Text(r[2])),
              ]),
            )
            .toList(),
      ),
    );
  }
}
