import 'package:app_inspections/models/images_model.dart';
import 'package:app_inspections/models/mano_obra.dart';
import 'package:app_inspections/models/materiales.dart';
import 'package:app_inspections/models/models.dart';
import 'package:app_inspections/models/problemas.dart';
import 'package:app_inspections/models/reporte_model.dart';
import 'package:app_inspections/models/usuarios.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart';

class DatabaseProvider {
  static Future<Database> openDB() async {
    return openDatabase(
        join(await getDatabasesPath(), 'conexsa.db'), //acceder a la bd
        onCreate: (db, version) async {
      //creación de la tabla problemas
      await db.execute(
          "CREATE TABLE problemas (id_probl INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, nom_probl TEXT, cod_probl TEXT, formato TEXT);");
      //creación de la tabla materiales
      await db.execute(
          "CREATE TABLE materiales (id_mat INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, nom_mat TEXT, zona TEXT);");
      //creación de tabla mano de obra
      await db.execute(
          "CREATE TABLE obra (id_obra INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, nom_obra TEXT);");
      //creación de tabla tiendas
      await db.execute(
          "CREATE TABLE tiendas (id_tienda INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, cod_tienda INTEGER, nom_tienda TEXT, dist_tienda TEXT, zona TEXT);");
      //creación de tabla usuarios
      await db.execute(
          "CREATE TABLE usuarios (id_usu INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, nombre TEXT NOT NULL, nom_usu TEXT NOT NULL, password TEXT NOT NULL, permiso INTEGER NOT NULL DEFAULT 0);");
      //tabla de imagenes
      await db.execute(
          "CREATE TABLE images (id_img INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, imagen TEXT, dato_unico_rep TEXT NOT NULL, id_tienda TEXT NOT NULL);");
      //creación de tabla reporte
      await db.execute(
          "CREATE TABLE reporte (id_rep INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, formato TEXT NOT NULL, nom_dep TEXT NOT NULL, clave_ubi TEXT NOT NULL, id_probl INTEGER NOT NULL, nom_probl TEXT, id_mat INTEGER, nom_mat TEXT, otro TEXT, cant_mat INTEGER, id_obra INTEGER, nom_obr TEXT, otro_obr TEXT, cant_obr INTEGER, foto TEXT, dato_unico TEXT NOT NULL, dato_comp TEXT NOT NULL, insertion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, nom_user TEXT NOT NULL, last_updated DATETIME, id_tienda INTEGER NOT NULL,"
          "FOREIGN KEY (id_probl) REFERENCES problemas(id_probl),"
          "FOREIGN KEY (id_mat) REFERENCES materiales(id_mat),"
          "FOREIGN KEY (id_obra) REFERENCES obra(id_obra),"
          "FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda));");
    }, version: 1);
  }

  //método para insertar la lista de problemas
  static Future<Future<int>> insertProblem(Problemas problema) async {
    Database database = await openDB();
    return database.insert("problemas", problema.toMap());
  }

  //método para insertar la lista de materiales
  static Future<Future<int>> insertMaterial(Materiales material) async {
    Database database = await openDB();
    return database.insert("materiales", material.toMap());
  }

  //método para insertar la lista de mano de obra
  static Future<Future<int>> insertManoObra(Obra obr) async {
    Database database = await openDB();
    return database.insert("obra", obr.toMap());
  }

  //método para insertar la lista de tiendas
  static Future<Future<int>> insertTiendas(Tiendas tienda) async {
    Database database = await openDB();
    return database.insert("tiendas", tienda.toMap());
  }

  //método para insertar la lista de usuarios
  static Future<Future<int>> insertUsuarios(Usuarios usuario) async {
    Database database = await openDB();
    return database.insert("usuarios", usuario.toMap());
  }

  // Método para insertar los datos del form de reporte
  static Future<int> insertReporte(Reporte reporte) async {
    Database database = await openDB();
    try {
      // Insertar el reporte en la base de datos local
      int id = await database.insert("reporte", reporte.toMap());
      return id;
    } catch (e) {
      // Manejar errores
      print("NO SE PUDO INSERTAR EL REPORTE $e");
      return -1; // Retornar un valor indicando un error, por ejemplo, -1
    }
  }

