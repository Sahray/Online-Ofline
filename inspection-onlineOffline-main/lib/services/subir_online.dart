import 'package:app_inspections/models/reporte_model.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:app_inspections/services/db_online.dart';
import 'package:app_inspections/src/pages/utils/check_internet_connection.dart';

final internetChecker = CheckInternetConnection();

Future<bool> insertarReporteOnline(Function(double) onProgress) async {
  bool insercionExitosa = false; // Inicializamos con false por defecto

  try {
    // Verificar si hay conexión a Internet
    final connectionStatus = await internetChecker.internetStatus().first;
    if (connectionStatus == ConnectionStatus.online) {
      print("CONEXION ACTIVA");

      // Si hay conexión, obtener los reportes locales
      final List<Reporte> reportes =
          await DatabaseProvider.leerReportesDesdeSQLite();

      if (reportes.isEmpty) {
        print("No hay reportes locales para sincronizar.");
        return false;
      }

      // Sincronizar los reportes locales con la base de datos remota
      final totalReportes = reportes.length;
      for (int i = 0; i < totalReportes; i++) {
        Reporte reporte = reportes[i];
        bool resultado =
            await DatabaseHelper.sincronizarConPostgreSQL([reporte]);

        if (!resultado) {
          print("Error al sincronizar el reporte con ID: ${reporte.idReporte}");
          insercionExitosa = false;
          break;
        }

        // Actualizar progreso
        onProgress((i + 1) / totalReportes);
      }

      // Si todos los reportes fueron sincronizados exitosamente
      insercionExitosa = true;
      print("SE INSERTO EL DATO EN POSTGRE $insercionExitosa");
    } else {
      print("No hay conexión a Internet.");
    }
  } catch (e) {
    print("No se pudo insertar el reporte online: $e");
  }

  return insercionExitosa;
}
