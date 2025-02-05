import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:app_inspections/models/mano_obra.dart';
import 'package:app_inspections/models/materiales.dart';
import 'package:app_inspections/models/problemas.dart';
import 'package:app_inspections/models/reporte_model.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:app_inspections/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:app_inspections/services/functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:diacritic/diacritic.dart';

class F1Screen extends StatelessWidget {
  final int idTienda;
  final String zona;

  const F1Screen({
    super.key,
    required this.idTienda,
    required this.zona,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyForm(
        idTienda: idTienda,
        context: context,
        zona: zona,
      ),
    );
  }
}

// ignore: must_be_immutable
class MyForm extends StatefulWidget {
  final int idTienda;
  final BuildContext context;
  final String zona;

  MyForm(
      {super.key,
      required this.idTienda,
      required this.context,
      required this.zona});

  @override
  // ignore: library_private_types_in_public_api, no_logic_in_create_state
  _MyFormState createState() =>
      // ignore: no_logic_in_create_state
      _MyFormState(idTienda: idTienda, context: context, zona);

  List<XFile> images = [];
}

class _MyFormState extends State<MyForm> {
  List<Materiales> materiales = [];
  List<Problemas> problemas = [];
  List<Obra> obra = [];

  final int idTienda;
  final String zona;

  @override
  final BuildContext context;
  List<Map<String, dynamic>> datosIngresados = [];
  List<XFile> images = [];
  int maxPhotos = 6;

  cargaProblemas() async {
    List<Problemas> auxProblema = await DatabaseProvider.showProblemas();

    setState(() {
      problemas = auxProblema;
    });
  }

  //Campos de mi formulario
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _idproblController = TextEditingController();
  final TextEditingController _idmatController = TextEditingController();
  final TextEditingController _cantmatController = TextEditingController();
  final TextEditingController _idobraController = TextEditingController();
  final TextEditingController _cantobraController = TextEditingController();
  final TextEditingController _otroMPController = TextEditingController();
  final TextEditingController _otroObraController = TextEditingController();

  int idTiend = 0;
  int idProbl = 0;
  int idMat = 0;
  int idObra = 0;
  bool isGuardarHabilitado = false;
  String? nomUser = "";
  String formato = "";
  List<String> problemasEscritos = [];
  List<String> materialesEscritos = [];
  List<String> obrasEscritas = [];

  _MyFormState(this.zona, {required this.idTienda, required this.context});

  //Desactivar campos
  final FocusNode _focusNodeProbl = FocusNode();
  final FocusNode _focusNodeMat = FocusNode();
  final FocusNode _focusNodeObr = FocusNode();
  final FocusNode _cantidadFocus = FocusNode();
  final FocusNode _focusOtO = FocusNode();

  bool _areRemainingFieldsEnabled = false;

  @override
  void initState() {
    super.initState();

    cargaProblemas();
    _focusNodeProbl.addListener(() {
      if (!_focusNodeProbl.hasFocus) {
        setState(() {
          showListProblemas = false;
        });
      }
    });
    _focusNodeMat.addListener(() {
      if (!_focusNodeMat.hasFocus) {
        setState(() {
          showListMaterial = false;
        });
      }
    });
    _focusNodeObr.addListener(() {
      if (!_focusNodeObr.hasFocus) {
        setState(() {
          showListObra = false;
        });
      }
    });
    _departamentoController.addListener(_validateFields);
    _ubicacionController.addListener(_validateFields);
    _textEditingControllerProblema.addListener(_validateFields);
  }

