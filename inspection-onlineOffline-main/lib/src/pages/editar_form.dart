import 'dart:async';
import 'dart:io';
import 'package:app_inspections/models/mano_obra.dart';
import 'package:app_inspections/models/materiales.dart';
import 'package:app_inspections/models/problemas.dart';
import 'package:app_inspections/models/reporte_model.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:app_inspections/services/functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:convert';

class EditarForm extends StatelessWidget {
  final int idTienda;
  final Reporte data;
  final String nombreTienda;
  final String zona;

  const EditarForm(
      {super.key,
      required this.idTienda,
      required this.data,
      required this.nombreTienda,
      required this.zona});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 40.0, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
        title: Text(
          nombreTienda,
          style: const TextStyle(fontSize: 24.0, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: EditMyForm(
          idTienda: idTienda,
          context: context,
          data: data,
          nombreTienda: nombreTienda,
          zona: zona),
    );
  }
}

class EditMyForm extends StatefulWidget {
  final int idTienda;
  final BuildContext context;
  final Reporte data;
  final String nombreTienda;
  final String zona;

  const EditMyForm(
      {super.key,
      required this.idTienda,
      required this.context,
      required this.data,
      required this.nombreTienda,
      required this.zona});

  @override
  State<EditMyForm> createState() =>
      // ignore: no_logic_in_create_state
      _EditMyFormState(idTienda: idTienda, context: context, zona);
}

class _EditMyFormState extends State<EditMyForm> {
  final int idTienda;
  String idTien = '';
  String nombreTienda = '';
  final String zona;

  @override
  final BuildContext context;
  bool _isLoading = true;
  List<String> fotos = [];

  @override
  void initState() {
    super.initState();
    idReporte = widget.data.idReporte ?? 0;
    formato = widget.data.formato ?? '';
    _departamentoController.text = widget.data.nomDep ?? '';
    _ubicacionController.text = widget.data.claveUbi ?? '';
    idProbl = widget.data.idProbl ?? 0;
    idMat = widget.data.idMat ?? 0;
    idObra = widget.data.idObr ?? 0;
    _cantmatController.text = widget.data.cantMat.toString();
    _cantobraController.text = widget.data.cantObr.toString();
    _otroMPController.text = widget.data.otro ?? '';
    _otroObraController.text = widget.data.otroObr ?? '';
    fotos = widget.data.foto != null
        ? List<String>.from(jsonDecode(widget.data.foto!))
        : [];
    _cargarDatosAsync();
    unico = widget.data.datoU;
    print("id reporte $idReporte");
    print("id reporte $unico");
    print("FOTOO $fotos");
  }

  //campos de la base de datos
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _cantmatController = TextEditingController();
  final TextEditingController _cantobraController = TextEditingController();
  final TextEditingController _otroMPController = TextEditingController();
  final TextEditingController _otroObraController = TextEditingController();

  int idTiend = 0;
  int idProbl = 0;
  int idMat = 0;
  int idObra = 0;
  int idReporte = 0;
  String? unico = '';
  String formato = "";
  final ImagePicker _picker = ImagePicker();

  _EditMyFormState(this.zona, {required this.idTienda, required this.context});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<XFile> images = []; // Lista para almacenar las rutas de las imágenes
  int maxPhotos = 6;

  final TextEditingController _textEditingControllerProblema =
      TextEditingController();
  bool showListProblemas = false;
  List<String> opcionesProblemas = [];
  List<String> filteredOptionsProblema = [];
  bool isProblemSelected = false;

  final TextEditingController _textEditingControllerMaterial =
      TextEditingController();
  bool showListMaterial = false;
  List<String> opcionesMaterial = [];
  List<String> filteredOptionsMaterial = [];
  bool isMaterialSelected = false;

  final TextEditingController _textEditingControllerObra =
      TextEditingController();
  bool showListObra = false;
  List<String> opcionesObra = [];
  List<String> filteredOptionsObra = [];
  bool isObraSelected = false;

  final FocusNode _cantidadFocus = FocusNode();
  final FocusNode _focusOtO = FocusNode();

  Future<void> editarDefecto() async {
    try {
      // Llama al método para obtener los defectos por su ID
      List<Problemas> defectos =
          await DatabaseProvider.obtenerDefectoPorId(idProbl);

      if (defectos.isNotEmpty) {
        // Itera sobre cada defecto en la lista
        for (Problemas defecto in defectos) {
          String nombreProblema = defecto.nombre;
          _textEditingControllerProblema.text = nombreProblema;
        }
      } else {
        // Manejo si no se encontraron defectos
        if (kDebugMode) {
          print("NO HAY DATOS");
        }
      }
    } catch (error) {
      // Maneja cualquier error que ocurra durante la ejecución
      if (kDebugMode) {
        print('Error en editarDefecto: $error');
      }
    }
  }