  //método para insertar imagenes en local
  static Future<Future<int>> insertImagenes(Images imagen) async {
    Database database = await openDB();
    return database.insert("images", imagen.toMap());
  }

  static Future<void> editarReporte(Reporte reporte) async {
    Database database = await openDB();

    // Iniciar transacción
    await database.transaction((txn) async {
      try {
        await txn.update(
          'reporte',
          {
            'formato': reporte.formato,
            'nom_dep': reporte.nomDep,
            'clave_ubi': reporte.claveUbi,
            'id_probl': reporte.idProbl,
            'nom_probl': reporte.nomProbl,
            'id_mat': reporte.idMat,
            'nom_mat': reporte.nomMat,
            'otro': reporte.otro,
            'cant_mat': reporte.cantMat,
            'id_obra': reporte.idObr,
            'nom_obr': reporte.nomObr,
            'otro_obr': reporte.otroObr,
            'cant_obr': reporte.cantObr,
            'foto': reporte.foto,
          },
          where: 'id_rep = ?',
          whereArgs: [reporte.idReporte],
        );
        int? id = reporte.idReporte;
        print("REPORTE EDITADO CORRECTAMENTE $id");
      } catch (e) {
        // Manejar el error adecuadamente (notificar al usuario, revertir cambios, etc.)
        print("Error al editar el reporte $e");
      }
    });
  }

  static Future<List<Problemas>> showProblemas() async {
    Database database = await openDB();
    final List<Map<String, dynamic>> problemasMap =
        await database.query("problemas");
    return List.generate(
        problemasMap.length,
        (i) => Problemas(
            id: problemasMap[i]['id_probl'],
            nombre: problemasMap[i]['nom_probl'],
            codigo: problemasMap[i]['cod_probl'],
            formato: problemasMap[i]['formato']));
  }

  //método para mostrar la lista de materiales en el form
  static Future<List<Materiales>> showMateriales() async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results =
          await database.rawQuery("SELECT * FROM materiales WHERE zona = 'na'");

