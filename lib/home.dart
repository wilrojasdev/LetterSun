import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:kellci/cardwidget.dart';
import 'package:lottie/lottie.dart';
import 'package:vitality/vitality.dart';

import 'mensaje.dart';

class homepage extends StatefulWidget {
  const homepage({super.key});

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> with TickerProviderStateMixin {
  List<String> cartas = ["c1.gif", "c4.json", "c5.json", "c6.json", "c7.json"];
  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  Message? availableMessage;
  int state = 0;
  bool _isCardShown = false;
  late DateTime _currentDate;
  late List<Message> _messages;
  @override
  void initState() {
    _currentDate = DateTime.now();
    _loadMessages();

    super.initState();
    _imageFuture = loadImage('assets/sun.png');
  }

  String getRandomCarta() {
    Random random = Random();
    int index = random.nextInt(cartas.length);
    return cartas[index];
  }

  Widget getCartaWidget(String carta) {
    if (carta.endsWith('.gif')) {
      return Column(
        children: [
          Text(
            "¡Hay una carta sin leer para ti!",
            style: GoogleFonts.acme(
                fontSize: 30,
                color: Color.fromARGB(255, 250, 250, 250),
                shadows: [
                  Shadow(
                    color: Color.fromARGB(255, 71, 71, 71),
                    blurRadius: 1,
                    offset: Offset(01, 1),
                  )
                ]),
          ),
          SizedBox(
              width: 250, height: 250, child: Image.asset('assets/$carta')),
        ],
      );
    } else if (carta.endsWith('.json')) {
      return Column(
        children: [
          Text(
            "¡Hay una carta sin leer para ti!",
            style: GoogleFonts.acme(
                fontSize: 30,
                color: Color.fromARGB(255, 250, 250, 250),
                shadows: [
                  Shadow(
                    color: Color.fromARGB(255, 71, 71, 71),
                    blurRadius: 1,
                    offset: Offset(01, 1),
                  )
                ]),
          ),
          SizedBox(
            width: 250,
            height: 250,
            child: Lottie.asset('assets/$carta'),
          ),
        ],
      );
    } else {
      return Container(); // Manejar otro tipo de archivo o caso inválido
    }
  }

  Future<void> _loadMessages() async {
    List<Message> messages = [];
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('mensajes').get();
    int? estado;
    querySnapshot.docs.forEach((doc) {
      Timestamp timestamp = (doc.data() as Map<String, dynamic>)['fecha'];
      DateTime date = timestamp.toDate();

      String content = (doc.data() as Map<String, dynamic>)['contenido'];
      String title = (doc.data() as Map<String, dynamic>)['titulo'];
      String song = (doc.data() as Map<String, dynamic>)['song'];
      estado = (doc.data() as Map<String, dynamic>)['estado'];
      String id = doc.id;
      Message message = Message(date, content, title, song, estado!, id);
      messages.add(message);
    });

    setState(() {
      _messages = messages;
      availableMessage = _getAvailableMessage();
      state == estado;
    });
  }

  Message? _getAvailableMessage() {
    for (var message in _messages) {
      if (_currentDate.year == message.date.year &&
          _currentDate.month == message.date.month &&
          _currentDate.day == message.date.day &&
          message.estado == 1) {
        setState(() {
          state = message.estado;
        });
        return message;
      }
    }

    return null;
  }

  String _selectedLottie = '';

  final List<String> _lottieAssets = [
    'assets/happy.json',
    'assets/smil.json',
    'assets/love.json',
    'assets/angry.json',
    'assets/bad.json',
    'assets/sad.json',
    'assets/sad.json',
  ];
  Future<ui.Image> loadImage(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ui.Color.fromARGB(255, 244, 252, 125),
            ui.Color.fromARGB(255, 250, 248, 234),
          ],
        ),
      ),
      child: Stack(
        children: [
          FutureBuilder<ui.Image>(
              future: _imageFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                    color: Colors.amber,
                  ));
                }
                return Positioned.fill(
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
                );
              }),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                height: 35,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () async {
                    if (!_isCardShown && availableMessage != null) {
                      await FirebaseFirestore.instance
                          .collection('mensajes')
                          .doc(availableMessage!.id)
                          .update({'estado': 0});
                      setState(() {
                        state = 0;
                      });
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return cardWidget(message: availableMessage!);
                        },
                      );
                    }
                  },
                  child: Center(
                    child: state != 1
                        ? Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Text(
                              '¡Vuelve mañana por otra carta!',
                              style: GoogleFonts.acme(
                                fontSize: 27,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.w400,
                                decorationThickness: 0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    offset: const Offset(1, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : getCartaWidget(getRandomCarta()),
                  ),
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color.fromARGB(144, 34, 34, 34),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '¿Cómo me siento hoy?',
                          style: GoogleFonts.acme(
                            fontSize: 20,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w400,
                            decorationThickness: 0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(
                                    0.5), // Color y opacidad de la sombra
                                offset: const Offset(
                                    2, 2), // Desplazamiento de la sombra
                                blurRadius:
                                    3, // Radio de difuminado de la sombra
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildSelectedLottie(),
                      _buildLottieList(),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSelectedLottie() {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Center(
          child: _selectedLottie.isNotEmpty
              ? Lottie.asset(
                  _selectedLottie,
                  width: 85,
                  height: 85,
                )
              : const SizedBox.shrink()),
    );
  }

  Widget _buildLottieList() {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: SizedBox(
        width: 155,
        height: 85,
        child: Center(
          child: GridView.builder(
            itemCount: _lottieAssets.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLottie = _lottieAssets[index];
                  });
                },
                child: Lottie.asset(
                  _lottieAssets[index],
                  width: 30,
                  height: 30,
                ),
              );
            },
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 10),
          ),
        ),
      ),
    );
  }
}