  Future<void> editarMaterial() async {
    try {
      List<Materiales> materiales =
          await DatabaseProvider.obtenerMaterialPorId(idMat);
      if (materiales.isNotEmpty) {
        for (Materiales material in materiales) {
          String nombreMaterial = material.nombre;
          _textEditingControllerMaterial.text = nombreMaterial;
        }
      } else {
        if (kDebugMode) {
          print("NO HAY DATOS");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error en editarDefecto: $error');
      }
    }
  }

  Future<void> editarManoObra() async {
    try {
      List<Obra> obras = await DatabaseProvider.obtenerObraPorId(idObra);
      if (obras.isNotEmpty) {
        for (Obra obra in obras) {
          String nombreObra = obra.nombre;

          _textEditingControllerObra.text = nombreObra;

          print('Nombre: $nombreObra');
        }
      } else {
        if (kDebugMode) {
          print("NO HAY DATOS");
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error en editarDefecto: $error');
      }
    }
  }

  Future<void> _cargarDatosAsync() async {
    try {
      await editarDefecto();
      await editarMaterial();
      await editarManoObra();
      setState(() {
        _isLoading = true;
      });

      Timer(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      const Text('¡Intente de nuevo por favor!');
    }
  }

  void handleSelectionMaterial(
      String selectedOptionMaterial, int idMaterialSeleccionado) {
    setState(() {
      _textEditingControllerMaterial.text = selectedOptionMaterial;
      showListMaterial = false;
      isMaterialSelected = true;
      idMat = idMaterialSeleccionado;
    });
  }

  void handleSelectionProblem(String selectedOptionProblem,
      int idProblemaSeleccionado, String textoFormato) {
    setState(() {
      _textEditingControllerProblema.text = selectedOptionProblem;
      showListProblemas = false;
      isProblemSelected = true;
      idProbl = idProblemaSeleccionado;
      formato = textoFormato;
    });
  }

  void handleSelectionObra(String selectedOptionObra, int idObraSeleccionado) {
    setState(() {
      _textEditingControllerObra.text = selectedOptionObra;
      showListObra = false;
      isObraSelected = true;
      idObra = idObraSeleccionado;
    });
  }

  // Función para guardar datos con confirmación
  void guardarDatosConConfirmacion(BuildContext context) async {
    bool confirmacion = await mostrarDialogoConfirmacionEditar(context);
    if (confirmacion == true) {
      _editarDatos();
    } else {}
  }

  Future<String?> selectPhoto() async {
    if (fotos.length >= maxPhotos) {
      String title = 'Límite de fotos alcanzado';
      String content = 'No puedes agregar más de 6 fotos';
      alerta(context, title, content);
    } else {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo == null) return null;
      await _saveImage(photo);
      return photo.path;
    }
    return null;
  }

  Future<void> _saveImage(XFile image) async {
    if (images.length >= maxPhotos) {
      String title = 'Límite de fotos alcanzado';
      String content = 'No puedes agregar más de 6 fotos';
      alerta(context, title, content);
    }
    String generateUniqueFilename(
        String dep, String ubi, String nomP, int idTiend) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'Dep_${dep}_Ubi_${ubi}_Def_${nomP}_T_${idTiend}_$timestamp.jpg';
    }

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      String dep = _departamentoController.text;
      String ubi = _ubicacionController.text;
      String nomP = _textEditingControllerProblema.text;

      String fileName = generateUniqueFilename(dep, ubi, nomP, idTiend);
      String imagePath = '${directory.path}/$fileName';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(await image.readAsBytes());

      setState(() {
        fotos.add(imagePath);
      });
      print("URL DE IMAGEN $imagePath");

      GallerySaver.saveImage(imagePath, albumName: 'inspecciones')
          .then((bool? success) {
        if (success != null && success) {
          print('La imagen se guardó correctamente en la galería.');
        } else {
          print('Error al guardar la imagen en la galería.');
        }
      });
      String title = 'Foto almacenada correctamente';
      String content = 'La foto se agregó correctamente';
      alerta(context, title, content);
    } catch (e) {
      print("No se pudo insertar el reporte online $e");
      String title = 'Foto no almacenada';
      String content = 'Intentalo nuevamente o revisa tu conexión a internet';
      alerta(context, title, content);
    }
  }

