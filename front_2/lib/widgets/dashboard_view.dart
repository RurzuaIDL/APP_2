import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isXS = w < 480;
        final isSM = w >= 480 && w < 720;
        final isWide = w >= 720;


        final inspections7d = const [42, 38, 40, 45, 39, 50, 47];
        final rejected7d   = const [ 3,  4,  5,  6,  4,  7,  5];

        final todayInspections = inspections7d.last;
        final yesterdayInspections = inspections7d[inspections7d.length - 2];
        final todayRejected = rejected7d.last;
        final yesterdayRejected = rejected7d[rejected7d.length - 2];

        double safeRate(int ok, int total) => total == 0 ? 0 : ok / total;
        final approvalToday = safeRate(todayInspections - todayRejected, todayInspections);
        final approvalYesterday = safeRate(yesterdayInspections - yesterdayRejected, yesterdayInspections);

        String signedPercent(double frac) {
          final v = (frac * 100);
          final s = v >= 0 ? '+' : '';
          return '$s${v.toStringAsFixed(1)}%';
        }
        double change(num curr, num prev) => (prev == 0) ? 0 : (curr - prev) / prev;


        final defectDist = const {
          'Golpes': 32,
          'Humedad': 21,
          'Clavos expuestos': 17,
          'Manchas': 11,
        };
        final totalDefects = defectDist.values.fold<int>(0, (a, b) => a + b);
        double defectFraction(String k) =>
            totalDefects == 0 ? 0 : (defectDist[k]! / totalDefects);

        final recentInspections = const [
          ['PL-1045', 'OK',   'hoy 12:30'],
          ['PL-1044', 'RECH', 'hoy 11:18'],
          ['PL-1043', 'OK',   'ayer 18:04'],
          ['PL-1042', 'OK',   'ayer 16:29'],
          ['PL-1041', 'RECH', 'ayer 11:27'],
          ['PL-1040', 'OK',   'ayer 09:12'],
        ];


        final kpis = [
          _KpiData(
            title: 'Inspecciones (hoy)',
            value: '$todayInspections',
            delta: signedPercent(change(todayInspections, yesterdayInspections)),
          ),
          _KpiData(
            title: 'Aprobación (hoy)',
            value: '${(approvalToday * 100).toStringAsFixed(1)}%',
            delta: signedPercent(change(approvalToday, approvalYesterday)),
          ),
        ];

        final sparkHeight = isXS ? 90.0 : (isSM ? 110.0 : 120.0);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isXS ? 12 : 16,
            vertical: 16,
          ),
          child: Column(
            children: [
  
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kpis.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isXS ? 14 / 7 : 14 / 6,
                ),
                itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
              ),
              const SizedBox(height: 16),

  
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _SectionCard(
                        title: 'Inspecciones últimos 7 días',
                        child: _MiniSparkline(
                          values: inspections7d.map((e) => e as num).toList(),
                          height: sparkHeight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SectionCard(
                        title: 'Top defectos',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProgressRow(label: 'Golpes', value: defectFraction('Golpes')),
                            _ProgressRow(label: 'Humedad', value: defectFraction('Humedad')),
                            _ProgressRow(label: 'Clavos expuestos', value: defectFraction('Clavos expuestos')),
                            _ProgressRow(label: 'Manchas', value: defectFraction('Manchas')),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Ultimos 7 días',
                      child: _MiniSparkline(
                        values: inspections7d.map((e) => e as num).toList(),
                        height: sparkHeight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Top defectos',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProgressRow(label: 'Golpes', value: defectFraction('Golpes')),
                          _ProgressRow(label: 'Humedad', value: defectFraction('Humedad')),
                          _ProgressRow(label: 'Clavos expuestos', value: defectFraction('Clavos expuestos')),
                          _ProgressRow(label: 'Manchas', value: defectFraction('Manchas')),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              _SectionCard(
                title: 'Inspecciones',
                trailing: TextButton.icon(
                  onPressed: () {}, 
                  icon: const Icon(Icons.refresh),
                  label: const Text(''),
                ),
                child: _RecentInspectionsResponsive(
                  isCompact: isXS || isSM,
                  rows: recentInspections,
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
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
                Expanded(
                  child: Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(data.delta, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                    ],
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
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
  final double height;
  const _MiniSparkline({required this.values, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final maxVal = (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b)).toDouble();
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final h = maxVal == 0 ? 0.0 : (v.toDouble() / maxVal) * (height - 10);
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


class _RecentInspectionsResponsive extends StatelessWidget {
  final bool isCompact;
  final List<List<String>> rows;
  const _RecentInspectionsResponsive({required this.isCompact, required this.rows});

  Color _statusColor(BuildContext ctx, String status) {
    switch (status.toUpperCase()) {
      case 'OK':
        return Colors.green;
      case 'RECH':
        return Colors.red;
      default:
        return Theme.of(ctx).colorScheme.primary;
    }
  }

  Widget _statusChip(BuildContext ctx, String status) {
    final c = _statusColor(ctx, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return ListView.separated(
        itemCount: rows.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = rows[i];
          return ListTile(
            dense: true,
            leading: Text(r[0], style: const TextStyle(fontWeight: FontWeight.w600)),
            title: _statusChip(context, r[1]),
            trailing: Text(r[2]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      );
    }


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Pallet')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Fecha')),
        ],
        rows: rows
            .map((r) => DataRow(cells: [
                  DataCell(Text(r[0])),
                  DataCell(_statusChip(context, r[1])),
                  DataCell(Text(r[2])),
                ]))
            .toList(),
      ),
    );
  }
}
