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
    this.atenuada = false,
  });
  final PublicacionDto publicacion;
  final PublicacionService service;
  final bool esAutor;
  final FotoSeleccionada? pendiente;

  /// Aviso resuelto: la imagen se ve atenuada.
  final bool atenuada;
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

  /// Sin foto: fondo suave con el emoji de la especie.
  Widget _sinFoto(ThemeData theme, {String? mensaje}) => Container(
    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          iconosMascota[widget.publicacion.tipoMascota] ?? '🐾',
          style: const TextStyle(fontSize: 56),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: 6),
          Text(mensaje, style: theme.textTheme.bodySmall),
        ],
      ],
    ),
  );

  Widget _imagen(ThemeData theme) {
    if (_pendiente != null && widget.esAutor) {
      return Image.memory(
        _pendiente!.bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _sinFoto(theme, mensaje: 'No pudimos mostrar la vista previa.'),
      );
    }
    if (_url != null) {
      return Image.network(
        widget.service.urlFoto(_url!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            _sinFoto(theme, mensaje: 'No pudimos cargar la foto.'),
      );
    }
    return _sinFoto(theme);
  }

  /// Botones del autor sobre la imagen, abajo a la derecha.
  Widget _controles() {
    final estilo = FilledButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      foregroundColor: Colors.black87,
      visualDensity: VisualDensity.compact,
    );
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 6,
      children: [
        FilledButton.icon(
          style: estilo,
          onPressed: _ocupado ? null : _elegir,
          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
          label: Text(_url == null ? 'Agregar foto' : 'Cambiar foto'),
        ),
        if (_url != null)
          FilledButton.icon(
            style: estilo,
            onPressed: _ocupado ? null : _eliminar,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar foto'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: widget.atenuada ? 0.55 : 1,
                  child: _imagen(theme),
                ),
                if (widget.esAutor)
                  Positioned(left: 8, right: 8, bottom: 8, child: _controles()),
                if (widget.esAutor && _ocupado)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
        if (widget.esAutor && _error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const Text(
                  'Tu aviso ya está publicado. Podés volver a intentar la carga de la foto.',
                ),
                if (_pendiente != null)
                  TextButton.icon(
                    onPressed: _ocupado ? null : _subir,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar foto'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
