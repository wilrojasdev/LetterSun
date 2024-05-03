import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'mensaje.dart';

import 'package:path_provider/path_provider.dart';

class cardWidget extends StatefulWidget {
  final Message message;

  cardWidget({Key? key, required this.message}) : super(key: key);

  @override
  State<cardWidget> createState() => _cardWidgetState();
}

class _cardWidgetState extends State<cardWidget> {
  double _revealPercent = 0.0;
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _downloadAndPlayAudio();
  }

  Future<void> _downloadAndPlayAudio() async {
    // Obtener la referencia al archivo en Firebase Storage
    final Reference ref =
        FirebaseStorage.instance.ref('/${widget.message.song}');

    try {
      // Obtener la URL de descarga del archivo
      final url = await ref.getDownloadURL();

      // Cargar el archivo de audio desde la URL
      await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));

      // Reproducir el audio
      _player.play();
    } catch (e) {
      // Manejar cualquier error que pueda ocurrir durante la descarga o reproducción
      print("Error al descargar o reproducir el audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.zero, // Elimina el padding alrededor del Container
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/R.png'), // Ruta de la imagen PNG
            fit: BoxFit.cover,
            alignment:
                Alignment.center, // Ajusta la imagen al centro del Container
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Para ajustar el tamaño del diálogo al contenido
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.message.title,
                    style: GoogleFonts.caveat(
                      fontSize: 25,
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      height: 3,
                      decorationThickness: 0,
                    ),
                    maxLines:
                        1, // Establece el número máximo de líneas mostradas
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                widget.message.content,
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 2,
                  decorationThickness: 0,
                ),
                maxLines: 13, // Establece el número máximo de líneas mostradas
                overflow: TextOverflow.ellipsis,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'WARS',
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    height: 2,
                    decorationThickness: 0,
                  ),
                  maxLines:
                      13, // Establece el número máximo de líneas mostradas
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () {
                      if (!_player.playing) {
                        _player.play();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.pause),
                    onPressed: () {
                      if (_player.playing) {
                        _player.pause();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
