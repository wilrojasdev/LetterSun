import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lottie/lottie.dart';
import 'package:material_dialogs/material_dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:material_dialogs/widgets/buttons/icon_outline_button.dart';

class TouchButton extends StatefulWidget {
  @override
  _TouchButtonState createState() => _TouchButtonState();
}

class _TouchButtonState extends State<TouchButton> {
  late DateTime _currentDate;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _lastDate = _currentDate;
  }

  void _createDocument() async {
    final collectionRef = FirebaseFirestore.instance.collection('toque');

    // Obtener el último documento ordenado por fecha de forma descendente
    final querySnapshot =
        await collectionRef.orderBy('fecha', descending: true).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastDocument = querySnapshot.docs.first;
      final lastDate =
          (lastDocument.data() as Map<String, dynamic>)['fecha'].toDate();

      // Verificar si la fecha actual es diferente a la fecha del último documento
      if (_currentDate.day == lastDate.day &&
          _currentDate.month == lastDate.month &&
          _currentDate.year == lastDate.year) {
        // Incrementar la cantidad en 1 en el documento existente
        final int currentCantidad =
            (lastDocument.data() as Map<String, dynamic>)['cantidad'];
        final updatedCantidad = currentCantidad + 1;

        await lastDocument.reference.update({'cantidad': updatedCantidad});

        setState(() {
          _lastDate = _currentDate; // Actualizar la última fecha registrada
        });
      } else {
        // Si la fecha actual es diferente, crear un nuevo documento en Firestore
        await collectionRef.add({
          'cantidad': 1,
          'fecha': Timestamp.fromDate(_currentDate),
        });

        setState(() {
          _lastDate = _currentDate; // Actualizar la última fecha registrada
        });
      }
    } else {
      // Si no hay ningún documento, crear uno nuevo
      await collectionRef.add({
        'cantidad': 1,
        'fecha': Timestamp.fromDate(_currentDate),
      });

      setState(() {
        _lastDate = _currentDate; // Actualizar la última fecha registrada
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: 80,
      child: FloatingActionButton(
        heroTag: "ds",
        backgroundColor: Colors.transparent,
        onPressed: () {
          _createDocument();
          Dialogs.materialDialog(
              color: Colors.white,
              msg: '¡Me alegra saber que estás aquí!',
              title: 'Has dejado tu huella',
              lottieBuilder: Lottie.asset(
                'assets/send.json',
                fit: BoxFit.contain,
              ),
              context: context,
              actions: [
                IconsButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'Regresar',
                  color: Colors.blue,
                  textStyle: TextStyle(color: Colors.white),
                  iconColor: Colors.white,
                ),
              ]);
        },
        child: Lottie.asset('assets/star.json', fit: BoxFit.cover),
      ),
    );
  }
}
