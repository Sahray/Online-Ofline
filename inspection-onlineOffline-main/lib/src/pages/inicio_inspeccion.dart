import 'dart:async';
import 'package:app_inspections/models/tiendas.dart';
import 'package:app_inspections/search/search_delegate.dart';
import 'package:app_inspections/services/auth_service.dart';
import 'package:app_inspections/services/db_offline.dart';
import 'package:app_inspections/src/widgets/card_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InicioInspeccion extends StatelessWidget {
  const InicioInspeccion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color encabezado = const Color(0xFF060644);
    return Home(encabezado: encabezado);
  }
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.encabezado,
  });

  final Color encabezado;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Tiendas> tiendas = [];

  @override
  void initState() {
    super.initState();
    loadTiendas();
  }

  Future<void> loadTiendas() async {
    List<Tiendas> loadedTiendas = await DatabaseProvider.showTiendas();
    setState(() {
      tiendas = loadedTiendas;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 174, 174, 174),
      appBar: AppBar(
        backgroundColor: widget.encabezado,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text(
              'Inspecciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
          ],
        ),
        actions: [
          PopupMenuButton<PopupMenuEntry>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/inicio.png"),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      ' ${authService.currentUser}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text("Cerrar Sesión"),
                onTap: () {
                  authService.logout();
                  Navigator.pushNamedAndRemoveUntil(
                      context, 'login', (route) => false);
                },
              ),
            ],
          ),
        ],
        toolbarHeight: 110.0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 8.0, right: 8.0),
        child: SizedBox(
          height: 1000,
          child: CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      showSearch(
                        context: context,
                        delegate: TiendaSearchDelegate(),
                      );
                    },
                    icon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: tiendas.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: tiendas.length,
                          itemBuilder: (context, index) {
                            final dato = tiendas[index];
                            return ListTile(
                              title: Text('${dato.codigo} ${dato.nombre}'),
                              onTap: () {
                                String nombreTiendaSeleccionada =
                                    '${dato.codigo} ${dato.nombre}';
                                String zona = dato.zona;
                                if (zona == 'sismica') {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            const Text('Tienda Zona Sísmica'),
                                        content: const Text(
                                            'Seleccionaste una tienda de zona sísmica'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                'inspectienda',
                                                arguments: {
                                                  'nombreTienda':
                                                      nombreTiendaSeleccionada,
                                                  'idTienda': dato.id,
                                                  'admin': authService.isAdmin,
                                                  'zona': zona
                                                },
                                              );
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    'inspectienda',
                                    arguments: {
                                      'nombreTienda': nombreTiendaSeleccionada,
                                      'idTienda': dato.id,
                                      'admin': authService.isAdmin,
                                      'zona': zona
                                    },
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
