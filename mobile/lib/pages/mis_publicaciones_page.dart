import 'package:flutter/material.dart';

import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import 'mascotas_page.dart';

/// Reutiliza la búsqueda y fija el autor; recrea el estado si cambia la cuenta.
class MisPublicacionesPage extends StatelessWidget {
  const MisPublicacionesPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
  });
  final AuthService auth;
  final PublicacionService service;
  final UbicacionService ubicacion;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (_, _) {
      if (auth.restaurando || !auth.autenticado) {
        return Scaffold(
          appBar: BarraSuperior(auth: auth, titulo: 'Mis publicaciones'),
          body: RequiereSesion(auth: auth, child: const SizedBox.shrink()),
        );
      }
      return MascotasPage(
        key: ValueKey(auth.usuario!.mascotero.id),
        auth: auth,
        service: service,
        ubicacion: ubicacion,
        soloMias: true,
      );
    },
  );
}
