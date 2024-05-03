import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kellci/wish.dart';
import 'package:vitality/vitality.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Wish> _wishes = [];
  late Future<ui.Image> _imageFuture; // Variable para almacenar la imagen

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWishes();
    _imageFuture = loadImage('assets/sun.png');
  }

  Future<void> _loadWishes() async {
    QuerySnapshot snapshot = await _firestore.collection('wishes').get();

    List<Wish> wishes = snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Wish(
        id: doc.id,
        text: data['text'],
        date: DateTime.fromMicrosecondsSinceEpoch(
          (data['date'] as Timestamp).microsecondsSinceEpoch,
        ),
        status: data['status'],
      );
    }).toList();

    setState(() {
      _wishes = wishes;
    });
  }

  Future<void> _addWish(String text, DateTime date, String status) async {
    await _firestore.collection('wishes').add({
      'text': text,
      'date': Timestamp.fromDate(date),
      'status': status,
    });
    _loadWishes();
  }

  Future<void> _updateWish(
      String id, String text, DateTime date, String status) async {
    await _firestore.collection('wishes').doc(id).update({
      'text': text,
      'date': Timestamp.fromDate(date),
      'status': status,
    });
    _loadWishes();
  }

  Future<void> _deleteWish(String id) async {
    await _firestore.collection('wishes').doc(id).delete();
    _loadWishes();
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
      backgroundColor: ui.Color.fromARGB(255, 251, 247, 227),
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black,
        backgroundColor: ui.Color.fromARGB(255, 251, 218, 74),
        title: Text(
          'Lista de Deseos',
          style: GoogleFonts.acme(fontSize: 20, color: Colors.white, shadows: [
            Shadow(
              color: Color.fromARGB(255, 71, 71, 71),
              blurRadius: 1,
              offset: Offset(01, 1),
            )
          ]),
        ),
        bottom: TabBar(
          indicatorColor: const Color.fromARGB(255, 77, 76, 76),
          controller: _tabController,
          labelColor: const Color.fromARGB(255, 77, 76, 76),
          unselectedLabelColor: Colors.white,
          labelStyle: GoogleFonts.raleway(
              fontSize: 16,
              color: const Color.fromARGB(255, 97, 97, 97),
              shadows: [
                Shadow(
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
                Shadow(
                  color: Color.fromARGB(255, 2, 2, 2),
                  blurRadius: 2,
                  offset: Offset(0.9, 0.7),
                )
              ]),
          tabs: [
            Tab(text: 'En Progreso'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Cumplidos'),
          ],
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
          TabBarView(
            controller: _tabController,
            children: [
              _buildWishlist('En progreso'),
              _buildWishlist('Pendiente'),
              _buildWishlist('Cumplido'),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 35, 211, 79),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddWishDialog(onSave: _addWish),
          );
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWishlist(String status) {
    List<Wish> wishes = _wishes.where((wish) => wish.status == status).toList();
    if (wishes.isEmpty)
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: Text('No hay deseos en esta sección.')),
      );

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: wishes.length,
        itemBuilder: (context, index) {
          Wish wish = wishes[index];

          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ViewWishDialog(
                  wish: wish,
                  onUpdate: _updateWish,
                  onDelete: _deleteWish,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors
                    .white, // Si quieres un color de fondo diferente, cámbialo aquí
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0,
                        3), // Cambiar la dirección de la sombra aquí si es necesario
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(wish.date),
                    style: GoogleFonts.acme(fontSize: 15),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        _trimText(
                          wish.text,
                          77,
                        ),
                        style: GoogleFonts.acme(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _trimText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return text.substring(0, maxLength) + '...';
    }
  }
}

class AddWishDialog extends StatefulWidget {
  final Function(String, DateTime, String) onSave;

  AddWishDialog({required this.onSave});

  @override
  _AddWishDialogState createState() => _AddWishDialogState();
}

class _AddWishDialogState extends State<AddWishDialog> {
  TextEditingController _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _status = 'Pendiente';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Nuevo Deseo',
        style: GoogleFonts.acme(fontSize: 20),
      ),
      content: Form(
        key: _formKey, // Vincula el _formKey con el Form
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelStyle: GoogleFonts.acme(
                  fontSize: 16,
                  color: Color.fromARGB(255, 58, 57, 57),
                ),
                labelText: 'Deseo',
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde cuando está seleccionado
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Escribe el deseo antes de guardarlo.';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: _status,
              onChanged: (String? newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
              items: ['Cumplido', 'En progreso', 'Pendiente']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.acme(
                      fontSize: 16,
                      color: Color.fromARGB(255, 58, 57, 57),
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Estado',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                ), // Cambiar el color del label
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde cuando está seleccionado
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancelar',
            style: GoogleFonts.acme(
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ui.Color.fromARGB(
                255, 175, 175, 175), // Cambiar el color del fondo del botón
            // Cambiar el color del texto del botón
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _textController.text,
                _selectedDate,
                _status,
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor:
                Colors.amber, // Cambiar el color del texto del botón
          ),
          child: Text(
            'Guardar',
            style:
                GoogleFonts.acme(fontSize: 17, color: Colors.white, shadows: [
              const Shadow(
                color: Color.fromARGB(255, 71, 71, 71),
                blurRadius: 1,
                offset: Offset(01, 1),
              )
            ]),
          ),
        ),
      ],
    );
  }
}

