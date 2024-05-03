import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:vitality/vitality.dart';
import 'cardwidget.dart';
import 'mensaje.dart';

class CartasAnterioresButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      width: 35,
      child: FloatingActionButton(
        heroTag: "aw",
        backgroundColor: Colors.transparent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartasAnterioresScreen(),
            ),
          );
        },
        child: Lottie.asset('assets/letter.json',
            animate: true), // Icono de una carta
      ),
    );
  }
}

class CartasAnterioresScreen extends StatefulWidget {
  @override
  _CartasAnterioresScreenState createState() => _CartasAnterioresScreenState();
}

class _CartasAnterioresScreenState extends State<CartasAnterioresScreen> {
  List<Message>? _cartasAnteriores;

  List<String> icons = [
    "a1.json",
    "a2.json",
    "a4.json",
    "a5.json",
    "a6.json",
  ];
  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  @override
  void initState() {
    super.initState();
    _loadCartasAnteriores();
    _imageFuture = loadImage('assets/sun.png');
  }

  String getRandomCarta() {
    Random random = Random();
    int index = random.nextInt(icons.length);
    return icons[index];
  }

  DateTime parseDate(String dateString) {
    DateFormat format = DateFormat('dd/MM/yyyy');
    return format.parse(dateString);
  }

  Future<void> _loadCartasAnteriores() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('mensajes')
        .where('fecha', isLessThan: DateTime.now())
        .get();

    List<Message> cartas = querySnapshot.docs.map((doc) {
      Timestamp timestamp = (doc.data() as Map<String, dynamic>)['fecha'];
      DateTime date = timestamp.toDate();

      String content = (doc.data() as Map<String, dynamic>)['contenido'];
      String title = (doc.data() as Map<String, dynamic>)['titulo'];
      String song = (doc.data() as Map<String, dynamic>)['song'];
      int estado = (doc.data() as Map<String, dynamic>)['estado'];
      String id = doc.id;
      Message message = Message(date, content, title, song, estado, id);
      return message;
    }).toList();

    cartas.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _cartasAnteriores = cartas;
    });
  }

  Future<ui.Image> loadImage(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ui.Color.fromARGB(255, 251, 250, 227),
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black,
        backgroundColor: ui.Color.fromARGB(255, 251, 218, 74),
        title: Text(
          'Historial de Cartas',
          style: GoogleFonts.acme(
              fontSize: 20,
              color: Color.fromARGB(255, 250, 250, 250),
              shadows: [
                Shadow(
                  color: Color.fromARGB(255, 71, 71, 71),
                  blurRadius: 1,
                  offset: Offset(01, 1),
                )
              ]),
        ),
      ),
      body: _cartasAnteriores == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.amber,
              ),
            )
          : FutureBuilder<ui.Image>(
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.amber,
                  ));
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Vitality.randomly(
                        itemsCount: 30,
                        whenOutOfScreenMode: WhenOutOfScreenMode.Reflect,
                        randomItemsColors: const [Colors.yellow],
                        randomItemsBehaviours: [
                          ItemBehaviour(
                            shape: ShapeType.Image,
                            image: snapshot.data!,
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ListView.builder(
                        itemCount: _cartasAnteriores!.length,
                        itemBuilder: (context, index) {
                          Message carta = _cartasAnteriores![index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 2, top: 3, left: 5, right: 5),
                            child: Card(
                              color: Colors.white,
                              elevation: 5,
                              child: ListTile(
                                title: Text(
                                  carta.title
                                      .substring(0, carta.title.length - 1),
                                  style: GoogleFonts.acme(fontSize: 20),
                                ),
                                subtitle: Text(DateFormat('dd/MM/yyyy')
                                    .format(carta.date)),
                                trailing: Icon(
                                  Icons.favorite,
                                  color: Colors.pink,
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return cardWidget(message: carta);
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
