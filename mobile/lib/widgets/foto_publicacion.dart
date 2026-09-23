import 'package:flutter/material.dart';

import '../models/foto_seleccionada.dart';
import '../models/publicacion_dto.dart';
import '../services/contracts/publicacion_service.dart';
import 'contenido_formulario.dart';

class MiniaturaPublicacion extends StatelessWidget {
  const MiniaturaPublicacion({
    super.key,
    required this.publicacion,
    required this.service,
    this.lado = 56,
  });
  final PublicacionDto publicacion;
  final PublicacionService service;
  final double lado;

  /// Sin foto (o si falla la carga) ocupa el mismo lugar con una huella.
  Widget _sinFoto(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: lado,
      height: lado,
      color: scheme.primaryContainer.withValues(alpha: 0.6),
      child: Icon(Icons.pets_rounded, size: lado * 0.45, color: scheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(lado / 6),
    child: publicacion.fotoUrl == null
        ? _sinFoto(context)
        : Image.network(
            service.urlFoto(publicacion.fotoUrl!),
            width: lado,
            height: lado,
            fit: BoxFit.cover,
            errorBuilder: (context, _, _) => _sinFoto(context),
          ),
  );
}

/// Mantiene el archivo pendiente para poder reintentar sin volver a crear el aviso.
class FotoPublicacion extends StatefulWidget {
  const FotoPublicacion({
    super.key,
    required this.publicacion,
    required this.service,
    required this.esAutor,
    this.pendiente,
  });
  final PublicacionDto publicacion;
  final PublicacionService service;
  final bool esAutor;
  final FotoSeleccionada? pendiente;
  @override
  State<FotoPublicacion> createState() => _FotoPublicacionState();
}

class _FotoPublicacionState extends State<FotoPublicacion> {
  FotoSeleccionada? _pendiente;
  String? _url, _error;
  bool _ocupado = false;
  @override
  void initState() {
    super.initState();
    _url = widget.publicacion.fotoUrl;
    _pendiente = widget.pendiente;
    if (_pendiente != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _subir();
      });
    }
  }

  Future<void> _elegir() async {
    var elegida = false;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final foto = await widget.service.elegirFoto();
      if (!mounted || !widget.esAutor) return;
      if (foto != null) {
        _pendiente = foto;
        elegida = true;
      }
    } catch (e) {
      if (mounted) _error = mensajeError(e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    if (mounted && elegida) await _subir();
  }

  Future<void> _subir() async {
    if (_ocupado || _pendiente == null || !widget.esAutor) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.service.subirFoto(widget.publicacion.id, _pendiente!);
      final actual = await widget.service.detalle(widget.publicacion.id);
      if (mounted) {
        setState(() {
          _url = actual.fotoUrl;
          _pendiente = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _eliminar() async {
    final acepta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar la foto?'),
        content: const Text('El aviso seguirá publicado sin foto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || acepta != true || !widget.esAutor) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.service.eliminarFoto(widget.publicacion.id);
      if (mounted) {
        setState(() {
          _url = null;
          _pendiente = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_pendiente != null && widget.esAutor)
        Image.memory(
          _pendiente!.bytes,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Text('No pudimos mostrar la vista previa.'),
        )
      else if (_url != null)
        Image.network(
          widget.service.urlFoto(_url!),
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(
            height: 80,
            child: Center(child: Text('No pudimos cargar la foto.')),
          ),
        )
      else
        const Icon(Icons.pets_outlined, size: 56),
      if (widget.esAutor) ...[
        if (_ocupado) const LinearProgressIndicator(),
        if (_error != null) ...[
          Text(_error!),
          const Text(
            'Tu aviso ya está publicado. Podés volver a intentar la carga de la foto.',
          ),
        ],
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _ocupado ? null : _elegir,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_url == null ? 'Agregar foto' : 'Cambiar foto'),
            ),
            if (_pendiente != null)
              TextButton(
                onPressed: _ocupado ? null : _subir,
                child: const Text('Reintentar foto'),
              ),
            if (_url != null)
              TextButton(
                onPressed: _ocupado ? null : _eliminar,
                child: const Text('Eliminar foto'),
              ),
          ],
        ),
      ],
    ],
  );
}
