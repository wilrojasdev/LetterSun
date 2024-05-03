import 'dart:async';
import 'dart:math';
import 'package:floating_bubbles/floating_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vitality/vitality.dart';
import 'dart:ui' as ui;
import 'Homepage.dart';

class initPage extends StatefulWidget {
  @override
  _initPageState createState() => _initPageState();
}

class _initPageState extends State<initPage> {
  List<String> lovePhrases = [
    "Eres increíble y capaz.",
    "Cada día es una nueva oportunidad.",
    "Tu dedicación es inspiradora.",
    "Tu actitud puede cambiar el mundo.",
    "Recuerda lo especial que eres.",
    "Eres fuente de inspiración.",
    "No te rindas, persevera.",
    "Tu presencia mejora el mundo, mi mundo.",
    "Eres una persona única y especial.",
    "Tus sueños pueden hacerse realidad.",
    "Confía en tus habilidades.",
    "El éxito está en tu determinación.",
    "Tienes el poder de cambiar el mundo.",
    "Cada paso te acerca a tus metas.",
    "Ama lo que haces y haz lo que amas.",
    "Hoy es un buen día para ser feliz.",
    "No hay límites para tus capacidades.",
    "Eres un ser humano asombroso.",
    "Nunca subestimes tu potencial.",
    "Las dificultades te hacen más fuerte.",
    "Sé amable contigo misma.",
    "Cada pequeño paso cuenta.",
    "No tengas miedo de brillar.",
    "El cambio comienza dentro de ti.",
    "Eres digna de todo lo bueno.",
    "Hoy es un buen día para sonreír.",
    "Tienes el poder de superar obstáculos.",
    "El futuro te espera con oportunidades.",
    "Eres más fuerte de lo que crees.",
  ];

  PageController _pageController = PageController();
  Timer? _timer;
  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  @override
  @override
  void initState() {
    super.initState();
    _imageFuture = loadImage('assets/sun.png');
    startCarousel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Detener el timer cuando el widget es eliminado
    _timer?.cancel();
    super.dispose();
  }

  void startCarousel() {
    // Iniciar el carrusel automático cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      // Avanzar al siguiente mensaje
      if (!_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ui.Color.fromARGB(255, 225, 230, 162),
              Color.fromARGB(255, 251, 250, 227),
            ],
          ),
        ),
        child: Center(
          child: Builder(builder: (context) {
            return FutureBuilder<ui.Image>(
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LetterSun',
                            style: GoogleFonts.dancingScript(
                              color: Colors.white,
                              fontSize: 55,
                              fontWeight: FontWeight.w800,
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

                          //a2
                          Lottie.asset(
                            'assets/cat1.json',
                            width: 300,
                            height: 300,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              '¡Hola, Nath!',
                              style: GoogleFonts.adamina(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(
                                        0.8), // Color y opacidad de la sombra
                                    offset: const Offset(
                                        2, 2), // Desplazamiento de la sombra
                                    blurRadius:
                                        3, // Radio de difuminado de la sombra
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          SizedBox(
                            height: 130,
                            child: PageView.builder(
                              controller: _pageController,
                              itemBuilder: (context, index) {
                                return Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.arrow_back_ios,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: const Color.fromARGB(
                                                101, 0, 0, 0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              lovePhrases[
                                                  index % lovePhrases.length],
                                              style: GoogleFonts.adamina(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Color.fromARGB(255, 0, 0, 0),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const BirthdayGiftApp()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 70, vertical: 10),
                            ),
                            child: Text(
                              'Ingresar',
                              style: GoogleFonts.acme(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 40, left: 20, right: 20, bottom: 1),
                            child: Text(
                              'He empezado a desarrollar esta aplicación exclusivamente para ti. Aquí encontrarás cada día un mensaje lleno de cariño, amor y motivación.',
                              style: GoogleFonts.acme(
                                  fontSize: 12,
                                  color: const Color.fromARGB(255, 0, 0, 0)),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                });
          }),
        ),
      ),
    );
  }
}
