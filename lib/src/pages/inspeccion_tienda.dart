import 'package:app_inspections/services/auth_service.dart';
import 'package:app_inspections/src/pages/f1.dart';
import 'package:app_inspections/src/pages/inicio_indv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InspeccionTienda extends StatefulWidget {
  final int initialTabIndex;
  final TabController? controller;

  const InspeccionTienda(
      {Key? key, required this.initialTabIndex, this.controller})
      : super(key: key);

  @override
  State<InspeccionTienda> createState() => _InspeccionTiendaState();
}

class _InspeccionTiendaState extends State<InspeccionTienda>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final String nombreTienda = arguments['nombreTienda'];
    int idTi = arguments['idTienda'];
    String zona = arguments['zona'];

    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 40.0, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, 'inicioInsp');
          },
        ),
        backgroundColor: const Color.fromRGBO(6, 6, 68, 1),
        title: Text(
          nombreTienda,
          style: const TextStyle(fontSize: 24.0, color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          indicatorColor: const Color.fromRGBO(169, 27, 96, 1),
          controller: controller,
          labelStyle: const TextStyle(fontSize: 20),
          unselectedLabelColor: Colors.white,
          unselectedLabelStyle: const TextStyle(fontSize: 20),
          tabs: const [
            Tab(
              child: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Text("Historial"),
                  ],
                ),
              ),
            ),
            Tab(
              child: SizedBox(
                width: 100,
                child: Text("Registro"),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: controller,
        children: [
          Inicio(
            idTienda: idTi,
            nomTienda: nombreTienda,
            admin: authService.isAdmin,
            zona: zona,
          ),
          F1Screen(
            idTienda: idTi,
            zona: zona,
          ),
        ],
      ),
    );
  }
}
