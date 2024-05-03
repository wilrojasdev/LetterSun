import 'package:floating_bottom_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kellci/galeria/galeria.dart';
import 'package:kellci/home.dart';
import 'package:kellci/notas_page.dart';
import 'package:kellci/wish_page.dart';
import 'package:lottie/lottie.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'historial.dart';

class BirthdayGiftApp extends StatefulWidget {
  const BirthdayGiftApp({Key? key}) : super(key: key);

  @override
  _BirthdayGiftAppState createState() => _BirthdayGiftAppState();
}

class _BirthdayGiftAppState extends State<BirthdayGiftApp>
    with SingleTickerProviderStateMixin {
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

  int _currentIndex = 0;

  List<Widget> pages = [
    homepage(),
    GaleriaPage(),
    NotasPage(),
    CartasAnterioresScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 251, 250, 227),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        controller: FloatingBottomBarController(),
        bottomBar: [
          BottomBarItem(
            icon: Lottie.asset('assets/l5.json',
                height: 50, width: 55, fit: BoxFit.cover),
            iconSelected: SizedBox(),
            title: 'Hoy',
            titleStyle: GoogleFonts.acme(),
            dotColor: Colors.amber,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          BottomBarItem(
            icon: Lottie.asset('assets/camera.json',
                height: 36, width: 35, fit: BoxFit.cover),
            iconSelected: SizedBox(),
            title: 'Galeria',
            titleStyle: GoogleFonts.acme(),
            dotColor: Colors.amber,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          BottomBarItem(
            icon: Lottie.asset('assets/l2.json',
                height: 45, width: 45, fit: BoxFit.cover),
            iconSelected: SizedBox(),
            title: 'Notas',
            titleStyle: GoogleFonts.acme(),
            dotColor: Colors.amber,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          BottomBarItem(
            icon: Lottie.asset('assets/l8.json',
                height: 30, width: 30, fit: BoxFit.cover),
            iconSelected: SizedBox(),
            title: 'Historial',
            titleStyle: GoogleFonts.acme(),
            dotColor: Colors.amber,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
        bottomBarCenterModel: BottomBarCenterModel(
          centerBackgroundColor: Colors.amber,
          centerIcon: const FloatingCenterButton(
            child: Icon(
              Icons.bubble_chart,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          centerIconChild: [
            FloatingCenterButtonChild(
              child: Lottie.asset('assets/wish.json', height: 35, width: 35),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => WishlistPage(),
                  ),
                );
              },
            ),
            FloatingCenterButtonChild(
              child: Lottie.asset('assets/l10.json', height: 35, width: 35),
              onTap: () {},
            ),
            FloatingCenterButtonChild(
              child: Lottie.asset('assets/star.json', height: 35, width: 35),
              onTap: () {
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
                        color: Color.fromARGB(255, 35, 141, 211),
                        textStyle: TextStyle(color: Colors.white),
                        iconColor: Colors.white,
                      ),
                    ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
