import 'dart:io';
import 'package:app_inspections/services/auth_service.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class ReporteMaterialesF1 extends StatelessWidget {
  final int idTienda;
  final String nomTienda;

  const ReporteMaterialesF1(
      {Key? key, required this.idTienda, required this.nomTienda})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _cargarReporte(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesF1(idTienda);
  }

  Future<List<Map<String, dynamic>>> _cargarReporteF2(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesF2(idTienda);
  }

  void _descargarPDFF1(BuildContext context, String? user) async {
    List<Map<String, dynamic>> datos = await _cargarReporte(idTienda);
    File pdfFile = await generatePDFF1(datos, nomTienda, user);
    // ignore: deprecated_member_use
    Share.shareFiles([pdfFile.path], text: 'Descarga tu reporte en PDF');
  }

  void _descargarPDFF2(BuildContext context, String? user) async {
    List<Map<String, dynamic>> datos = await _cargarReporteF2(idTienda);
    File pdfFile = await generatePDFF2(datos, nomTienda, user);
    // ignore: deprecated_member_use
    Share.shareFiles([pdfFile.path], text: 'Descarga tu reporte en PDF');
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    String? user = authService.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 40.0, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
        title: const Text(
          "REPORTE DE MATERIALES ",
          style: TextStyle(fontSize: 24.0, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          const Text("F1", style: TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _descargarPDFF1(context, user);
            },
          ),
          const Text("F2", style: TextStyle(color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _descargarPDFF2(context, user);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ReporteF1Widget(idTienda: idTienda)),
          Expanded(
            child: ReporteF2Widget(idTienda: idTienda),
          ),
        ],
      ),
    );
  }
}

class ReporteF1Widget extends StatefulWidget {
  final int idTienda;

  const ReporteF1Widget({Key? key, required this.idTienda}) : super(key: key);

  get pdfWidgets => null;

  @override
  State<ReporteF1Widget> createState() => _ReporteWidgetF1State();
}

