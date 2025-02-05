// ignore: file_names
import 'dart:io';
import 'package:app_inspections/services/auth_service.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore: library_prefixes
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class ReporteObra extends StatelessWidget {
  final int idTienda;
  final String nomTienda;

  const ReporteObra(
      {super.key, required this.idTienda, required this.nomTienda});

  Future<List<Map<String, dynamic>>> _cargarReporte(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesObra(idTienda);
  }

  void _descargarPDF(BuildContext context, String? user) async {
    List<Map<String, dynamic>> datos = await _cargarReporte(idTienda);
    File pdfFile = await generatePDF(datos, nomTienda, user);
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
          "REPORTE DE MANO DE OBRA",
          style: TextStyle(fontSize: 24.0, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _descargarPDF(context, user);
            },
          ),
        ],
      ),
      body: ReporteManoObra(idTienda: idTienda),
    );
  }
}

class ReporteManoObra extends StatefulWidget {
  final int idTienda;

  const ReporteManoObra({super.key, required this.idTienda});

  @override
  State<ReporteManoObra> createState() => _ReporteManoObraState();
}

Future<File> generatePDF(
    List<Map<String, dynamic>> data, String nomTiend, String? user) async {
  final pdfWidgets.Font customFont = pdfWidgets.Font.ttf(
    await rootBundle.load('assets/fonts/OpenSans-Italic.ttf'),
  );
  final pdf = pdfWidgets.Document();
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final formattedDate = dateFormatter.format(DateTime.now());
  //final Uint8List imageData = await _loadImageData('assets/logoconexsa.png');
  final Uint8List backgroundImageData =
      await _loadImageData('assets/portada1.png');
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
                  pdfWidgets.SizedBox(height: 100),

                  pdfWidgets.Text(
                    'Reporte de Mano de Obra',
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
                    'Nombre de Inspector: $user',
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
                        'Reporte de Mano de Obra',
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
                          ['Mano de Obra', 'Cantidad Total'],
                          for (var row in pageData)
                            [
                              pdfWidgets.Text(
                                row['nom_obr'].toString(),
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

  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/reporteManoDeObra.pdf';
  final File file = File(filePath);
  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<Uint8List> _loadImageData(String imagePath) async {
  final ByteData data = await rootBundle.load(imagePath);
  return data.buffer.asUint8List();
}

class _ReporteManoObraState extends State<ReporteManoObra> {
  late Future<List<Map<String, dynamic>>> _futureReporte;

  @override
  void initState() {
    super.initState();
    _futureReporte = _cargarReporte(widget.idTienda);
  }

  Future<List<Map<String, dynamic>>> _cargarReporte(int idTienda) async {
    return DatabaseProvider.mostrarCantidadesObra(idTienda);
  }

  int calculateRowsPerPage(List<Map<String, dynamic>> data) {
    // Define el número máximo de filas por página que deseas mostrar
    int maxRowsPerPage = 12;

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
                      DataColumn(label: Text('Mano de Obra')),
                      DataColumn(label: Text('Cantidad Total')),
                    ],
                    source: MyDataTableSource(data),
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

class MyDataTableSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  MyDataTableSource(this._data);

  @override
  DataRow getRow(int index) {
    if (index >= _data.length) {
      return const DataRow(cells: []);
    }

    final dato = _data[index];
    print('Building row for index $index: $dato');

    return DataRow(cells: [
      DataCell(Text('${dato['nom_obr']}')),
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
