import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class Carrusel {
  final String? id; // Agregar el campo para el ID del documento
  final Timestamp? fecha;
  final String? descripcion;
  final List<Map<String, dynamic>>? fotos;
  final List<XFile>? fotosCache;
  Carrusel(
      {this.id, this.fecha, this.descripcion, this.fotos, this.fotosCache});

  factory Carrusel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Carrusel(
      id: doc.id, // Obtener el ID del documento
      fecha: data['fecha'],
      descripcion: data['descripcion'] ?? '',
      fotos: List<Map<String, dynamic>>.from(data['fotos'] ?? []),
    );
  }
}
