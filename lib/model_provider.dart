import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kellci/galeria/carrusel.dart';
import 'package:path/path.dart' as Path;

class ModelProvider extends ChangeNotifier {
  List<Carrusel> carruselesList = [];
  String? carruselId;

  Map<String, bool> favoritos = {};

  get favo => favoritos;
  void setFavorito(String url, bool isFavorito) {
    favoritos[url] = isFavorito;
    // No llamar a notifyListeners aquí porque solo estamos configurando el estado inicial
  }

  Future<void> updateFavoriteStatus(
      String documentId, String fotoName, bool newStatus) async {
    DocumentReference docRef =
        FirebaseFirestore.instance.collection('carrules').doc(documentId);

    DocumentSnapshot docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      return; // Si el documento no existe, no hacer nada
    }

    // Obtener la lista actual de fotos
    List<dynamic> fotos = (docSnapshot.data() as Map<String, dynamic>)['fotos'];
    // Buscar la foto específica y actualizar su estado de 'favorito'
    bool updated = false;
    List<dynamic> updatedFotos = fotos.map((foto) {
      if (foto['foto'] == fotoName) {
        updated = true;
        return {'foto': fotoName, 'favorito': newStatus};
      }
      return foto;
    }).toList();

    // Si se actualizó alguna foto, actualizar el documento en Firestore
    if (updated) {
      await docRef.update({'fotos': updatedFotos});
    }
  }

  Future<void> getCarrules() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('carrules').get();

    List<Carrusel> carrulesList =
        querySnapshot.docs.map((doc) => Carrusel.fromFirestore(doc)).toList();

    for (var carrule in carrulesList) {
      for (var foto in carrule.fotos!) {
        setFavorito(foto['foto'], foto['favorito']);
      }
    }
    carrulesList.sort((a, b) => b.fecha!.compareTo(a.fecha!));

    carruselesList = carrulesList;
    notifyListeners();
  }

  Future<void> eliminarCarrusel(String idDocumento) async {
    try {
      await FirebaseFirestore.instance
          .collection('carrules')
          .doc(idDocumento)
          .delete();

      carruselesList.removeWhere((carrusel) => carrusel.id == idDocumento);
      notifyListeners();
    } catch (e) {
      print("Error al eliminar el documento: $e");
    }
  }

  Future<List<String>> subirFotosAFirebaseStorage(
      List<XFile> imagenesSeleccionadas) async {
    List<String> urls = [];

    for (var imagen in imagenesSeleccionadas) {
      final bytes = await imagen.readAsBytes();

      Reference storageRef =
          FirebaseStorage.instance.ref().child("galeria/${imagen.name}");

      final metadata = SettableMetadata(contentType: imagen.mimeType);
      final uploadTask =
          storageRef.putData(Uint8List.fromList(bytes), metadata);

      //  final uploadTask = storageRef.putData(bytes, metadata);
      await uploadTask.whenComplete(() async {
        final downloadUrl = await storageRef.getDownloadURL();
        urls.add(extractFileNameFromUrl(downloadUrl).toString());
      });
    }

    return urls;
  }

  Future<String> guardarDatosEnFirestore(
      String descripcion, List<String> urlsDeFotos) async {
    CollectionReference carrulesRef =
        FirebaseFirestore.instance.collection("carrules");

    // Crear una lista de mapas para las fotos
    List<Map<String, dynamic>> fotosMapList = urlsDeFotos.map((url) {
      String nombreFoto = Path.basename(url);
      return {"foto": nombreFoto, "favorito": true};
    }).toList();

    DocumentReference docRef = await carrulesRef.add({
      "fecha": FieldValue.serverTimestamp(),
      "descripcion": descripcion,
      "fotos": fotosMapList,
    });

    String carruselId = docRef.id;
    return carruselId;
  }

  Future<void> guardarFotosYDescripcion(
      String descripcion, List<XFile> imagenesSeleccionadas) async {
    try {
      List<String> urls =
          await subirFotosAFirebaseStorage(imagenesSeleccionadas);
      carruselId = await guardarDatosEnFirestore(descripcion, urls);

      carruselesList.add(Carrusel(
          id: carruselId,
          fecha: Timestamp.now(),
          descripcion: descripcion,
          fotosCache: imagenesSeleccionadas));
      carruselesList.sort((a, b) => b.fecha!.compareTo(a.fecha!));
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  String extractFileNameFromUrl(String url) {
    var decodedUrl = Uri.decodeFull(url);
    var uri = Uri.parse(decodedUrl);
    String path = uri.path;
    return path.split('/').last;
  }
}
