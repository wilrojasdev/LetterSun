import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kellci/note.dart';
import 'package:vitality/vitality.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  List<Note> noteList = [];
  TextEditingController textController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  Future<void> _addTextToList() async {
    String newText = textController.text;
    DateTime now = DateTime.now();
    Note newNote = Note(text: newText, date: now);
    await _addNote(newNote.text, newNote.date); // Agregar a Firebase
    setState(() {
      textController.clear();
    });
  }

  Future<void> _loadNotes() async {
    QuerySnapshot snapshot = await _firestore.collection('notes').get();

    List<Note> notas = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Note(
        text: data['text'],
        date: DateTime.fromMicrosecondsSinceEpoch(
          (data['date'] as Timestamp).microsecondsSinceEpoch,
        ),
      );
    }).toList();
    notas.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      noteList = notas;
    });
  }

  Future<void> _addNote(String text, DateTime date) async {
    await _firestore.collection('notes').add({
      'text': text,
      'date': Timestamp.fromDate(date),
    });
    _loadNotes();
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _imageFuture = loadImage('assets/sun.png');
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
      backgroundColor: ui.Color.fromARGB(255, 251, 249, 227),
      appBar: AppBar(
        backgroundColor: ui.Color.fromARGB(255, 251, 218, 74),
        elevation: 4,
        shadowColor: Colors.black,
        title: Text(
          'Baúl de notas',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<ui.Image>(
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
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Déjame una nota expresando lo que sientas.',
                            style: GoogleFonts.acme(fontSize: 17),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: textController,
                            style: GoogleFonts.acme(),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu nota...',
                              labelStyle: GoogleFonts.acme(),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 41, 40, 41),
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 41, 40, 41)),
                              ),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 41, 40, 41)),
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (textController.text.isNotEmpty) {
                              _addTextToList();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 74, 142, 163),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Agregar',
                            style: GoogleFonts.acme(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: noteList.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                            'EEE, dd MMMM yyyy hh:mm a', 'es')
                                        .format(noteList[index].date),
                                    style: GoogleFonts.acme(color: Colors.grey),
                                  ),
                                  Text(
                                    noteList[index].text,
                                    style: GoogleFonts.acme(fontSize: 17),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
