import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/colores_app.dart';
import '../models/auth_dto.dart';
import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/estado_mensaje.dart';
import '../widgets/seccion_formulario.dart';
import '../widgets/tarjeta_inicio.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key, required this.auth});
  final AuthService auth;
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _cargando = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.auth.miPerfil();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos cargar tu perfil.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _encabezado(ThemeData theme, UsuarioDto user) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ColoresApp.verde, ColoresApp.verdeClaro],
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          child: Text(
            user.mascotero.iniciales,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.mascotero.nombre} ${user.mascotero.apellido}',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Miembro de la comunidad',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _estadoEmail(ThemeData theme, bool confirmado) => Container(
    padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
    decoration: BoxDecoration(
      color: confirmado ? ColoresApp.verdeSuave : ColoresApp.ambarSuave,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          confirmado ? Icons.verified_rounded : Icons.error_outline_rounded,
          size: 15,
          color: confirmado ? ColoresApp.verde : ColoresApp.ambar,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            confirmado ? 'Email confirmado' : 'Email sin confirmar',
            style: theme.textTheme.labelMedium?.copyWith(
              color: confirmado ? ColoresApp.verde : ColoresApp.ambar,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _datos(ThemeData theme, UsuarioDto user) {
    final telefono = user.mascotero.telefono;
    Widget fila(IconData icono, Widget contenido) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: contenido),
      ],
    );
    return SeccionFormulario(
      titulo: 'Datos de la cuenta',
      child: Column(
        spacing: 12,
        children: [
          fila(
            Icons.email_rounded,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                _estadoEmail(theme, user.emailConfirmado),
              ],
            ),
          ),
          fila(
            Icons.call_rounded,
            Text(
              telefono?.isNotEmpty == true ? telefono! : 'Sin informar',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accesos() => SeccionFormulario(
    titulo: 'Accesos rápidos',
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Expanded(
            child: TarjetaInicio(
              titulo: 'Mis publicaciones',
              icono: Icons.list_alt_rounded,
              color: ColoresApp.azul,
              colorSuave: ColoresApp.azulSuave,
              onTap: () => Navigator.of(context).pushNamed('/mascotas/mias'),
            ),
          ),
          Expanded(
            child: TarjetaInicio(
              titulo: 'Recomendar un servicio',
              icono: Icons.recommend_rounded,
              color: ColoresApp.violeta,
              colorSuave: ColoresApp.violetaSuave,
              onTap: () =>
                  Navigator.of(context).pushNamed('/servicios/recomendar'),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Mi perfil'),
    body: ListenableBuilder(
      listenable: widget.auth,
      builder: (context, _) {
        final theme = Theme.of(context);
        final user = widget.auth.usuario;
        return ContenidoFormulario(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_cargando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_error != null)
                EstadoMensaje(
                  icono: Icons.cloud_off_rounded,
                  mensaje: _error!,
                  accion: 'Reintentar',
                  onAccion: _cargando ? null : _cargar,
                ),
              if (user != null) ...[
                _encabezado(theme, user),
                _datos(theme, user),
                _accesos(),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: widget.auth.ocupado
                      ? null
                      : () => cerrarSesion(context, widget.auth),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ] else if (!_cargando)
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Ingresar'),
                ),
            ],
          ),
        );
      },
    ),
  );
}