      return results
          .map((row) => Materiales(id: row['id_mat'], nombre: row['nom_mat']))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    }
  }

  //método para mostrar la lista de materiales en el form
  static Future<List<Materiales>> showMaterialesSismo() async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database
          .rawQuery("SELECT * FROM materiales WHERE zona = 'sismica'");

      return results
          .map((row) => Materiales(id: row['id_mat'], nombre: row['nom_mat']))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    }
  }

  //método para mostrar la lista de mano de obra en el form
  static Future<List<Obra>> showObra() async {
    Database database = await openDB();
    final List<Map<String, dynamic>> obraMap = await database.query("obra");

    return List.generate(obraMap.length,
        (i) => Obra(id: obraMap[i]['id_obra'], nombre: obraMap[i]['nom_obra']));
  }

  //método para mostrar la lista de tiendas
  static Future<List<Tiendas>> showTiendas() async {
    Database database = await openDB();
    final List<Map<String, dynamic>> tiendasMap =
        await database.query("tiendas");
    return List.generate(
        tiendasMap.length,
        (i) => Tiendas(
            id: tiendasMap[i]['id_tienda'],
            codigo: tiendasMap[i]['cod_tienda'],
            nombre: tiendasMap[i]['nom_tienda'],
            distrito: tiendasMap[i]['dist_tienda'],
            zona: tiendasMap[i]['zona']));
  }

  //método para mostrar los usuarios y verificar si existen sino para insertarlos
  static Future<List<Usuarios>> showUsers() async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results =
          await database.rawQuery('SELECT * FROM usuarios');

      return results
          .map((row) => Usuarios(
              id: row['id_usu'],
              nombre: row['nombre'],
              nomUsu: row['nom_usu'],
              contrasena: row['password'],
              permiso: row['permiso']))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    }
  }

  //método para buscar tiendas por nombre
  static Future<List<Tiendas>> searchTiendas(String query) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM tiendas WHERE cod_tienda LIKE ? OR nom_tienda LIKE ?',
        ['%$query%', '%$query%'],
      );

      return results
          .map((row) => Tiendas(
                id: row['id_tienda'],
                codigo: row['cod_tienda'],
                nombre: row['nom_tienda'],
                distrito: row['dist_tienda'],
                zona: row['zona'],
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    }
  }

  static Future<List<Problemas>> obtenerDefectoPorId(int query) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM problemas WHERE id_probl = ?',
        [query],
      );

      return results
          .map((row) => Problemas(
                id: row['id_probl'],
                nombre: row['nom_probl'],
                codigo: row['cod_probl'],
                formato: row['formato'],
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Materiales>> obtenerMaterialPorId(int query) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM materiales WHERE id_mat = ?',
        [query],
      );

      return results
          .map((row) => Materiales(
                id: row['id_mat'],
                nombre: row['nom_mat'],
                zona: row['zona'],
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Obra>> obtenerObraPorId(int query) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM obra WHERE id_obra = ?',
        [query],
      );

      return results
          .map((row) => Obra(
                id: row['id_obra'],
                nombre: row['nom_obra'],
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Reporte>> mostrarReporte(int idtienda) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM reporte WHERE id_tienda LIKE ?',
        ['%$idtienda%'],
      );
      //print('despues de la consulta');
      if (kDebugMode) {
        print('Resultados de la consulta: $results');
      }

      return results.map((row) {
        return Reporte(
          idReporte: row['id_rep'] as int?,
          formato: row['formato'] as String?,
          nomDep: row['nom_dep'] as String?,
          claveUbi: row['clave_ubi'] as String?,
          idProbl: row['id_probl'] as int?,
          nomProbl: row['nom_probl'] as String?,
          idMat: row['id_mat'] as int?,
          nomMat: row['nom_mat'] as String?,
          otro: row['otro'] as String?,
          cantMat: row['cant_mat'] as int?,
          idObr: row['id_obra'] as int?,
          nomObr: row['nom_obr'] as String?,
          otroObr: row['otro_obr'] as String?,
          cantObr: row['cant_obr'] as int?,
          foto: row['foto'] as String?,
          datoU: row['dato_unico'] as String?,
          datoC: row['dato_comp'] as String?,
          nombUser: row['nom_user'] as String?,
          lastUpdated: row['lastUpdated'] as String?,
          idTienda: row['id_tienda'] as int?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Reporte>> mostrarReporteF1(int idtienda) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        "SELECT * FROM reporte WHERE id_tienda = ? AND formato = 'F1'",
        [idtienda],
      );
      if (kDebugMode) {
        print('Resultados de la consulta: $results');
      }

      return results.map((row) {
        return Reporte(
          idReporte: row['id_rep'] as int?,
          formato: row['formato'] as String?,
          nomDep: row['nom_dep'] as String?,
          claveUbi: row['clave_ubi'] as String?,
          idProbl: row['id_probl'] as int?,
          nomProbl: row['nom_probl'] as String?,
          idMat: row['id_mat'] as int?,
          nomMat: row['nom_mat'] as String?,
          otro: row['otro'] as String?,
          cantMat: row['cant_mat'] as int?,
          idObr: row['id_obra'] as int?,
          nomObr: row['nom_obr'] as String?,
          otroObr: row['otro_obr'] as String?,
          cantObr: row['cant_obr'] as int?,
          foto: row['foto'] as String?,
          datoU: row['dato_unico'] as String?,
          datoC: row['dato_comp'] as String?,
          nombUser: row['nom_user'] as String?,
          lastUpdated: row['lastUpdated'] as String?,
          idTienda: row['id_tienda'] as int?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al realizar la consulta: $e');
        const Text('No hay datos disponibles');
      }
      // Puedes mostrar un mensaje de error de otra manera en tu UI
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Reporte>> mostrarReporteF2(int idtienda) async {
    Database database = await openDB();
    try {
      final List<Map<String, dynamic>> results = await database.rawQuery(
        "SELECT * FROM reporte WHERE id_tienda = ? AND formato = 'F2'",
        [idtienda],
      );
      if (kDebugMode) {
        print('Resultados de la consulta: $results');
      }

      return results.map((row) {
        return Reporte(
          idReporte: row['id_rep'] as int?,
          formato: row['formato'] as String?,
          nomDep: row['nom_dep'] as String?,
          claveUbi: row['clave_ubi'] as String?,
          idProbl: row['id_probl'] as int?,
          nomProbl: row['nom_probl'] as String?,
          idMat: row['id_mat'] as int?,
          nomMat: row['nom_mat'] as String?,
          otro: row['otro'] as String?,
          cantMat: row['cant_mat'] as int?,
          idObr: row['id_obra'] as int?,
          nomObr: row['nom_obr'] as String?,
          otroObr: row['otro_obr'] as String?,
          cantObr: row['cant_obr'] as int?,
          foto: row['foto'] as String?,
          datoU: row['dato_unico'] as String?,
          datoC: row['dato_comp'] as String?,
          nombUser: row['nom_user'] as String?,
          lastUpdated: row['lastUpdated'] as String?,
          idTienda: row['id_tienda'] as int?,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error en la consulta: $e');
      }
      const Text('Comprueba tu conexión a internet');
      return [];
    } finally {
      try {
        await database.close();
      } catch (e) {
        if (kDebugMode) {
          print('Error al cerrar la conexión: $e');
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> mostrarCantidadesF1(
      int idTienda) async {
    Database database = await openDB();
    try {
      final results = await database.rawQuery('''
      SELECT nom_mat, SUM(cant_mat) as cantidad_total 
      FROM reporte 
      WHERE id_tienda = $idTienda AND formato = 'F1'
      GROUP BY nom_mat
    ''');

      // Filtrar los resultados para excluir registros donde nom_mat es nulo o vacío
      final filteredResults = results
          .where((row) => row['nom_mat'] != null && row['nom_mat'] != '');

      return filteredResults.toList();
    } catch (e) {
      // Manejar errores
      print('Error al ejecutar la consulta: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> mostrarCantidadesF2(
      int idTienda) async {
    Database database = await openDB();
    try {
      final results = await database.rawQuery('''
      SELECT nom_mat, SUM(cant_mat) as cantidad_total 
      FROM reporte 
      WHERE id_tienda = $idTienda AND formato = 'F2'
      GROUP BY nom_mat
    ''');

      // Filtrar los resultados para excluir registros donde nom_mat es nulo o vacío
      final filteredResults = results
          .where((row) => row['nom_mat'] != null && row['nom_mat'] != '');

      return filteredResults.toList();
    } catch (e) {
      // Manejar errores
      print('Error al ejecutar la consulta: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> mostrarCantidadesObra(
      int idTienda) async {
    Database database = await openDB();
    try {
      final results = await database.rawQuery('''
      SELECT nom_obr, SUM(cant_obr) as cantidad_total 
      FROM reporte 
      WHERE id_tienda = $idTienda AND formato = 'F1'
      GROUP BY nom_obr 
    ''');

      // Filtrar los resultados para excluir registros donde nom_mat es nulo o vacío
      final filteredResults = results
          .where((row) => row['nom_obr'] != null && row['nom_obr'] != '');

      return filteredResults.toList();
    } catch (e) {
      // Manejar errores
      print('Error al ejecutar la consulta: $e');
      return [];
    }
  }

  //vincular bd con postgre
  static Future<List<Reporte>> leerReportesDesdeSQLite() async {
    // Abrir la conexión a la base de datos SQLite
    Database database = await openDB();

    // Ejecutar una consulta para obtener los datos de la tabla 'reporte'
    final resultados = await database.query('reporte');

    // Mapear los resultados a objetos Reporte
    final reportes = resultados.map((row) => Reporte.fromMap(row)).toList();

    // Cerrar la conexión a la base de datos
    //await database.close();

    return reportes;
  }

  static Future<void> deleteReporte(int? idReporte) async {
    Database database = await openDB();
    await database.delete(
      'reporte', // Nombre de la tabla
      where: 'id_rep = ?',
      whereArgs: [idReporte],
    );
  }
}
