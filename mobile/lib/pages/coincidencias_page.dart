import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/coincidencias_publicacion.dart';

class CoincidenciasPage extends StatelessWidget {
  const CoincidenciasPage({
    super.key,
    required this.publicacion,
    required this.auth,
    required this.service,
  });
  final PublicacionDto publicacion;
  final AuthService auth;
  final PublicacionService service;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: auth, titulo: 'Posibles coincidencias'),
    body: ContenidoFormulario(
      child: ListenableBuilder(
        listenable: auth,
        builder: (_, _) => auth.usuario?.mascotero.id == publicacion.mascoteroId
            ? CoincidenciasPublicacion(
                publicacion: publicacion,
                auth: auth,
                service: service,
                paginada: true,
              )
            : const Text(
                'Ingresá con la cuenta que publicó este aviso para consultar sus coincidencias.',
              ),
      ),
    ),
  );
}
