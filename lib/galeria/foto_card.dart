import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kellci/galeria/foto_info.dart';
import 'package:kellci/model_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as Path;

class FotoCard extends StatefulWidget {
  final FotoInfo fotoInfo;
  final String? carruleId;
  final bool isnew;
  const FotoCard(
      {Key? key, required this.fotoInfo, this.carruleId, this.isnew = false})
      : super(key: key);

  @override
  _FotoCardState createState() => _FotoCardState();
}

class _FotoCardState extends State<FotoCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Añadir esto

  String extractFileNameFromUrl(String url) {
    var decodedUrl = Uri.decodeFull(url);
    var uri = Uri.parse(decodedUrl);
    String path = uri.path;
    return path.split('/').last;
  }

  bool esFavorito(String url) {
    return favoritos[url] ?? false;
  }

  Map<String, bool> favoritos = {};

  String? carruselId;
  void toggleFavorito(String url, bool isFavorito) {
    setState(() {
      favoritos[url] = isFavorito;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ModelProvider favoritosModel =
        Provider.of<ModelProvider>(context, listen: false);
    favoritos = favoritosModel.favo;
    bool isFavorite;
    if (widget.isnew) {
      String fileName = Path.basename(widget.fotoInfo.foto!.path);
      isFavorite = esFavorito(widget.fotoInfo.url != null
          ? extractFileNameFromUrl(widget.fotoInfo.url!)
          : fileName);
    } else {
      isFavorite = esFavorito(extractFileNameFromUrl(widget.fotoInfo.url!));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9, top: 3),
      child: Card(
        elevation: 8,
        shadowColor: const Color.fromARGB(255, 0, 0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              widget.fotoInfo.url != null
                  ? Image.network(
                      widget.fotoInfo.url!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : FutureBuilder(
                      future: widget.fotoInfo.foto!.readAsBytes(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<int>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return Image.memory(
                            Uint8List.fromList(snapshot.data!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
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
                  right: 15,
                  bottom: 20,
                  child: GestureDetector(
                    onTap: () async {
                      String fileName;
                      if (widget.isnew) {
                        fileName = widget.fotoInfo.foto!.name;
                      } else {
                        fileName = extractFileNameFromUrl(widget.fotoInfo.url!);
                      }
                      toggleFavorito(fileName, !isFavorite);
                      await favoritosModel.updateFavoriteStatus(
                          widget.carruleId!, fileName, !isFavorite);
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Color.fromARGB(255, 255, 238, 0),
                      size: 35,
                      shadows: const [
                        BoxShadow(
                          color: Colors.black,
                          spreadRadius: 4,
                          blurRadius: 5,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
