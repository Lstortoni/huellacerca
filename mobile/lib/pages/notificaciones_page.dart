import 'package:flutter/material.dart';

import '../models/notificacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/notificacion_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/lista_paginada.dart';
import '../widgets/tarjeta_notificacion.dart';
import 'publicacion_detalle_page.dart';

/// Posibles coincidencias con los avisos propios. Tocar una la marca como
/// leída y abre el aviso que coincide; «Ver mi aviso» abre el propio.
class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({
    super.key,
    required this.auth,
    required this.notificaciones,
    required this.publicaciones,
  });
  final AuthService auth;
  final NotificacionService notificaciones;
  final PublicacionService publicaciones;
  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  bool _soloNoLeidas = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    widget.notificaciones.actualizar();
  }

  Future<void> _abrir(
    NotificacionDto n,
    String publicacionId,
    VoidCallback recargar,
  ) async {
    await widget.notificaciones.marcarLeida(n);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicacionDetallePage(
          id: publicacionId,
          auth: widget.auth,
          service: widget.publicaciones,
        ),
      ),
    );
    if (mounted) recargar();
  }

  Future<void> _marcarTodas() async {
    try {
      await widget.notificaciones.marcarTodas();
      if (mounted) setState(() => _revision++);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensajeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Notificaciones'),
    body: RequiereSesion(
      auth: widget.auth,
      child: ContenidoFormulario(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Todas')),
                ButtonSegment(value: true, label: Text('No leídas')),
              ],
              selected: {_soloNoLeidas},
              onSelectionChanged: (s) => setState(() {
                _soloNoLeidas = s.first;
                _revision++;
              }),
            ),
            ListenableBuilder(
              listenable: widget.notificaciones,
              builder: (_, _) => widget.notificaciones.noLeidas > 0
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _marcarTodas,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Marcar todas como leídas'),
                      ),
                    )
                  : const SizedBox(height: 12),
            ),
            ListaPaginada<NotificacionDto>(
              key: ValueKey('$_revision:$_soloNoLeidas'),
              cargar: (pagina) => widget.notificaciones.listar(
                pagina: pagina,
                soloNoLeidas: _soloNoLeidas,
              ),
              vacio: EstadoMensaje(
                icono: Icons.notifications_none_rounded,
                mensaje: _soloNoLeidas ? 'No tenés notificaciones sin leer.' : 'Todavía no tenés notificaciones. Te avisamos acá cuando aparezca una posible coincidencia con tus avisos.',
              ),
              itemBuilder: (n, recargar) => TarjetaNotificacion(
                notificacion: n,
                urlFoto: widget.publicaciones.urlFoto,
                onTap: () => _abrir(n, n.coincidente.id, recargar),
                onVerMiAviso: () => _abrir(n, n.publicacion.id, recargar),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
