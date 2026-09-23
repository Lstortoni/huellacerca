import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/colores_app.dart';
import '../core/theme/tema_servicios.dart';
import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/gestion_recomendacion.dart';
import '../widgets/lista_paginada.dart';
import '../widgets/seccion_formulario.dart';
import '../widgets/tarjeta_prestador.dart';

class PrestadorDetallePage extends StatefulWidget {
  const PrestadorDetallePage({
    super.key,
    required this.id,
    required this.auth,
    required this.service,
    this.permitirGestion = false,
  });
  final String id;
  final AuthService auth;
  final RecomendacionService service;

  /// Solo se habilita al entrar desde «Recomendar un servicio».
  final bool permitirGestion;
  @override
  State<PrestadorDetallePage> createState() => _PrestadorDetallePageState();
}

class _PrestadorDetallePageState extends State<PrestadorDetallePage> {
  PrestadorDto? _prestador;
  String? _error;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = await widget.service.detalle(widget.id);
      if (mounted) {
        setState(() {
          _prestador = p;
          _error = null;
          _revision++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    }
  }

  Future<void> _copiar(String texto) async {
    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Copiado.')));
  }

  Widget _encabezado(ThemeData theme, PrestadorDto p) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ColoresApp.ambarSuave,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconoRubro(rubro: p.rubro, lado: 56, solido: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${p.rubro} · ${p.localidad}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.thumb_up_rounded, color: ColoresApp.ambar),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                p.textoRecomendaciones,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ColoresApp.ambar,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _contacto(ThemeData theme, PrestadorDto p) {
    final filas = [
      if (p.direccion?.isNotEmpty == true)
        (Icons.location_on_rounded, p.direccion!),
      if (p.telefono?.isNotEmpty == true) (Icons.call_rounded, p.telefono!),
      if (p.enlace?.isNotEmpty == true) (Icons.link_rounded, p.enlace!),
    ];
    if (filas.isEmpty) return const SizedBox.shrink();
    return SeccionFormulario(
      titulo: 'Contacto',
      child: Column(
        children: [
          for (final (icono, texto) in filas)
            Row(
              children: [
                Icon(icono, size: 20, color: theme.colorScheme.outline),
                const SizedBox(width: 10),
                Expanded(child: SelectableText(texto)),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => _copiar(texto),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Barras proporcionales: qué parte de quienes recomiendan destacó cada aspecto.
  Widget _aspectos(ThemeData theme, PrestadorDto p) {
    final aspectos = [...p.aspectos.where((a) => a.cantidad > 0)]
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
    if (aspectos.isEmpty) return const SizedBox.shrink();
    final total = p.totalRecomendaciones < 1 ? 1 : p.totalRecomendaciones;
    return SeccionFormulario(
      titulo: 'Lo que más destaca la comunidad',
      child: Column(
        spacing: 12,
        children: [
          for (final a in aspectos)
            Row(
              key: ValueKey('aspecto:${a.nombre}'),
              children: [
                Expanded(flex: 5, child: Text(a.nombre)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (a.cantidad / total).clamp(0, 1),
                      minHeight: 10,
                      color: ColoresApp.ambarBoton,
                      backgroundColor: ColoresApp.ambarSuave,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${a.cantidad}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _recomendadores(ThemeData theme, PrestadorDto p) => SeccionFormulario(
    titulo: 'Personas que lo recomiendan',
    child: ListaPaginada<MascoteroRecomiendaDto>(
      key: ValueKey(_revision),
      cargar: (pagina) => widget.service.recomendadores(p.id, pagina: pagina),
      itemBuilder: (persona, _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: ColoresApp.ambarSuave,
          foregroundColor: ColoresApp.ambar,
          child: Text(
            persona.nombre.isEmpty ? '?' : persona.nombre[0].toUpperCase(),
          ),
        ),
        title: Text(persona.nombre),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => TemaServicios(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final p = _prestador;
        return Scaffold(
          appBar: BarraSuperior(
            auth: widget.auth,
            titulo: 'Servicio recomendado',
          ),
          body: ContenidoFormulario(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  EstadoMensaje(
                    icono: Icons.cloud_off_rounded,
                    mensaje: _error!,
                    accion: 'Reintentar',
                    onAccion: _cargar,
                  ),
                if (p == null && _error == null)
                  const Center(child: CircularProgressIndicator()),
                if (p != null) ...[
                  _encabezado(theme, p),
                  // Desde «Recomendar un servicio» la acción va primero.
                  if (widget.permitirGestion)
                    SeccionFormulario(
                      titulo: 'Tu recomendación',
                      child: GestionRecomendacion(
                        prestadorId: p.id,
                        auth: widget.auth,
                        service: widget.service,
                        onChanged: _cargar,
                      ),
                    ),
                  _contacto(theme, p),
                  _aspectos(theme, p),
                  if (p.totalRecomendaciones > 0) _recomendadores(theme, p),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
