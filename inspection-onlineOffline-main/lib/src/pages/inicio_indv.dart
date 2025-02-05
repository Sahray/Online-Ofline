import 'dart:async';
import 'package:app_inspections/models/reporte_model.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:app_inspections/services/functions.dart';
import 'package:app_inspections/services/subir_online.dart';
import 'package:app_inspections/src/pages/editar_form.dart';
import 'package:app_inspections/src/pages/reporteMateriales.dart';
import 'package:app_inspections/src/pages/reporteObra.dart';
import 'package:app_inspections/src/pages/reporte_F1.dart';
import 'package:app_inspections/src/pages/reporte_F2.dart';
import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  final int idTienda;
  final int initialTabIndex;
  final String nomTienda;
  final bool? admin;
  final String zona;

  const InicioScreen(
      {super.key,
      required this.idTienda,
      required this.initialTabIndex,
      required this.nomTienda,
      required authService,
      required this.admin,
      required this.zona});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Inicio(
        idTienda: idTienda,
        nomTienda: nomTienda,
        admin: admin,
        zona: zona,
      ),
    );
  }
}

class Inicio extends StatefulWidget {
  final int idTienda;
  final TabController? controller;
  final String nomTienda;
  final bool? admin;
  final String zona;

  const Inicio({
    super.key,
    required this.idTienda,
    this.controller,
    required this.nomTienda,
    required this.admin,
    required this.zona,
  });

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _InicioState createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  List<Reporte> reportes = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSyncing = false;
  double _progress = 0.0;
  final StreamController<List<Reporte>> _reportesStreamController =
      StreamController();
  @override
  void initState() {
    super.initState();
    cargarReporte(widget.idTienda);
    _searchController.addListener(_filterReportes);
  }

  @override
  void dispose() {
    _reportesStreamController.close();
    _searchController.removeListener(_filterReportes);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> cargarReporte(int idTienda) async {
    List<Reporte> loadedTiendas =
        await DatabaseProvider.mostrarReporte(widget.idTienda);
    print("REPORTES BD ${loadedTiendas.length}");
    setState(() {
      reportes = loadedTiendas;
    });
    _reportesStreamController.add(reportes);
  }

  void _filterReportes() {
    String searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      _reportesStreamController.add(reportes);
    } else {
      List<Reporte> filteredReportes = reportes.where((reporte) {
        return reporte.claveUbi?.toLowerCase().contains(searchText) ?? false;
      }).toList();
      _reportesStreamController.add(filteredReportes);
    }
  }

  void _deleteReporte(int? idReporte) async {
    // ignore: use_build_context_synchronously
    bool confirmacion = await mostrarAlertaEliminarPreguntar(context);
    if (confirmacion == true) {
      await DatabaseProvider.deleteReporte(idReporte);
      setState(() {
        reportes.removeWhere((reporte) => reporte.idReporte == idReporte);
      });
      // ignore: use_build_context_synchronously
      mostrarAlertaEliminar(context);
    } else {}
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _progress = 0.0;
    });

    final insercionExitosa = await insertarReporteOnline((progress) {
      setState(() {
        _progress = progress;
      });
    });

    setState(() {
      _isSyncing = false;
    });

    if (insercionExitosa) {
      mostrarAlerta(context);
    } else {
      mostrarErrorAlerta(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int idTiend = widget.idTienda;
    String nomTienda = widget.nomTienda;
    bool? isAdmin = widget.admin;
    String zona = widget.zona;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 45),
        child: Column(
          children: [
            Text('Historial', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar ubicación',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      hintText: 'Search...',
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 10, 38,
                              129), // Color del borde cuando el campo de texto está enfocado
                          width:
                              1.0, // Ancho del borde cuando el campo de texto está enfocado
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: const BorderSide(
                          color: Colors
                              .grey, // Color del borde cuando el campo de texto está deshabilitado
                          width:
                              1.0, // Ancho del borde cuando el campo de texto está deshabilitado
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            _isSyncing
                ? Column(
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                      ),
                      const SizedBox(height: 30),
                      Text(
                          'Subiendo... ${(_progress * 100).toStringAsFixed(0)}%'),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _syncData,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
                    ),
                    child: const Text('Subir información'),
                  ),
            const SizedBox(
              height: 40,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: StreamBuilder<List<Reporte>>(
                  stream: _reportesStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Text('Comprueba tu conexión a internet');
                    } else {
                      List<Reporte> filteredReportes = snapshot.data!;
                      return SizedBox(
                        width: 1000.0,
                        child: DataTable(
                          horizontalMargin: 0,
                          columnSpacing: 10,
                          headingRowHeight: 50,
                          // ignore: deprecated_member_use
                          dataRowHeight: 90,
                          columns: [
                            const DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  'Ubicación',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ),
                            ),
                            /* DataColumn(
                                        label: Text(
                                          'Departamento',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.0,
                                          ),
                                        ),
                                      ), */
                            const DataColumn(
                              label: Text(
                                'Problema',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Mano de Obra',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                                softWrap: true,
                              ),
                            ),
                            const DataColumn(
                              label: Text(
                                'Editar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                            if (isAdmin!)
                              const DataColumn(
                                label: Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ),
                          ],
                          rows: filteredReportes.map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item.claveUbi ??
                                    'N/A')), // Manejo de posible valor nulo
                                /*  DataCell(Text(item.nomDep ??
                                              'N/A')), */
                                DataCell(SizedBox(
                                  width: 150,
                                  child: Text(
                                    item.nomProbl ?? 'N/A',
                                    softWrap: true,
                                  ),
                                )),
                                DataCell(Text(
                                  item.nomObr ?? 'N/A',
                                  softWrap: true,
                                )),
                                DataCell(
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditarForm(
                                              idTienda: idTiend,
                                              data: item,
                                              nombreTienda: nomTienda,
                                              zona: zona),
                                        ),
                                      );
                                    },
                                    child: const Center(
                                      child: Icon(
                                        Icons.mode_edit,
                                        color: Color.fromRGBO(7, 133, 13, 1),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAdmin)
                                  DataCell(
                                    IconButton(
                                      onPressed: () =>
                                          _deleteReporte(item.idReporte),
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReporteF1Screen(
                      idTienda: idTiend,
                      nomTienda: nomTienda,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
              ),
              child: const Text('Ver Reporte F1'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReporteF2Screen(
                      idTienda: idTiend,
                      nomTienda: nomTienda,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
              ),
              child: const Text('Ver Reporte F2'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReporteMaterialesF1(
                      idTienda: idTiend,
                      nomTienda: nomTienda,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
              ),
              child: const Text('Materiales'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReporteObra(
                      idTienda: idTiend,
                      nomTienda: nomTienda,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
              ),
              child: const Text('Mano de Obra'),
            ),
          ],
        ),
      ),
    );
  }
}
