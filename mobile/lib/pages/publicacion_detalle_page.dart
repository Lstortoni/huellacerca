import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colores_app.dart';
import '../core/theme/colores_aviso.dart';
import '../core/util/contacto.dart';
import '../widgets/botones_contacto.dart';
import '../models/publicacion_dto.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/etiqueta_aviso.dart';
import '../widgets/seccion_formulario.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/caracteristicas_publicacion.dart';
import '../widgets/coincidencias_publicacion.dart';
import '../widgets/foto_publicacion.dart';
import '../models/foto_seleccionada.dart';

class PublicacionDetallePage extends StatefulWidget {
  const PublicacionDetallePage({
    super.key,
    required this.id,
    required this.auth,
    required this.service,
    this.fotoPendiente,
  });
  final String id;
  final FotoSeleccionada? fotoPendiente;
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
      if (mounted) {
        setState(() {
          _future = Future.value(result);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Contacto copiado.')));
  }

  Widget _avisoResuelto(ThemeData theme) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ColoresAviso.resuelta.fondo,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(ColoresAviso.resuelta.icono, color: ColoresAviso.resuelta.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Este caso fue resuelto',
            style: theme.textTheme.titleSmall?.copyWith(
              color: ColoresAviso.resuelta.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chipMascota(ThemeData theme, int tipo) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '${iconosMascota[tipo] ?? ''} ${tiposMascota[tipo] ?? ''}',
      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
    ),
  );

  Widget _datos(ThemeData theme, PublicacionDto p) {
    Widget fila(IconData icono, String texto) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: theme.textTheme.bodyLarge)),
      ],
    );
    return SeccionFormulario(
      titulo: 'Datos del aviso',
      child: Column(
        spacing: 10,
        children: [
          fila(
            Icons.event_rounded,
            '${p.resumenFecha} · ${fechaVisible(p.fechaReferencia)}',
          ),
          fila(Icons.location_on_rounded, '${p.localidad}, ${p.provincia}'),
          if (p.zona.isNotEmpty) fila(Icons.explore_rounded, 'Zona: ${p.zona}'),
        ],
      ),
    );
  }

  /// Bloque destacado: es la acción principal de quien lee el aviso.
  Widget _contacto(ThemeData theme, PublicacionDto p) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: ColoresApp.verdeSuave,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contacto',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.call_rounded, color: ColoresApp.verde),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    p.informacionContacto,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar contacto',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () => _copiar(p.informacionContacto),
                ),
              ],
            ),
            if (telefonoEn(p.informacionContacto) case final telefono?) ...[
              const SizedBox(height: 4),
              BotonesContacto(
                llamar: () => widget.service.llamar(telefono),
                whatsapp: () => widget.service.escribirPorWhatsApp(
                  telefono,
                  'Hola, te escribo por el aviso de ${p.titulo} en Huella Cerca.',
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'Publicado por ${p.autor}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// Acciones y consultas exclusivas del autor.
  Widget _tuAviso(ThemeData theme, PublicacionDto p) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SeccionFormulario(
        titulo: 'Tu aviso',
        subtitulo: p.estado == 1
            ? 'Podés cambiar la foto desde la imagen de arriba.'
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.estado == 1)
              FilledButton.icon(
                onPressed: _ocupado ? null : _resolver,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(_ocupado ? 'Guardando…' : 'Marcar como resuelta'),
              )
            else
              const Text('Marcaste este aviso como resuelto.'),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      if (p.estado == 1)
        CoincidenciasPublicacion(
          key: ValueKey(p.id),
          publicacion: p,
          auth: widget.auth,
          service: widget.service,
        )
      else ...[
        const SizedBox(height: 10),
        Text('Posibles coincidencias', style: theme.textTheme.titleLarge),
        const Text(
          'Este aviso está resuelto. Ya no se consultan posibles coincidencias.',
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Detalle del aviso'),
    body: ContenidoFormulario(
      child: FutureBuilder<PublicacionDto>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EstadoMensaje(
              icono: Icons.cloud_off_rounded,
              mensaje: mensajeError(snapshot.error!),
              accion: 'Reintentar',
              onAccion: () => setState(() {
                _future = widget.service.detalle(widget.id);
              }),
            );
          }
          final theme = Theme.of(context);
          final p = snapshot.data!;
          final resuelta = p.estado == 2;
          return ListenableBuilder(
            listenable: widget.auth,
            builder: (context, _) {
              final esAutor =
                  widget.auth.usuario?.mascotero.id == p.mascoteroId;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (resuelta) _avisoResuelto(theme),
                  FotoPublicacion(
                    key: ValueKey('foto-${p.id}'),
                    publicacion: p,
                    service: widget.service,
                    esAutor: esAutor,
                    pendiente: widget.fotoPendiente,
                    atenuada: resuelta,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.titulo,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      EtiquetaAviso.tipo(p.tipoPublicacion),
                      _chipMascota(theme, p.tipoMascota),
                      if (resuelta) const EtiquetaAviso.resuelta(),
                    ],
                  ),
                  // Difundir es lo primero que se hace ante una mascota perdida.
                  if (!resuelta) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => widget.service.compartir(p),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir aviso'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _datos(theme, p),
                  SeccionFormulario(
                    titulo: 'Descripción',
                    child: Text(
                      p.descripcion,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (p.caracteristicas.isNotEmpty)
                    CaracteristicasPublicacion(
                      key: ValueKey('${p.id}:${p.tipoMascota}'),
                      publicacion: p,
                      service: widget.service,
                    ),
                  _contacto(theme, p),
                  if (esAutor) _tuAviso(theme, p),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}