  @override
  void dispose() {
    _departamentoController.dispose();
    _ubicacionController.dispose();
    _idproblController.dispose();
    _idmatController.dispose();
    _cantmatController.dispose();
    _idobraController.dispose();
    _cantobraController.dispose();
    _otroMPController.dispose();
    _otroObraController.dispose();
    _textEditingControllerProblema.dispose();
    _textEditingControllerMaterial.dispose();
    _textEditingControllerObra.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      _areRemainingFieldsEnabled = _departamentoController.text.isNotEmpty &&
          _ubicacionController.text.isNotEmpty &&
          _textEditingControllerProblema.text.isNotEmpty;
    });
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  List<String> imagePaths =
      []; // Lista para almacenar las rutas de las imágenes
  //deshabilitar botones

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
  List<String?> imageUrls = []; //se almacenan todas las imagenes

  void _showPermissionDeniedDialog() {
    String title = 'Permiso de cámara denegado';
    String content =
        'Esta aplicación necesita acceso a la cámara para funcionar correctamente. Por favor, habilita el permiso desde la configuración';
    alerta(context, title, content);
  }

  // Función para abrir la cámara y seleccionar imágenes
  Future<void> _getImage() async {
    if (images.length >= maxPhotos) {
      String title = 'Límite de fotos alcanzado';
      String content = 'No puedes agregar más de 6 fotos.';
      alerta(context, title, content);
      return;
    }

    var cameraPermissionStatus = await Permission.camera.request();
    if (cameraPermissionStatus != PermissionStatus.granted) {
      _showPermissionDeniedDialog();
    } else {}

    final XFile? image = await _picker.pickImage(
        source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
    if (image != null) {
      setState(() {
        images.add(image);
      });

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
          imagePaths.add(imagePath);
        });
        print("URL DE IMAGEN $imagePath");

        // Guardar la imagen en la galería
        GallerySaver.saveImage(imagePath, albumName: 'inspecciones')
            .then((bool? success) {
          if (success != null && success) {
            print('La imagen se guardó correctamente en la galería.');
          } else {
            print('Error al guardar la imagen en la galería.');
          }
        });
      } catch (e) {
        print("No se pudo insertar el reporte online $e");
      }
    }
  }

  Future<String?> selectPhoto() async {
    if (images.length >= maxPhotos) {
      String title = 'Límite de fotos alcanzado';
      String content = 'No puedes agregar más de 6 fotos.';
      alerta(context, title, content);
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

    if (photo == null) return null;

    print("Tenemos una imagen ${photo.path}");

    await _saveImage(photo);
    return photo.path;
  }

  // Función para guardar la imagen
  Future<void> _saveImage(XFile image) async {
    setState(() {
      images.add(image);
      imagePaths.add(image.path);
    });
  }

  void storeImageUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? storedUrls = prefs.getStringList('imageUrls') ?? [];
    storedUrls.add(url);
    await prefs.setStringList('imageUrls', storedUrls);
  }

  void _removeImage(int index) {
    setState(() {
      // Elimina la imagen de la lista de imágenes
      images.removeAt(index);

      // Elimina la ruta de la imagen de la lista de rutas de imágenes
      String imagePathToRemove = imagePaths[index];
      File(imagePathToRemove).deleteSync();
      imagePaths.removeAt(index);
      print("IMAGENES DE LA LISTA $imagePaths");
    });
  }

  void handleSelectionMaterial(
      String selectedOptionMaterial, int idMaterialSeleccionado) {
    setState(() {
      _textEditingControllerMaterial.text = selectedOptionMaterial;
      showListMaterial = false; // Ocultar la lista después de la selección
      isMaterialSelected = true;
      _idmatController.text = idMat.toString();
      idMat = idMaterialSeleccionado;
    });
  }

  // Mapa de problemas y sus correspondientes materiales y obras
  final Map<String, Map<String, String>> problemaMappings = {
    'tornillo de seguridad faltante.': {
      'obra': 'Instalación de tornillo de seguridad',
      'material': 'Tornillo grado 5, 7/16”x4” galv'
    },
    'tornillo de seguridad faltante': {
      'obra': 'Instalación de tornillo de seguridad',
      'material': 'Tornillo grado 5, 7/16”x2” galv'
    },
    'tablón con separador faltante': {
      'obra': '',
      'material': 'Separador tablón galvanizado'
    },
  };

  void handleSelectionProblem(String selectedOptionProblem,
      int idProblemaSeleccionado, String textoFormato) {
    setState(() {
      _textEditingControllerProblema.text = selectedOptionProblem;

      final problemaKey = selectedOptionProblem.toLowerCase();

      if (problemaMappings.containsKey(problemaKey)) {
        _textEditingControllerObra.text =
            problemaMappings[problemaKey]!['obra']!;
        _textEditingControllerMaterial.text =
            problemaMappings[problemaKey]!['material']!;
      } else {
        _textEditingControllerObra.clear();
        _textEditingControllerMaterial.clear();
      }

      isProblemSelected = true;
      showListProblemas = false;
      _idproblController.text = idProbl.toString();
      idProbl = idProblemaSeleccionado;
      formato = textoFormato;
    });
  }

  void handleSelectionObra(String selectedOptionObra, int idObraSeleccionado) {
    setState(() {
      _textEditingControllerObra.text = selectedOptionObra;
      showListObra = false; // Ocultar la lista después de la selección
      isObraSelected = true;
      _idobraController.text = idObra.toString();
      idObra = idObraSeleccionado;
    });
  }

  // Función para generar un ID único que aumenta en uno cada vez
  String generateUniqueId() {
    var uuid = const Uuid();
    return uuid.v4();
  }

  // Función para guardar datos con confirmación
  void guardarDatosConConfirmacion(BuildContext context) async {
    if (datosIngresados.isEmpty) {
      String title = 'Campos vacíos';
      String content = '¡Por favor ingresa datos!';
      alerta(context, title, content);
      return;
    }

    bool confirmacion = await mostrarDialogoConfirmacion(context);
    if (confirmacion == true) {
      _guardarDatos();
    } else {}
  }

  void _guardarDatos() {
    if (formKey.currentState!.validate()) {
      try {
        String valorDepartamento = _departamentoController.text;
        String valorUbicacion = _ubicacionController.text;
        String nomProbl = _textEditingControllerProblema.text;
        String nomMat = _textEditingControllerMaterial.text;
        String nomObra = _textEditingControllerObra.text;
        String otro = _otroMPController.text;
        String otroO = _otroObraController.text;
        String cantidadM = _cantmatController.text;
        String cantidadO = _cantobraController.text;
        int cantM = 0;
        int cantO = 0;
        String datoUnico = "";
        String datoCompartido = generateUniqueId();

        for (final datos in datosIngresados) {
          formato = datos['Formato'] ?? '';
          valorDepartamento = datos['Departamento'] ?? '';
          valorUbicacion = datos['Ubicacion'] ?? '';
          idProbl = datos['ID_Problema'] ?? 0;
          nomProbl = datos['Problema'] ?? '';
          idMat = datos['ID_Material'] ?? 0;
          nomMat = datos['Material'] ?? '';
          otro = datos['Otro'] ?? 0;
          cantidadM = datos['Cantidad_Material'] ?? '';
          idObra = datos['ID_Obra'] ?? 0;
          nomObra = datos['Obra'] ?? '';
          otroO = datos['Otro_Obr'] ?? 0;
          cantidadO = datos['Cantidad_Obra'] ?? ' ';
          datoUnico = datos['Dato_Unico'] ?? ' ';
          String? fotosString = imagePaths.toString();
          print("FOTOS EN LA BD $fotosString");
          fotosString = jsonEncode(imagePaths);

          if (cantidadM.isNotEmpty) {
            cantM = int.tryParse(cantidadM) ?? 0;
          }

          if (cantidadO.isNotEmpty) {
            cantO = int.tryParse(cantidadO) ?? 0;
          }

          Reporte nuevoReporte = Reporte(
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
            foto: fotosString,
            datoU: datoUnico,
            datoC: datoCompartido,
            nombUser: nomUser!,
            lastUpdated: DateTime.now().toIso8601String(),
            idTienda: idTiend,
          );
          print("FORMATO $formato");
          print("DEP $valorDepartamento");
          print("UBI $valorUbicacion");
          print("IDPROBL $idProbl");
          print("NOMPRO $nomProbl");
          print("IDMAT $idMat");
          print("NOMMAT $nomMat");
          print("OTRO $otro");
          print("CANTM $cantidadM");
          print("IDOBR $idObra");
          print("NOMO $nomObra");
          print("OTROO $otroO");
          print("CANTO $cantidadO");
          print("DTO UNICO $datoUnico");
          print("FOTOS $fotosString");
          print("OTRO $otro");
          print("OTRO $otro");
          print("OTRO $otro");

          DatabaseProvider.insertReporte(nuevoReporte);
        }
        _save();
        datosIngresados.clear();
        imagePaths.clear();
        images.clear();
      } catch (e) {
        String title = 'Error al Insertar';
        String content = '¡Intenta nuevamente! $e';
        alerta(context, title, content);
      }
    }
  }

  // Método para eliminar un dato
  void eliminarDato(int index) {
    setState(() {
      datosIngresados.removeAt(index);
    });
  }

  void _preguardarDatos() {
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
      String datoUnico = generateUniqueId();

      // Crear una lista para almacenar los nombres de los campos vacíos
      List<String> camposVacios = [];

      // Verificar que los campos no estén vacíos
      if (valorDepartamento.isEmpty) camposVacios.add('Departamento');
      if (valorUbicacion.isEmpty) camposVacios.add('Ubicación');
      if (nomProbl.isEmpty) camposVacios.add('Defecto');

      if (camposVacios.isNotEmpty) {
        String mensaje = 'Por favor completa los siguientes campos:\n';
        mensaje += camposVacios.join(', ');

        String title = 'Campos vacíos';
        String content = mensaje;
        alerta(context, title, content);
        return;
      }

      datosIngresados.add({
        'Formato': formato,
        'Departamento': valorDepartamento,
        'Ubicacion': valorUbicacion,
        'ID_Problema': idProbl,
        'Problema': nomProbl,
        'ID_Material': idMat,
        'Material': nomMat,
        'Otro': otro,
        'Cantidad_Material': valorCanMate,
        'ID_Obra': idObra,
        'Obra': nomObra,
        'Otro_Obr': otroO,
        'Dato_Unico': datoUnico,
        'Cantidad_Obra': valorCanObra,
      });
      _saveT();
    }
  }

  void _saveT() {
    setState(() {
      _textEditingControllerMaterial.clear();
      isMaterialSelected = false;
      showListMaterial = false;
      _textEditingControllerProblema.clear();
      isProblemSelected = false;
      showListProblemas = false;
      _textEditingControllerObra.clear();
      isObraSelected = false;
      showListObra = false;
      _cantidadFocus.unfocus();
      //_departamentoController.clear();
      //_ubicacionController.clear();
      _cantmatController.clear();
      _cantobraController.clear();
      _otroMPController.clear();
      _otroObraController.clear();
      formato = "";
      _focusNodeObr.unfocus();
    });
  }

  void _save() {
    setState(() {
      _textEditingControllerMaterial.clear();
      isMaterialSelected = false;
      showListMaterial = false;
      _textEditingControllerProblema.clear();
      isProblemSelected = false;
      showListProblemas = false;
      _textEditingControllerObra.clear();
      isObraSelected = false;
      showListObra = false;
      _cantidadFocus.unfocus();
      _departamentoController.clear();
      _ubicacionController.clear();
      _cantmatController.clear();
      _cantobraController.clear();
      _otroMPController.clear();
      _otroObraController.clear();
      formato = "";
      _focusNodeObr.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    idTiend = idTienda;
    List<Problemas> resultadosP = [];
    List<Materiales> resultadosM = [];
    List<Obra> resultadosO = [];
    final authService = Provider.of<AuthService>(context, listen: false);
    nomUser = authService.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text('Registro de Inspección',
                    style: Theme.of(context).textTheme.headlineMedium),
                TextFormField(
                  controller: _departamentoController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Departamento'),
                  validator: (value) {
                    if (_departamentoController.text.isEmpty &&
                        _departamentoController.text.isNotEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  },
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
                  focusNode: _focusNodeProbl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _textEditingControllerProblema,
                  onChanged: (String value) async {
                    resultadosP = await DatabaseProvider.showProblemas();
                    idProbl = 0;
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
                                showListProblemas = true;
                              });
                            },
                          )
                        : null,
                  ),
                  readOnly: isProblemSelected,
                  validator: (value) {
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
                          print("VISIBILIDAD $showListProblemas");
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
                              print("ID PROBLEMA $idProblemaSeleccionado");
                              handleSelectionProblem(textoProblema,
                                  idProblemaSeleccionado, textoFormato);
                              showListProblemas = false;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                TextFormField(
                  enabled: _areRemainingFieldsEnabled,
                  focusNode: _focusNodeMat,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _textEditingControllerMaterial,
                  onChanged: (String value) async {
                    String normalizedInput =
                        removeDiacritics(value); // Normalizar el texto
                    print("ZONAA $zona");
                    if (zona == 'sismica') {
                      resultadosM =
                          await DatabaseProvider.showMaterialesSismo();
                    } else {
                      resultadosM = await DatabaseProvider.showMateriales();
                    }

                    idMat = 0;
                    setState(() {
                      showListMaterial = normalizedInput.isNotEmpty;
                      filteredOptionsMaterial = resultadosM
                          .where((opcion) => removeDiacritics(opcion.nombre)
                              .toLowerCase()
                              .contains(normalizedInput.toLowerCase()))
                          .map((opcion) {
                        if (showListMaterial) {
                          idMat = opcion.id!;
                        }
                        String textoMaterial = opcion.nombre;
                        return '$textoMaterial|id:$idMat';
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
                  enabled: _areRemainingFieldsEnabled,
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
                  enabled: _areRemainingFieldsEnabled,
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
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return buildThumbnailWithCancel(images[index], index);
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _getImage();
                        },
                        icon: const Icon(Icons.camera),
                        label: const Text('Tomar fotografía'),
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final photoPath = await selectPhoto();
                          if (photoPath == null) return;
                          photoPath;
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Seleccionar fotografía'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text('Mano de Obra',
                    style: TextStyle(
                      fontSize: 25,
                    )),
                TextFormField(
                  enabled: _areRemainingFieldsEnabled,
                  focusNode: _focusNodeObr,
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
                        }
                        String textoObra = opcion.nombre;
                        return '$textoObra|id:$idObra';
                      }).toList();
                    });
                  },

                  //readOnly: true, no editar el texto
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
                  enabled: _areRemainingFieldsEnabled,
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
                  enabled: _areRemainingFieldsEnabled,
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
                ElevatedButton(
                  onPressed: _areRemainingFieldsEnabled
                      ? () {
                          _preguardarDatos();
                        }
                      : null,
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
                  child: const Text('Guardar'),
                ),
                const SizedBox(height: 25),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16.0,
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Departamento')),
                      DataColumn(label: Text('Ubicación')),
                      DataColumn(label: Text('Problema')),
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('Cantidad Material')),
                      DataColumn(label: Text('Mano de Obra')),
                      DataColumn(label: Text('Cantidad Mano de Obra')),
                      DataColumn(label: Text('Eliminar')),
                    ],
                    rows: datosIngresados.asMap().entries.map((entry) {
                      final index = entry.key;
                      final dato = entry.value;
                      return DataRow(cells: <DataCell>[
                        DataCell(
                          Center(
                            child: Text(
                              dato['Departamento'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Ubicacion'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Problema'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Material'],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Cantidad_Material'],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Obra'],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Center(
                            child: Text(
                              dato['Cantidad_Obra'],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  eliminarDato(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
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
                  child: const Text('Guardar todo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void mostrarFotoEnGrande(XFile image) {
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
                  color: Colors
                      .transparent, // Establece el color de fondo transparente
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
                    Navigator.of(context).pop(); // Cerrar el diálogo
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

//permitir al usuario ver la imagen en grande
  Widget buildThumbnailWithCancel(XFile image, int index) {
    return GestureDetector(
      onTap: () {
        mostrarFotoEnGrande(image);
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(.0),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Image.file(
                  File(image.path),
                  width: 100,
                  height: 70,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                /* setState(() {
                  images.removeAt(index); // Remueve la imagen de la lista
                }); */
                _removeImage(index);
              },
              child: const Icon(Icons.cancel_rounded), // Ícono para cancelar
            ),
          ),
        ],
      ),
    );
  }
}
