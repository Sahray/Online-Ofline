import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class FirebaseStorageService {
  static Future<String?> uploadImage(File image) async {
    try {
      // Subir la imagen a Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(
        contentType: 'image/jpeg',
      );

      await ref.putFile(image, metadata);
      String downloadURL = await ref.getDownloadURL();

      print('Imagen cargada exitosamente. URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error al cargar la imagen: $e');
      return null;
    }
  }

  /*static Future<String?> uploadImage(File image) async {
    try {
      // Subir la imagen a Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      firebase_storage.SettableMetadata metadata =
          firebase_storage.SettableMetadata(
        contentType: 'image/jpeg',
      );

      await ref.putFile(image, metadata);
      String downloadURL = await ref.getDownloadURL();

      // Guardar la ruta de la imagen en el almacenamiento local solo si no existe
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> imagePaths = prefs.getStringList('imagePaths') ?? [];

      // Verificar si la ruta de la imagen ya está presente en la lista
      if (!imagePaths.contains(image.path)) {
        imagePaths.add(image.path);
        await prefs.setStringList('imagePaths', imagePaths);
      }

      // Guardar la URL de la imagen en la lista imageUrls
      List<String> imageUrls = prefs.getStringList('imageUrls') ?? [];
      imageUrls.add(downloadURL);
      await prefs.setStringList('imageUrls', imageUrls);

      print('Imagen cargada exitosamente. URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error al cargar la imagen: $e');
      return null;
    }
  }
*/
  static Future<bool> isValidImageUrl(String imageUrl) async {
    try {
      firebase_storage.Reference storageRef =
          firebase_storage.FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
}
