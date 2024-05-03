import 'dart:io';
import 'dart:ui' as ui;
import 'package:card_swiper/card_swiper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kellci/galeria/carrusel.dart';
import 'package:kellci/galeria/foto_card.dart';
import 'package:kellci/galeria/foto_info.dart';
import 'package:kellci/galeria/loading.dart';
import 'package:kellci/model_provider.dart';
import 'package:provider/provider.dart';
import 'package:vitality/vitality.dart';

class GaleriaPage extends StatefulWidget {
  const GaleriaPage({super.key});

  @override
  State<GaleriaPage> createState() => _GaleriaPageState();
}

class _GaleriaPageState extends State<GaleriaPage>
    with SingleTickerProviderStateMixin {
  List<Carrusel> carruselesList = [];
  late TabController _tabController;
  late ModelProvider model;
  Future<String> getDownloadURL(String imagePath) async {
    String downloadURL =
        await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    return downloadURL;
  }

  Future<ui.Image> loadImage(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes = data.buffer.asUint8List();
    ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Posterga la ejecución hasta después de construir el árbol de widgets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      model = Provider.of<ModelProvider>(context, listen: false);
      model.getCarrules();
    });
    _imageFuture = loadImage('assets/sun.png');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await model.getCarrules();
  }

  void _mostrarDialogoConfirmacion(BuildContext context, String idCarrusel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Borrar Carrusel',
            style: GoogleFonts.acme(),
          ),
          content: Text('¿Estás segura de que quieres eliminar este carrusel?',
              style: GoogleFonts.acme()),
          actions: <Widget>[
            TextButton(
              child:
                  Text('Cancelar', style: GoogleFonts.acme(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo sin hacer nada
              },
            ),
            TextButton(
              child: Text(
                'Eliminar',
                style: GoogleFonts.acme(
                    color: const Color.fromARGB(255, 161, 30, 21)),
              ),
              onPressed: () {
                // Aquí llamas a tu método para eliminar el carrusel
                model.eliminarCarrusel(idCarrusel);
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildAllPhotosView(ModelProvider model) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: model.carruselesList.isNotEmpty
          ? ListView.builder(
              itemCount: model.carruselesList.length,
              itemBuilder: (context, index) {
                final carrule = model.carruselesList[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {
                              _mostrarDialogoConfirmacion(context, carrule.id!);
                            },
                            icon: const Icon(Icons.delete)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              DateFormat('EEE, dd MMMM yyyy hh:mm a', 'es')
                                  .format(carrule.fecha!.toDate()),
                              style: GoogleFonts.acme(
                                  color:
                                      const Color.fromARGB(255, 116, 115, 115)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    carrule.fotos != null
                        ? FutureBuilder(
                            future:
                                Future.wait(carrule.fotos!.map((fotoMap) async {
                              String url = await getDownloadURL(
                                  'galeria/${fotoMap['foto']}');
                              return FotoInfo(
                                  url: url, favorito: fotoMap['favorito']);
                            })),
                            builder: (BuildContext context,
                                AsyncSnapshot<List<FotoInfo>> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ));
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const Text(
                                    'Error al cargar las imágenes');
                              }

                              return SizedBox(
                                height: 350,
                                child: Swiper(
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final fotoInfo = snapshot.data![index];

                                    return FotoCard(
                                        key: ValueKey(fotoInfo.url),
                                        fotoInfo: fotoInfo,
                                        carruleId: carrule.id!);
                                  },
                                  loop:
                                      snapshot.data!.length > 1 ? true : false,
                                  index: snapshot.data!.length > 1 ? 1 : 0,
                                  pagination: const SwiperPagination(),
                                  itemCount: snapshot.data!.length,
                                  viewportFraction: 0.6,
                                  scale: 0.8,
                                ),
                              );
                            },
                          )
                        : SizedBox(
                            height: 350,
                            child: Swiper(
                              itemBuilder: (BuildContext context, int index) {
                                final fotoInfo = carrule.fotosCache![index];

                                return FotoCard(
                                    isnew: true,
                                    fotoInfo: FotoInfo(
                                      foto: fotoInfo,
                                    ),
                                    carruleId: carrule.id);
                              },
                              loop:
                                  carrule.fotosCache!.length > 1 ? true : false,
                              index: carrule.fotosCache!.length > 1 ? 1 : 0,
                              pagination: const SwiperPagination(),
                              itemCount: carrule.fotosCache!.length,
                              viewportFraction: 0.6,
                              scale: 0.8,
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        carrule.descripcion!,
                        style: GoogleFonts.acme(fontSize: 17),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10),
                      child: Divider(),
                    )
                  ],
                );
              },
            )
          : const Center(
              child: Text('No hay fotos por mostrar'),
            ),
    );
  }

  Widget buildFavoritesView(ModelProvider model) {
    if (!hayFotosFavoritas(model)) {
      // Si no hay fotos favoritas, muestra el mensaje
      return const Center(child: Text('No hay fotos en favoritos mostrar'));
    }
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        itemCount: model.carruselesList.length,
        itemBuilder: (context, index) {
          final carrule = model.carruselesList[index];
          var favoriteFotos = [];
          if (carrule.fotos != null) {
            favoriteFotos =
                carrule.fotos!.where((foto) => foto['favorito']).toList();
          }
          return favoriteFotos.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('EEE, dd MMMM yyyy hh:mm a', 'es')
                              .format(carrule.fecha!.toDate()),
                          style: GoogleFonts.acme(
                              color: const Color.fromARGB(255, 116, 115, 115)),
                        ),
                      ),
                    ),
                    carrule.fotos != null
                        ? FutureBuilder(
                            future:
                                Future.wait(favoriteFotos.map((fotoMap) async {
                              String url = await getDownloadURL(
                                  'galeria/${fotoMap['foto']}');
                              return FotoInfo(
                                  url: url, favorito: fotoMap['favorito']);
                            })),
                            builder: (BuildContext context,
                                AsyncSnapshot<List<FotoInfo>> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                  color: Colors.amber,
                                ));
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return const Text(
                                    'Error al cargar las imágenes');
                              }

                              return SizedBox(
                                height: 350,
                                child: Swiper(
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final fotoInfo = snapshot.data![index];

                                    return FotoCard(
                                        key: ValueKey(fotoInfo.url),
                                        fotoInfo: fotoInfo,
                                        carruleId: carrule.id!);
                                  },
                                  loop:
                                      snapshot.data!.length > 1 ? true : false,
                                  index: snapshot.data!.length > 1 ? 1 : 0,
                                  pagination: const SwiperPagination(),
                                  itemCount: snapshot.data!.length,
                                  viewportFraction: 0.6,
                                  scale: 0.8,
                                ),
                              );
                            },
                          )
                        : SizedBox(
                            height: 350,
                            child: Swiper(
                              itemBuilder: (BuildContext context, int index) {
                                final fotoInfo = carrule.fotosCache![index];

                                return FotoCard(
                                    isnew: true,
                                    fotoInfo: FotoInfo(
                                      foto: fotoInfo,
                                    ),
                                    carruleId: carrule.id);
                              },
                              loop:
                                  carrule.fotosCache!.length > 1 ? true : false,
                              index: carrule.fotosCache!.length > 1 ? 1 : 0,
                              pagination: const SwiperPagination(),
                              itemCount: carrule.fotosCache!.length,
                              viewportFraction: 0.6,
                              scale: 0.8,
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        carrule.descripcion!,
                        style: GoogleFonts.acme(fontSize: 17),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0, right: 10),
                      child: Divider(),
                    )
                  ],
                )
              : SizedBox.shrink();
        },
      ),
    );
  }

  bool hayFotosFavoritas(ModelProvider model) {
    for (var carrule in model.carruselesList) {
      if (carrule.fotos != null) {
        var favoriteFotos =
            carrule.fotos!.where((foto) => foto['favorito']).toList();
        if (favoriteFotos.isNotEmpty) {
          return true; // Retorna true si encuentra al menos una foto favorita
        }
      } else {
        return true;
      }
    }
    return false; // Retorna false si no encuentra fotos favoritas
  }

  bool _isLoading = true; // Controlar la visibilidad del overlay de carga

  Future<void> _procesarAccion(
      descripcionController, imagenesSeleccionadas) async {
    await model.guardarFotosYDescripcion(
        descripcionController, imagenesSeleccionadas!);
    setState(() {
      _isLoading = true;
    });
  }

  void _mostrarDialogoDeSeleccionDeFotos(BuildContext context) {
    TextEditingController descripcionController = TextEditingController();
    List<XFile>? imagenesSeleccionadas = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Agregar Fotos",
                style: GoogleFonts.acme(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: descripcionController,
                            decoration: InputDecoration(
                              hintText: "Descripción",
                              hintStyle: GoogleFonts.acme(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: IconButton(
                            icon: const Icon(Icons.add_photo_alternate),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final List<XFile> imagenesTemporales =
                                  await picker.pickMultiImage();

                              setState(() {
                                imagenesSeleccionadas = imagenesTemporales;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    // Vista previa de las imágenes
                    imagenesSeleccionadas!.isNotEmpty
                        ? SizedBox(
                            height: 220,
                            width: 600,
                            child: GridView.builder(
                              shrinkWrap: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.7,
                                      crossAxisSpacing: 1,
                                      mainAxisSpacing: 1),
                              itemCount: imagenesSeleccionadas?.length ?? 0,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    FutureBuilder(
                                      future: imagenesSeleccionadas![index]
                                          .readAsBytes(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List<int>> snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.hasData) {
                                          return Image.memory(
                                            Uint8List.fromList(snapshot.data!),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return const Center(
                                              child: CircularProgressIndicator(
                                            color: Colors.amber,
                                          ));
                                        }
                                      },
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 10,
                                      child: SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: IconButton(
                                          alignment: Alignment.center,
                                          icon: const Align(
                                            alignment: Alignment.topCenter,
                                            child: Icon(
                                              Icons.cancel,
                                              size: 20,
                                              shadows: [
                                                Shadow(
                                                  color: Color.fromARGB(
                                                      192, 255, 255, 255),
                                                  blurRadius: 4,
                                                  offset: Offset(1, 1),
                                                )
                                              ],
                                            ),
                                          ),
                                          color: Color.fromARGB(255, 7, 7, 7),
                                          onPressed: () {
                                            setState(() {
                                              imagenesSeleccionadas!
                                                  .removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.grey)),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.acme(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        Colors.amber, // Cambiar el color del texto del botón
                  ),
                  child: _isLoading
                      ? Text(
                          "Agregar",
                          style: GoogleFonts.acme(
                              fontSize: 14,
                              color: ui.Color.fromARGB(255, 247, 245, 245),
                              shadows: [
                                Shadow(
                                  color: Color.fromARGB(255, 71, 71, 71),
                                  blurRadius: 1,
                                  offset: Offset(01, 1),
                                )
                              ]),
                        )
                      : const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                  onPressed: () async {
                    if (imagenesSeleccionadas!.isNotEmpty &&
                        descripcionController.text.isNotEmpty) {
                      setState(() {
                        _isLoading = false; // Activar el indicador de carga
                      });

                      _procesarAccion(
                              descripcionController.text, imagenesSeleccionadas)
                          .then((value) => Navigator.of(context).pop());
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor:
                              ui.Color.fromARGB(255, 250, 255, 183),
                          content: Text(
                            "Agrega una foto y descripción",
                            style: GoogleFonts.acme(
                              fontSize: 14,
                              color: ui.Color.fromARGB(255, 3, 3, 3),
                            ),
                          ),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior
                              .floating, // Hace que el SnackBar 'flote'
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ui.Color.fromARGB(255, 251, 250, 227),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromARGB(255, 35, 211, 79),
          onPressed: () {
            _mostrarDialogoDeSeleccionDeFotos(context);
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        appBar: AppBar(
          backgroundColor: ui.Color.fromARGB(255, 251, 218, 74),
          elevation: 4,
          shadowColor: Colors.black,
          bottom: TabBar(
            indicatorColor: const Color.fromARGB(255, 77, 76, 76),
            controller: _tabController,
            labelColor: const Color.fromARGB(255, 77, 76, 76),
            unselectedLabelColor: Colors.white,
            labelStyle: GoogleFonts.raleway(
                fontSize: 16,
                color: const Color.fromARGB(255, 97, 97, 97),
                shadows: [
                  const Shadow(
                    color: Color.fromARGB(255, 2, 2, 2),
                    blurRadius: 2,
                    offset: Offset(0.9, 0.7),
                  )
                ]),
            unselectedLabelStyle: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    color: Color.fromARGB(255, 2, 2, 2),
                    blurRadius: 2,
                    offset: Offset(0.9, 0.7),
                  )
                ]),
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Favoritos'),
            ],
          ),
          title: Text(
            'Carrusel de fotos',
            style: GoogleFonts.acme(
                fontSize: 22,
                color: ui.Color.fromARGB(255, 254, 254, 254),
                shadows: [
                  Shadow(
                    color: Color.fromARGB(255, 71, 71, 71),
                    blurRadius: 1,
                    offset: Offset(01, 1),
                  )
                ]),
          ),
        ),
        body: Stack(
          children: [
            FutureBuilder(
                future: _imageFuture,
                builder: ((context, snapshot) {
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
                })),
            Consumer<ModelProvider>(builder: (context, model, _) {
              return SizedBox(
                height: MediaQuery.sizeOf(context).height,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildAllPhotosView(model),
                    buildFavoritesView(model),
                  ],
                ),
              );
            }),
          ],
        ));
  }
}
