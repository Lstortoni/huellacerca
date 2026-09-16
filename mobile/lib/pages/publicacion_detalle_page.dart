import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';

class PublicacionDetallePage extends StatefulWidget {
  const PublicacionDetallePage({
    super.key,
    required this.id,
    required this.auth,
    required this.service,
  });
  final String id;
  final AuthService auth;
  final PublicacionService service;
  @override
  State<PublicacionDetallePage> createState() => _PublicacionDetallePageState();
}

class _PublicacionDetallePageState extends State<PublicacionDetallePage> {
  late Future<PublicacionDto> _future;
  bool _ocupado = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _future = widget.service.detalle(widget.id);
  }

  Future<void> _resolver() async {
    if (_ocupado) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿El caso está resuelto?'),
        content: const Text('El aviso seguirá visible con el estado Resuelta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final result = await widget.service.resolver(widget.id);
      if (mounted) setState(() => _future = Future.value(result));
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(
      auth: widget.auth,
      titulo: 'Detalle de la publicación',
    ),
    body: ContenidoFormulario(
      child: FutureBuilder<PublicacionDto>(
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
          final p = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.pets_outlined, size: 56),
              Text(p.titulo, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                '${tiposPublicacion[p.tipoPublicacion]} · ${tiposMascota[p.tipoMascota]} · ${estadosPublicacion[p.estado]}',
              ),
              const SizedBox(height: 16),
              Text(p.descripcion),
              const SizedBox(height: 16),
              Text('Fecha: ${fechaVisible(p.fechaSuceso)}'),
              Text('${p.localidad}, ${p.provincia}'),
              Text('Zona: ${p.zona}'),
              const SizedBox(height: 16),
              const Text(
                'Contacto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(p.informacionContacto),
              Text('Publicado por ${p.autor}'),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ListenableBuilder(
                listenable: widget.auth,
                builder: (_, _) =>
                    p.estado == 1 &&
                        widget.auth.usuario?.mascotero.id == p.mascoteroId
                    ? FilledButton(
                        onPressed: _ocupado ? null : _resolver,
                        child: Text(
                          _ocupado ? 'Guardando…' : 'Marcar como resuelta',
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    ),
  );
}