  //configuración de fotos
  void _replaceImage(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar una nueva foto'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? newImage = await _picker.pickImage(
                    source: ImageSource.camera,
                    preferredCameraDevice: CameraDevice.rear);
                if (newImage != null) {
                  String newPath = await _saveImageAndReturnPath(newImage);
                  setState(() {
                    fotos[index] = newPath;
                  });
                  print("FOTOS EN tomar una nueva foto $fotos");
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de la galería'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? newImage =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (newImage != null) {
                  String newPath = await _saveImageAndReturnPath(newImage);

                  setState(() {
                    fotos[index] = newPath;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Eliminar imagen'),
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  fotos.removeAt(index);
                });
                print("FOTOS EN eliminar imagen $fotos");
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _saveImageAndReturnPath(XFile image) async {
    if (images.length >= maxPhotos) {
      String title = 'Límite de fotos alcanzado';
      String content = 'No puedes agregar más de 6 fotos';
      alerta(context, title, content);
    }

    String generateUniqueFilename(
        String dep, String ubi, String nomP, int idTiend) {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'Dep_${dep}_Ubi_${ubi}_Def_${nomP}_T_${idTiend}_$timestamp.jpg';
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    String dep = _departamentoController.text;
    String ubi = _ubicacionController.text;
    String nomP = _textEditingControllerProblema.text;

    String fileName = generateUniqueFilename(dep, ubi, nomP, idTiend);
    String imagePath = '${directory.path}/$fileName';
    final File imageFile = File(imagePath);
    await imageFile.writeAsBytes(await image.readAsBytes());

    GallerySaver.saveImage(imagePath, albumName: 'inspecciones')
        .then((bool? success) {
      if (success != null && success) {
        print('La imagen se guardó correctamente en la galería.');
      } else {
        print('Error al guardar la imagen en la galería.');
      }
    });
    String title = 'Foto almacenada correctamente';
    String content = 'La foto se insertó correctamente';
    alerta(context, title, content);

    return imagePath;
  }

  void _editarDatos() {
    if (formKey.currentState!.validate()) {
      String valorDepartamento = _departamentoController.text;
      String valorUbicacion = _ubicacionController.text;
      String valorCanMate = _cantmatController.text;
      String valorCanObra = _cantobraController.text;
      String nomProbl = _textEditingControllerProblema.text;
      String nomMat = _textEditingControllerMaterial.text;
      String nomObra = _textEditingControllerObra.text;
      String otro = _otroMPController.text;
      String otroO = _otroObraController.text;
      int? cantM = widget.data.cantMat;
      int? cantO = widget.data.cantObr;
      String zona = widget.zona;

      try {
        if (valorCanMate.isNotEmpty) {
          cantM = int.parse(valorCanMate);
        }
        if (valorCanObra.isNotEmpty) {
          cantO = int.parse(valorCanObra);
        }

        Reporte nuevoReporte = Reporte(
          idReporte: idReporte,
          formato: formato,
          nomDep: valorDepartamento,
          claveUbi: valorUbicacion,
          idProbl: idProbl,
          nomProbl: nomProbl,
          idMat: idMat,
          nomMat: nomMat,
          otro: otro,
          cantMat: cantM,
          idObr: idObra,
          nomObr: nomObra,
          otroObr: otroO,
          cantObr: cantO,
          foto: jsonEncode(fotos),
          lastUpdated: DateTime.now().toIso8601String(),
        );
        print("FOTO EDITAR $fotos");

        DatabaseProvider.editarReporte(nuevoReporte);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(
                  255, 255, 255, 255), // Color de fondo del diálogo
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Bordes redondeados
              ),
              title: const Text(
                'Edición terminada',
                style: TextStyle(
                  color: Color.fromARGB(
                      255, 5, 20, 107), // Color del texto del título
                  fontWeight: FontWeight.bold, // Peso del texto del título
                  fontSize: 20, // Tamaño del texto del título
                ),
              ),
              content: const Text(
                '¡Los datos han sido editados con éxito!',
                style: TextStyle(
                  color: Colors.black54, // Color del texto del contenido
                  fontSize: 16, // Tamaño del texto del contenido
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra la alerta
                    Navigator.pushNamed(
                      context,
                      'inspectienda',
                      arguments: {
                        'idTienda': idTiend,
                        'nombreTienda': nombreTienda,
                        'zona': zona,
                      },
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromRGBO(
                        6,
                        6,
                        68,
                        1,
                      ),
                    ), // Color de fondo del botón
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            15), // Bordes redondeados del botón
                      ),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold, // Peso del texto del botón
                    ),
                  ),
                ),
              ],
            );
          },
        );
      } catch (e) {
        String title = 'Error al Editar';
        String content = '¡Intenta nuevamente! $e';
        alerta(context, title, content);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildLoadingIndicator() : _buildForm(context);
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildForm(BuildContext context) {
    idTiend = idTienda;
    List<Problemas> resultadosP = [];
    List<Materiales> resultadosM = [];
    List<Obra> resultadosO = [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Editar Inspección',
                    style: Theme.of(context).textTheme.headlineMedium),
                TextFormField(
                  controller: _departamentoController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (_departamentoController.text.isEmpty &&
                        _departamentoController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(labelText: 'Departamento'),
                ),
                TextFormField(
                  controller: _ubicacionController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration:
                      const InputDecoration(labelText: 'Ubicación (Bahia)'),
                  validator: (value) {
                    if (_ubicacionController.text.isEmpty &&
                        _ubicacionController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _textEditingControllerProblema,
                  onChanged: (String value) async {
                    resultadosP = await DatabaseProvider.showProblemas();
                    setState(() {
                      showListProblemas = value.isNotEmpty;
                      filteredOptionsProblema = resultadosP
                          .where((opcion) =>
                              opcion.codigo
                                  .toLowerCase()
                                  .contains(value.toLowerCase()) ||
                              opcion.nombre
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                          .map((opcion) {
                        // Guarda el ID en la variable externa
                        // Establecer como null por defecto
                        if (showListProblemas) {
                          idProbl = opcion.id!;
                          formato = opcion.formato;
                        }

                        String textoProblema = opcion.nombre;

                        return '$textoProblema|id:$idProbl|formato:$formato';
                      }).toList();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Escribe o selecciona un defecto',
                    suffixIcon: _textEditingControllerProblema.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _textEditingControllerProblema.clear();
                                isProblemSelected = false;
                                showListProblemas =
                                    true; // Muestra la lista nuevamente al eliminar la opción
                              });
                            },
                          )
                        : null,
                  ),
                  readOnly: isProblemSelected,
                  validator: (value) {
                    // Validar si el campo está vacío solo si el usuario ha interactuado con él
                    if (_textEditingControllerProblema.text.isEmpty &&
                        _textEditingControllerProblema.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                if (showListProblemas)
                  Visibility(
                    visible:
                        showListProblemas && filteredOptionsProblema.isNotEmpty,
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredOptionsProblema.length,
                        itemBuilder: (context, i) {
                          // Divide el texto del problema y el ID del problema
                          List<String> partes =
                              filteredOptionsProblema[i].split('|');
                          print("PARTES DE LA SELECCIÓN $partes");
                          String textoProblema = partes[0];
                          int idProblema = int.parse(
                              partes[1].substring(3)); // Para eliminar 'id:'
                          String textoFormato = partes[2]
                              .substring(8); // Para eliminar 'formato:'
                          return ListTile(
                            title: Text(textoProblema),
                            onTap: () {
                              int idProblemaSeleccionado = idProblema;
                              handleSelectionProblem(textoProblema,
                                  idProblemaSeleccionado, textoFormato);
                              showListProblemas = false;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _textEditingControllerMaterial,
                  onChanged: (String value) async {
                    if (zona == 'sismica') {
                      resultadosM =
                          await DatabaseProvider.showMaterialesSismo();
                    } else {
                      resultadosM = await DatabaseProvider.showMateriales();
                    }
                    setState(() {
                      showListMaterial = value.isNotEmpty;
                      filteredOptionsMaterial = resultadosM
                          .where((opcion) => opcion.nombre
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .map((opcion) {
                        String textoMaterial = opcion.nombre;
                        int idMaterial = showListMaterial ? opcion.id! : 173;
                        return '$textoMaterial|id:$idMaterial';
                      }).toList();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Escribe o selecciona un material',
                    suffixIcon: _textEditingControllerMaterial.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _textEditingControllerMaterial.clear();
                                isMaterialSelected = false;
                                showListMaterial = true;
                                idMat = 173;
                              });
                            },
                          )
                        : null,
                  ),
                  readOnly: isMaterialSelected,
                  validator: (value) {
                    if (_textEditingControllerMaterial.text.isEmpty &&
                        _textEditingControllerMaterial.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                if (showListMaterial)
                  Visibility(
                    visible:
                        showListMaterial && filteredOptionsMaterial.isNotEmpty,
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredOptionsMaterial.length,
                        itemBuilder: (context, index) {
                          List<String> partes =
                              filteredOptionsMaterial[index].split('|id:');
                          String textoMaterial = partes[0];
                          int idMaterial = int.parse(partes[1]);
                          print("MATERIALESS $partes");
                          return ListTile(
                            title: Text(textoMaterial),
                            onTap: () {
                              int idMaterialSeleccionado = idMaterial;
                              handleSelectionMaterial(
                                  textoMaterial, idMaterialSeleccionado);
                              showListMaterial = false;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _otroMPController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration:
                      const InputDecoration(labelText: 'Especifique otro'),
                  validator: (value) {
                    if (_otroMPController.text.isEmpty &&
                        _otroMPController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _cantmatController,
                  decoration:
                      const InputDecoration(labelText: 'Cantidad de Material'),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (_cantmatController.text.isEmpty &&
                        _cantmatController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text('Fotos',
                    style: TextStyle(
                      fontSize: 20,
                    )),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    itemBuilder: (context, index) {
                      String url = fotos[index];
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content: Image.file(
                                  File(url.trim()),
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/no_image.png',
                                      width: 500,
                                      height: 500,
                                    );
                                  },
                                  width: 500,
                                  height: 500,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Image.file(
                                File(url.trim()),
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/no_image.png',
                                    width: 70,
                                    height: 70,
                                  );
                                },
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white),
                                  onPressed: () => _replaceImage(index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () => selectPhoto(),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Agregar foto de la galería'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color.fromRGBO(
                            6,
                            6,
                            68,
                            1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const SizedBox(height: 25),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _textEditingControllerObra,
                  onChanged: (String value) async {
                    resultadosO = await DatabaseProvider.showObra();
                    idObra = 0;
                    setState(() {
                      showListObra = value.isNotEmpty;
                      filteredOptionsObra = resultadosO
                          .where((opcion) => opcion.nombre
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .map((opcion) {
                        if (showListObra) {
                          idObra = opcion.id!;
                        } else {
                          idObra = 0;
                        }
                        String textoObra = opcion.nombre;
                        return '$textoObra|id:$idObra';
                      }).toList();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Escribe o selecciona un dato',
                    suffixIcon: _textEditingControllerObra.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _textEditingControllerObra.clear();
                                isObraSelected = false;
                                showListObra = true;
                              });
                            },
                          )
                        : null,
                  ),
                  readOnly: isObraSelected,
                  validator: (value) {
                    if (_textEditingControllerObra.text.isEmpty &&
                        _textEditingControllerObra.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                if (showListObra)
                  Visibility(
                    visible: showListObra && filteredOptionsObra.isNotEmpty,
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: filteredOptionsObra.length,
                        itemBuilder: (context, index) {
                          List<String> partes =
                              filteredOptionsObra[index].split('|id:');
                          String textoObra = partes[0];
                          int idObra = int.parse(partes[1]);
                          return ListTile(
                            title: Text(textoObra),
                            onTap: () {
                              if (_textEditingControllerObra.text.isEmpty) {
                                idObra = 0;
                              }
                              int idObraSeleccionado = idObra;
                              handleSelectionObra(
                                  textoObra, idObraSeleccionado);

                              showListObra = false;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                TextFormField(
                  focusNode: _focusOtO,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _otroObraController,
                  decoration: const InputDecoration(
                      labelText: 'Especifique otro (Mano de Obra)'),
                  validator: (value) {
                    if (_otroObraController.text.isEmpty &&
                        _otroObraController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  focusNode: _cantidadFocus,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _cantobraController,
                  decoration: const InputDecoration(
                      labelText: 'Cantidad de Material para Mano de Obra'),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (_cantobraController.text.isEmpty &&
                        _cantobraController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () {
                    guardarDatosConConfirmacion(context);
                  },
                  key: null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromRGBO(
                      6,
                      6,
                      68,
                      1,
                    ),
                  ),
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _mostrarFotoEnGrande(XFile image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PhotoView(
                imageProvider: FileImage(File(image.path)),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                loadingBuilder: (context, event) {
                  if (event == null || event.expectedTotalBytes == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      value: event.cumulativeBytesLoaded /
                          event.expectedTotalBytes!,
                    ),
                  );
                },
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child:
                        const Icon(Icons.cancel_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
