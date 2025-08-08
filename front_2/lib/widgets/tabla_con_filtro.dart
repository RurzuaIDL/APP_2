import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

class TablaConFiltro extends StatefulWidget {
  const TablaConFiltro({super.key});

  @override
  State<TablaConFiltro> createState() => _TablaConFiltroState();
}

class _TablaConFiltroState extends State<TablaConFiltro> {
  final TextEditingController _controller = TextEditingController();

  // TODO: reemplazar por data remota
  final List<Map<String, String>> _datos = const [
    {'Nombre': 'Juan Pérez', 'Correo': 'juan@example.com'},
    {'Nombre': 'María López', 'Correo': 'maria@example.com'},
    {'Nombre': 'Pedro Díaz', 'Correo': 'pedro@example.com'},
    {'Nombre': 'Ana Torres', 'Correo': 'ana@example.com'},
  ];

  String _filtro = '';
  final Set<int> _selected = <int>{}; // índices de _datos

  List<MapEntry<int, Map<String, String>>> get _filtradosConIndice {
    return _datos.asMap().entries.where((e) {
      if (_filtro.isEmpty) return true;
      return e.value.values.any(
        (v) => v.toLowerCase().contains(_filtro.toLowerCase()),
      );
    }).toList();
  }

  void _toggleSelectAll(bool? value) {
    final filteredKeys = _filtradosConIndice.map((e) => e.key);
    setState(() {
      if (value == true) {
        _selected.addAll(filteredKeys);
      } else {
        _selected.removeAll(filteredKeys);
      }
    });
  }

  Future<void> _exportSelectedToExcel() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una fila.')),
      );
      return;
    }

    final excel = Excel.createExcel();

    // Renombrar la hoja por defecto
    final defaultSheetName = excel.getDefaultSheet();
    if (defaultSheetName != null) {
      excel.rename(defaultSheetName, 'Seleccion');
    }

    final sheet = excel['Seleccion'];

    // Encabezados
    sheet.appendRow([TextCellValue('Nombre'), TextCellValue('Correo')]);

    // Filas seleccionadas
    for (var i = 0; i < _datos.length; i++) {
      if (_selected.contains(i)) {
        final fila = _datos[i];
        sheet.appendRow([
          TextCellValue(fila['Nombre'] ?? ''),
          TextCellValue(fila['Correo'] ?? ''),
        ]);
      }
    }

    // Guardar
    final bytes = Uint8List.fromList(excel.encode()!);
    await FileSaver.instance.saveFile(
      name: 'seleccion',
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel generado con la selección.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtradosConIndice;

    // Estado del "seleccionar todo" según lo filtrado
    final allFilteredSelected =
        filtrados.isNotEmpty &&
        filtrados.every((e) => _selected.contains(e.key));
    final someFilteredSelected = filtrados.any(
      (e) => _selected.contains(e.key),
    );
    final selectAllValue = allFilteredSelected
        ? true
        : (someFilteredSelected ? null : false);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 🔍 Búsqueda + Exportar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Buscar',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _filtro.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _filtro = '');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (valor) =>
                            setState(() => _filtro = valor.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _exportSelectedToExcel,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar a Excel'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 📋 Tabla: ocupa todo el ancho del Card, solo scroll vertical
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity, // 👈 se adapta al ancho del Card
                      child: DataTable(
                        columnSpacing: 24,
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value: selectAllValue,
                              tristate: true,
                              onChanged: _toggleSelectAll,
                            ),
                          ),
                          const DataColumn(label: Text('Nombre')),
                          const DataColumn(label: Text('Correo')),
                        ],
                        rows: filtrados.map((entry) {
                          final idx = entry.key;
                          final fila = entry.value;
                          final isSelected = _selected.contains(idx);

                          return DataRow(
                            // importante: NO usamos onSelectChanged => solo el checkbox controla
                            selected: isSelected,
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.add(idx);
                                      } else {
                                        _selected.remove(idx);
                                      }
                                    });
                                  },
                                ),
                              ),
                              DataCell(Text(fila['Nombre'] ?? '')),
                              DataCell(Text(fila['Correo'] ?? '')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
