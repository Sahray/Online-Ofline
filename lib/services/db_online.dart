import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Importar dotenv
import 'package:postgres/postgres.dart';

class DatabaseHelper {
  // Usando la nueva conexión
  static Future<PostgreSQLConnection> _getConnection() async {
    try {
      // Obtener los valores de las variables de entorno desde dotenv
      final databaseHost = dotenv.env['DB_HOST'] ?? '';
      final databasePort = int.parse(dotenv.env['DB_PORT'] ?? '5432');
      final databaseName = dotenv.env['DB_NAME'] ?? '';
      final username = dotenv.env['DB_USER'] ?? '';
      final password = dotenv.env['DB_PASSWORD'] ?? '';

      // Validar que no falten valores esenciales
      if (databaseHost.isEmpty || databaseName.isEmpty || username.isEmpty || password.isEmpty) {
        throw Exception('Faltan configuraciones de conexión en las variables de entorno');
      }

      // Aquí es donde estableces la nueva conexión:
      final connection = PostgreSQLConnection(
        databaseHost, // Dirección del servidor
        databasePort, // Puerto de la base de datos
        databaseName, // Nombre de la base de datos
        username: username, // Usuario
        password: password, // Contraseña
      );

      // Intentamos abrir la conexión
      await connection.open();
      print('BASE CONECTADA');
      return connection;
    } catch (e) {
      print('Error al abrir la conexión: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadPhotosToFirebase(String? filePaths) async {
    List<String> downloadUrls = [];

    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      // Dividir la cadena en una lista de rutas
      List<String> filePathList = filePaths!.split(',');

      for (String filePath in filePathList) {
        // Eliminar posibles espacios en blanco y corchetes
        filePath = filePath.trim().replaceAll('[', '').replaceAll(']', '');

        // Eliminar comillas adicionales alrededor de la ruta absoluta
        filePath = filePath.replaceAll('"', '');

        print("Verificando archivo: $filePath");

        // Verificar la existencia del archivo
        File file = File(filePath);
        print("Ruta absoluta del archivo: ${file.absolute.path}");
        if (await file.exists()) {
          print("Archivo encontrado: $filePath");

          // Subir el archivo a Firebase Storage
          TaskSnapshot snapshot = await storage
              .ref('uploads/${file.uri.pathSegments.last}')
              .putFile(
                file,
                SettableMetadata(contentType: 'image/jpeg'),
              );

          // Obtener la URL del archivo subido
          String downloadUrl = await snapshot.ref.getDownloadURL();
          downloadUrls.add(downloadUrl);
          print("FIREBASE $downloadUrls");
        } else {
          print("El archivo no existe: $filePath");
        }
      }
    } catch (e) {
      print("Error al subir las fotos a Firebase: $e");
    }

    return downloadUrls;
  }

  static Future<void> insertarReporte(
      String? formato,
      String? valorDepartamento,
      String? valorUbicacion,
      int? idProbl,
      String? nomProbl,
      int? idMat,
      String? nomMat,
      String? otro,
      int? cantM,
      int? idObra,
      String? nomObr,
      String? otroObr,
      int? cantO,
      String? foto,
      String? datoUnico,
      String? datoComp,
      String? nomUser,
      String? lastUpdate,
      int? idTiend) async {
    final connection = await _getConnection();
    try {
      await connection.query(
        'INSERT INTO reports (formato, nom_dep, clave_ubi, id_probl, nom_probl, id_mat, nom_mat, otro, cant_mat, id_obr, nom_obr, otro_obr, cant_obr, foto, dato_unico, dato_comp, nom_user, last_updated, id_tienda) '
        'VALUES (@formato, @valorDepartamento, @valorUbicacion, @idProbl, @nomProbl, @idMat, @nomMat, @otro, @cantM, @idObra, @nomObr, @otroObr, @cantO, @foto, @datoUnico, @datoComp, @nomUser, @lastUpdate, @idTiend)',
        substitutionValues: {
          'formato': formato,
          'valorDepartamento': valorDepartamento,
          'valorUbicacion': valorUbicacion,
          'idProbl': idProbl,
          'nomProbl': nomProbl,
          'idMat': idMat,
          'nomMat': nomMat,
          'otro': otro,
          'cantM': cantM,
          'idObra': idObra,
          'nomObr': nomObr,
          'otroObr': otroObr,
          'cantO': cantO,
          'foto': foto,
          'datoUnico': datoUnico,
          'datoComp': datoComp,
          'nomUser': nomUser,
          'lastUpdate': lastUpdate,
          'idTiend': idTiend,
        },
      );
      if (kDebugMode) {
        print("CONSULTA INSERTADA CORRECTAMENTE");
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al insertar el reporte: $e');
      }
      rethrow;
    }
  }

  static Future<void> editarReporte(
    int? idReporte,
    String? formato,
    String? valorDepartamento,
    String? valorUbicacion,
    int? idProbl,
    String? nomProbl,
    int? idMat,
    String? nomMat,
    String? otro,
    int? cantM,
    int? idObra,
    String? nomObr,
    String? otroObr,
    int? cantO,
    String? foto,
    String? datoU,
    int? idTiend,
  ) async {
    final connection = await _getConnection();
    try {
      await connection.query(
        '''UPDATE reports SET formato = @formato, nom_dep = @valorDepartamento, clave_ubi = @valorUbicacion, id_probl = @idProbl, nom_probl = @nomProbl, id_mat = @idMat, nom_mat = @nomMat, otro = @otro, cant_mat = @cantM, id_obr = @idObra, nom_obr = @nomObr, otro_obr = @otroObr, cant_obr = @cantO, foto = @foto, id_tienda = @idTiend WHERE dato_unico = @datoU''',
        substitutionValues: {
          'idReporte': idReporte,
          'formato': formato,
          'valorDepartamento': valorDepartamento,
          'valorUbicacion': valorUbicacion,
          'idProbl': idProbl,
          'nomProbl': nomProbl,
          'idMat': idMat,
          'nomMat': nomMat,
          'otro': otro,
          'cantM': cantM,
          'idObra': idObra,
          'nomObr': nomObr,
          'otroObr': otroObr,
          'cantO': cantO,
          'foto': foto,
          'datoU': datoU,
          'idTiend': idTiend,
        },
      );
      print("Reporte actualizado correctamenteee: $datoU");
    } catch (e) {
      if (kDebugMode) {
        print('Error al editar el reporte: $e');
      }
      rethrow;
    } finally {
      await connection.close();
    }
  }

  static Future<bool> sincronizarConPostgreSQL(List<Reporte> reportes) async {
    final connection = await _getConnection();
    bool insercionExitosa = true;

    for (final reporte in reportes) {
      try {
        String? unic = reporte.datoU;
        print("Procesando reporte con dato único: $unic");

        final result = await connection.query(
            'SELECT COUNT(*) FROM reports WHERE dato_unico = @unic',
            substitutionValues: {'unic': unic});

        final rowCount = int.parse(result[0][0].toString());
        if (rowCount == 0) {
          List<String> fotosUrls = [];
          if (reporte.foto != null && reporte.foto!.isNotEmpty) {
            fotosUrls = await uploadPhotosToFirebase(reporte.foto);
          }

          String? fotoUrl = fotosUrls.isNotEmpty ? fotosUrls.join(',') : '';
          print(fotoUrl.isNotEmpty
              ? "si hay foto en el reporte"
              : "No hay foto en el reporte");

          await insertarReporte(
              reporte.formato,
              reporte.nomDep,
              reporte.claveUbi,
              reporte.idProbl,
              reporte.nomProbl,
              reporte.idMat,
              reporte.nomMat,
              reporte.otro,
              reporte.cantMat,
              reporte.idObr,
              reporte.nomObr,
              reporte.otroObr,
              reporte.cantObr,
              fotoUrl,
              reporte.datoU,
              reporte.datoC,
              reporte.nombUser,
              reporte.lastUpdated,
              reporte.idTienda);
          print("Reporte insertado correctamente: $unic");
        } else {
          print("DATO UNICO ${reporte.datoU}");
          await editarReporte(
              reporte.idReporte,
              reporte.formato,
              reporte.nomDep,
              reporte.claveUbi,
              reporte.idProbl,
              reporte.nomProbl,
              reporte.idMat,
              reporte.nomMat,
              reporte.otro,
              reporte.cantMat,
              reporte.idObr,
              reporte.nomObr,
              reporte.otroObr,
              reporte.cantObr,
              reporte.datoU,
              reporte.foto,
              reporte.idTienda);
          print("El reporte ya existe en la base de datos, se ha actualizado: $unic");
        }
      } catch (e) {
        print("Error al procesar el reporte: ${reporte.datoU}, error: $e");
        insercionExitosa = false;
      }
    }

    await connection.close();
    return insercionExitosa;
  }
}