class ViewWishDialog extends StatelessWidget {
  final Wish wish;
  final Function(String, String, DateTime, String) onUpdate;
  final Function(String) onDelete;

  ViewWishDialog({
    required this.wish,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Deseo',
            style: GoogleFonts.acme(fontSize: 25),
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(wish.date),
            style: GoogleFonts.acme(fontSize: 20),
          ),
        ],
      ),
      content: Text(
        wish.text,
        style: GoogleFonts.acme(fontSize: 18),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => EditWishDialog(
                wish: wish,
                onUpdate: onUpdate,
              ),
            );
          },
          icon: Icon(Icons.edit),
        ),
        IconButton(
          color: Colors.red,
          onPressed: () {
            onDelete(wish.id);
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.delete),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cerrar',
            style:
                GoogleFonts.acme(fontSize: 20, color: Colors.white, shadows: [
              Shadow(
                color: Color.fromARGB(255, 71, 71, 71),
                blurRadius: 1,
                offset: Offset(1, 1),
              )
            ]),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.amber, // Cambiar el color del fondo del botón
            // Cambiar el color del texto del botón
          ),
        ),
      ],
    );
  }
}

class EditWishDialog extends StatefulWidget {
  final Wish wish;
  final Function(String, String, DateTime, String) onUpdate;

  EditWishDialog({required this.wish, required this.onUpdate});

  @override
  _EditWishDialogState createState() => _EditWishDialogState();
}

class _EditWishDialogState extends State<EditWishDialog> {
  TextEditingController _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _status = 'Pendiente';
  final _formKey = GlobalKey<FormState>(); // Agregar el GlobalKey

  @override
  void initState() {
    super.initState();
    _textController.text = widget.wish.text;
    _selectedDate = widget.wish.date;
    _status = widget.wish.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Editar Deseo',
        style: GoogleFonts.acme(fontSize: 20),
      ),
      content: Form(
        key: _formKey, // Vincula el _formKey con el Form
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelStyle: GoogleFonts.acme(
                  fontSize: 16,
                  color: Color.fromARGB(255, 58, 57, 57),
                ),
                labelText: 'Deseo',
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde cuando está seleccionado
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Escribe el deseo antes de guardarlo.';
                }
                return null;
              },
            ),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: _status,
              onChanged: (String? newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
              items: ['Cumplido', 'En progreso', 'Pendiente']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.acme(
                      fontSize: 16,
                      color: Color.fromARGB(255, 58, 57, 57),
                    ),
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Estado',
                labelStyle: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde normal
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.amber,
                  ), // Cambiar el color del borde cuando está seleccionado
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancelar',
            style: GoogleFonts.acme(
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ui.Color.fromARGB(
                255, 141, 140, 140), // Cambiar el color del fondo del botón
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onUpdate(
                widget.wish.id,
                _textController.text,
                _selectedDate,
                _status,
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor:
                  Colors.amber // Cambiar el color del texto del botón
              ),
          child: Text(
            'Guardar',
            style: GoogleFonts.acme(
              fontSize: 17,
              color: Colors.white,
              shadows: [
                const Shadow(
                  color: Color.fromARGB(255, 71, 71, 71),
                  blurRadius: 1,
                  offset: Offset(01, 1),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
