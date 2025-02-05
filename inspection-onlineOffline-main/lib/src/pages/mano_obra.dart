import 'package:flutter/material.dart';

class ManoObra extends StatefulWidget {
  const ManoObra({super.key});

  @override
  State<ManoObra> createState() => _ManoObraState();
}

class _ManoObraState extends State<ManoObra> {
  @override
  Widget build(BuildContext context) {
    String selectedFormato = "F1";

    return Dialog(
      // Configura la forma y el tamaño del diálogo según tus necesidades
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "AGREGAR DESCRIPCIÓN DE MANO DE OBRA",
                  style: TextStyle(
                    fontSize: 20, // Tamaño de fuente deseado
                    fontWeight: FontWeight
                        .bold, // Puedes ajustar el peso de la fuente si lo deseas
                  ),
                ),
                const SizedBox(height: 26), // Espacio entre los campos
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 16), // Espacio entre los campos
                DropdownButtonFormField(
                  value: selectedFormato,
                  onChanged: (newValue) {
                    setState(() {
                      selectedFormato = newValue!;
                    });
                  },
                  items: <String>['F1', 'F2']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration:
                      const InputDecoration(labelText: 'Formato (F1 o F2)'),
                ),

                const SizedBox(height: 25), // Espacio entre los campos
                ElevatedButton(
                  onPressed: () {
                    // Lógica para manejar la acción del botón
                  },
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