Future<File> generatePDFF1(
    List<Map<String, dynamic>> data, String nomTiend, String? user) async {
  final pdfWidgets.Font customFont = pdfWidgets.Font.ttf(
    await rootBundle.load('assets/fonts/OpenSans-Italic.ttf'),
  );
  final pdf = pdfWidgets.Document();
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final formattedDate = dateFormatter.format(DateTime.now());
  final Uint8List imageData = await _loadImageData('assets/logoconexsa.png');
  final Uint8List backgroundImageData =
      await _loadImageData('assets/portada1.png');
  const int itemsPerPage = 20;
  final int totalPages = (data.length / itemsPerPage).ceil();

  pdf.addPage(
    pdfWidgets.Page(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 0,
        marginRight: -60,
        marginTop: 0,
        marginBottom: 0,
      ),
      build: (context) {
        return pdfWidgets.Stack(
          alignment: pdfWidgets.Alignment.center,
          children: [
            pdfWidgets.Positioned.fill(
              child: pdfWidgets.Image(
                pdfWidgets.MemoryImage(backgroundImageData),
                fit: pdfWidgets.BoxFit.cover,
              ),
            ),
            pdfWidgets.Center(
              child: pdfWidgets.Column(
                mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
                children: [
                  // Logo
                  pdfWidgets.Positioned(
                    right: 0,
                    top: 0,
                    child: pdfWidgets.Container(
                      margin: const pdfWidgets.EdgeInsets.all(5),
                      child:
                          pdfWidgets.Image(pdfWidgets.MemoryImage(imageData)),
                      width: 250,
                    ),
                  ),
                  pdfWidgets.SizedBox(height: 100),
                  pdfWidgets.Text(
                    'Reporte de Materiales F1',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 50,
                      fontWeight: pdfWidgets.FontWeight.bold,
                      color: const PdfColor(17 / 255, 25 / 255, 64 / 255),
                    ),
                  ),
                  pdfWidgets.Text(
                    'Fecha: $formattedDate',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                  pdfWidgets.Text(
                    'Tienda: $nomTiend',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                  pdfWidgets.Text(
                    'Nombre del Inspector: $user',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final int startIndex = pageIndex * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage < data.length)
        ? startIndex + itemsPerPage
        : data.length;
    final List<Map<String, dynamic>> pageData =
        data.sublist(startIndex, endIndex);

    pdf.addPage(
      pdfWidgets.MultiPage(
        build: (context) {
          List<pdfWidgets.Widget> widgets = [
            pdfWidgets.Container(
              padding: const pdfWidgets.EdgeInsets.all(40),
              child: pdfWidgets.Stack(
                children: [
                  pdfWidgets.Column(
                    crossAxisAlignment: pdfWidgets.CrossAxisAlignment.center,
                    children: [
                      pdfWidgets.Text(
                        'Reporte de Materiales F1',
                        style: pdfWidgets.TextStyle(
                          font: customFont,
                          fontSize: 20,
                          fontWeight: pdfWidgets.FontWeight.bold,
                          color: const PdfColor(17 / 255, 25 / 255, 64 / 255),
                        ),
                      ),
                      pdfWidgets.SizedBox(height: 30),
                      // ignore: deprecated_member_use
                      pdfWidgets.Table.fromTextArray(
                        context: context,
                        data: [
                          ['Material', 'Cantidad Total'],
                          for (var row in pageData)
                            [
                              pdfWidgets.Text(
                                row['nom_mat'].toString(),
                                style: pdfWidgets.TextStyle(
                                  font: customFont,
                                  fontSize: 12,
                                  color: PdfColors.black,
                                ),
                              ),
                              row['cantidad_total'].toString(),
                            ],
                        ],
                        border: pdfWidgets.TableBorder.all(
                          color: PdfColors.black,
                          width: 1,
                        ),
                        cellAlignment: pdfWidgets.Alignment.center,
                        cellStyle: const pdfWidgets.TextStyle(
                          fontSize: 12,
                          color: PdfColors.black,
                        ),
                        headerStyle: pdfWidgets.TextStyle(
                          fontWeight: pdfWidgets.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        headerDecoration: const pdfWidgets.BoxDecoration(
                          color: PdfColors.lightBlue900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
          return widgets;
        },
      ),
    );
  }

  // Guarda el PDF en un archivo
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/reporteDeMateriales.pdf';
  final File file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  return file;
}

Future<File> generatePDFF2(
    List<Map<String, dynamic>> data, String nomTiend, String? user) async {
  final pdfWidgets.Font customFont = pdfWidgets.Font.ttf(
    await rootBundle.load('assets/fonts/OpenSans-Italic.ttf'),
  );
  final pdf = pdfWidgets.Document();
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final formattedDate = dateFormatter.format(DateTime.now());
  //final Uint8List imageData = await _loadImageData('assets/logoconexsa.png');
  final Uint8List backgroundImageData =
      await _loadImageData('assets/portada3.png');
  const int itemsPerPage = 20;
  final int totalPages = (data.length / itemsPerPage).ceil();

  pdf.addPage(
    pdfWidgets.Page(
      orientation: pdfWidgets.PageOrientation.landscape,
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 0,
        marginRight: -60,
        marginTop: 0,
        marginBottom: 0,
      ),
      build: (context) {
        return pdfWidgets.Stack(
          alignment: pdfWidgets.Alignment.center,
          children: [
            pdfWidgets.Positioned.fill(
              child: pdfWidgets.Image(
                pdfWidgets.MemoryImage(backgroundImageData),
                fit: pdfWidgets.BoxFit.cover,
              ),
            ),
            pdfWidgets.Center(
              child: pdfWidgets.Column(
                mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
                children: [
                  // Logo
                  /* pdfWidgets.Positioned(
                    right: 0,
                    top: 0,
                    child: pdfWidgets.Container(
                      margin: const pdfWidgets.EdgeInsets.all(5),
                      child:
                          pdfWidgets.Image(pdfWidgets.MemoryImage(imageData)),
                      width: 250,
                    ),
                  ), */
                  pdfWidgets.SizedBox(height: 20),

                  pdfWidgets.Text(
                    'Reporte de Materiales F2',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 30,
                      fontWeight: pdfWidgets.FontWeight.bold,
                      color: PdfColors.blueGrey500,
                    ),
                  ),
                  pdfWidgets.Text(
                    'Fecha: $formattedDate',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                  pdfWidgets.Text(
                    'Tienda: $nomTiend',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                  pdfWidgets.Text(
                    'Nombre del Inspector: $user',
                    style: pdfWidgets.TextStyle(
                      font: customFont,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final int startIndex = pageIndex * itemsPerPage;
    final int endIndex = (startIndex + itemsPerPage < data.length)
        ? startIndex + itemsPerPage
        : data.length;
    final List<Map<String, dynamic>> pageData =
        data.sublist(startIndex, endIndex);

    pdf.addPage(
      pdfWidgets.MultiPage(
        orientation: pdfWidgets.PageOrientation.landscape,
        build: (context) {
          List<pdfWidgets.Widget> widgets = [
            pdfWidgets.Container(
              padding: const pdfWidgets.EdgeInsets.all(40),
              child: pdfWidgets.Stack(
                children: [
                  pdfWidgets.Column(
                    crossAxisAlignment: pdfWidgets.CrossAxisAlignment.center,
                    children: [
                      pdfWidgets.Text(
                        'Reporte de Materiales F2',
                        style: pdfWidgets.TextStyle(
                          font: customFont,
                          fontSize: 20,
                          fontWeight: pdfWidgets.FontWeight.bold,
                          color: PdfColors.blueGrey500,
                        ),
                      ),
                      pdfWidgets.SizedBox(height: 30),
                      // ignore: deprecated_member_use
                      pdfWidgets.Table.fromTextArray(
                        context: context,
                        data: [
                          ['Material', 'Cantidad Total'],
                          for (var row in pageData)
                            [
                              pdfWidgets.Text(
                                row['nom_mat'].toString(),
                                style: pdfWidgets.TextStyle(
                                  font: customFont,
                                  fontSize: 12,
                                  color: PdfColors.black,
                                ),
                              ),
                              row['cantidad_total'].toString(),
                            ],
                        ],
                        border: pdfWidgets.TableBorder.all(
                          color: PdfColors.black,
                          width: 1,
                        ),
                        cellAlignment: pdfWidgets.Alignment.center,
                        cellStyle: const pdfWidgets.TextStyle(
                          fontSize: 12,
                          color: PdfColors.black,
                        ),
                        headerStyle: pdfWidgets.TextStyle(
                          fontWeight: pdfWidgets.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        headerDecoration: const pdfWidgets.BoxDecoration(
                          color: PdfColor(17 / 255, 25 / 255, 64 / 255),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
          return widgets;
        },
      ),
    );
  }

  // Guarda el PDF en un archivo
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/reporteDeMateriales.pdf';
  final File file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  return file;
}

Future<Uint8List> _loadImageData(String imagePath) async {
  final ByteData data = await rootBundle.load(imagePath);
  return data.buffer.asUint8List();
}

class _ReporteWidgetF1State extends State<ReporteF1Widget> {
  late Future<List<Map<String, dynamic>>> _futureReporte;

  @override
  void initState() {
    super.initState();
    _futureReporte = _cargarReporte(widget.idTienda);
  }

  Future<List<Map<String, dynamic>>> _cargarReporte(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesF1(idTienda);
  }

  int calculateRowsPerPage(List<Map<String, dynamic>> data) {
    // Define el número máximo de filas por página que deseas mostrar
    int maxRowsPerPage = 6;
    // Calcula el número de filas por página basado en la longitud de tus datos
    int calculatedRowsPerPage =
        data.length > maxRowsPerPage ? maxRowsPerPage : data.length;

    return calculatedRowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureReporte,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Map<String, dynamic>> data = snapshot.data!;
            if (data.isEmpty) {
              return const Center(
                  child: Text('No hay datos disponibles para formato 1'));
            }
            return Expanded(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    cardTheme: CardTheme.of(context).copyWith(
                      color: Colors.white,
                    ),
                  ),
                  child: Card(
                    elevation: 0,
                    child: PaginatedDataTable(
                      columns: const [
                        DataColumn(label: Text('Material')),
                        DataColumn(label: Text('Cantidad Total')),
                      ],
                      source: MyDataTableF1Source(data),
                      rowsPerPage: calculateRowsPerPage(data),
                      sortColumnIndex: 0,
                      sortAscending: true,
                      columnSpacing: 20.0,
                      horizontalMargin: 10.0,
                      showCheckboxColumn: true,
                      showFirstLastButtons: true,
                      // ignore: deprecated_member_use
                      dataRowHeight: 60.0,
                      headingRowHeight: 65.0,
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class MyDataTableF1Source extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  MyDataTableF1Source(this._data);

  @override
  DataRow getRow(int index) {
    if (index >= _data.length) {
      return const DataRow(cells: []);
    }

    final dato = _data[index];
    print('Building row for index $index: $dato');

    return DataRow(cells: [
      DataCell(Text('${dato['nom_mat']}')),
      DataCell(Text('${dato['cantidad_total']}')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length; // Use the length of the data list

  @override
  int get selectedRowCount => 0;
}

class ReporteF2Widget extends StatefulWidget {
  final int idTienda;

  const ReporteF2Widget({Key? key, required this.idTienda}) : super(key: key);

  get pdfWidgets => null;

  @override
  State<ReporteF2Widget> createState() => _ReporteWidgetF2State();
}

class _ReporteWidgetF2State extends State<ReporteF2Widget> {
  late Future<List<Map<String, dynamic>>> _futureReporte;

  @override
  void initState() {
    super.initState();
    _futureReporte = _cargarReporteF2(widget.idTienda);
  }

  Future<List<Map<String, dynamic>>> _cargarReporteF2(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesF2(idTienda);
  }

  int calculateRowsPerPage(List<Map<String, dynamic>> data) {
    // Define el número máximo de filas por página que deseas mostrar
    int maxRowsPerPage = 6;

    // Calcula el número de filas por página basado en la longitud de tus datos
    int calculatedRowsPerPage =
        data.length > maxRowsPerPage ? maxRowsPerPage : data.length;

    return calculatedRowsPerPage;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureReporte,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<Map<String, dynamic>> data = snapshot.data!;
            if (data.isEmpty) {
              return const Center(
                  child: Text('No hay datos disponibles para formato 2'));
            }
            return ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: Theme(
                data: Theme.of(context).copyWith(
                  cardTheme: CardTheme.of(context).copyWith(
                    color: Colors.white,
                  ),
                ),
                child: Card(
                  elevation: 0,
                  child: PaginatedDataTable(
                    columns: const [
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Cantidad Total')),
                    ],
                    source: MyDataTableF1Source(data),
                    rowsPerPage: calculateRowsPerPage(data),
                    sortColumnIndex: 0,
                    sortAscending: true,
                    columnSpacing: 20.0,
                    horizontalMargin: 10.0,
                    showCheckboxColumn: true,
                    showFirstLastButtons: true,
                    // ignore: deprecated_member_use
                    dataRowHeight: 60.0,
                    headingRowHeight: 65.0,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class MyDataTableF2Source extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  MyDataTableF2Source(this._data);

  @override
  DataRow getRow(int index) {
    if (index >= _data.length) {
      return const DataRow(cells: []);
    }

    final dato = _data[index];
    print('Building row for index $index: $dato');

    return DataRow(cells: [
      DataCell(Text('${dato['nom_mat']}')),
      DataCell(Text('${dato['cantidad_total']}')),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length; // Use the length of the data list

  @override
  int get selectedRowCount => 0;
}
