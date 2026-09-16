import 'package:flutter/material.dart';

import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';

class RecomendacionDetallePage extends StatefulWidget {
  const RecomendacionDetallePage({
    super.key,
    required this.id,
    required this.auth,
    required this.service,
  });
  final String id;
  final AuthService auth;
  final RecomendacionService service;
  @override
  State<RecomendacionDetallePage> createState() =>
      _RecomendacionDetallePageState();
}

class _RecomendacionDetallePageState extends State<RecomendacionDetallePage> {
  late Future<RecomendacionDto> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.service.detalle(widget.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(
      auth: widget.auth,
      titulo: 'Detalle de la recomendación',
    ),
    body: ContenidoFormulario(
      child: FutureBuilder<RecomendacionDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(mensajeError(snapshot.error!)),
                TextButton(
                  onPressed: () => setState(
                    () => _future = widget.service.detalle(widget.id),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          final r = snapshot.data!, p = r.prestador;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.storefront_outlined, size: 56),
              Text(p.nombre, style: Theme.of(context).textTheme.headlineMedium),
              Text('${p.rubro} · ${p.localidad}'),
              if (p.direccion?.isNotEmpty == true)
                SelectableText('Dirección: ${p.direccion}'),
              if (p.telefono?.isNotEmpty == true)
                SelectableText('Teléfono: ${p.telefono}'),
              if (p.enlace?.isNotEmpty == true) SelectableText(p.enlace!),
              const Divider(height: 32),
              Text(r.titulo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(r.descripcion),
              const SizedBox(height: 12),
              Text('Recomendado por ${r.autor}'),
            ],
          );
        },
      ),
    ),
  );
}
