import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../services/contracts/auth_service.dart';

/// Cierra la sesión, vuelve al inicio e informa si el servidor no confirmó.
Future<void> cerrarSesion(BuildContext context, AuthService auth) async {
  await auth.logout();
  if (!context.mounted) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
  if (auth.aviso != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(auth.aviso!)));
  }
}

/// Componente compartido: se coloca en el appBar de cada Scaffold.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const BarraSuperior({
    super.key,
    required this.auth,
    this.titulo = 'Huella Cerca',
  });
  final AuthService auth;
  final String titulo;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (context, _) => AppBar(
      title: Text(titulo),
      actions: [
        if (auth.aviso != null)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Aviso de sesión',
            onPressed: () =>
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(auth.aviso!))),
          ),
        if (auth.restaurando || auth.ocupado)
          const Padding(
            padding: EdgeInsets.all(18),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            color: Colors.white,
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: auth.usuario == null
                ? const Icon(Icons.person_outline_rounded)
                : _Avatar(iniciales: auth.usuario!.mascotero.iniciales),
            onSelected: (value) async {
              if (value == 'logout') {
                await cerrarSesion(context, auth);
              } else if (value == 'restaurar') {
                await auth.restaurar();
              } else if (ModalRoute.of(context)?.settings.name != value) {
                Navigator.of(context).pushNamed(value);
              }
            },
            itemBuilder: (context) {
              final theme = Theme.of(context);
              final user = auth.usuario;
              return [
                if (!auth.autenticado) ...[
                  _opcion('/login', Icons.login_rounded, 'Ingresar'),
                  _opcion(
                    '/registro',
                    Icons.person_add_alt_1_rounded,
                    'Registrarse',
                  ),
                ] else ...[
                  // Encabezado informativo: confirma con qué cuenta se está.
                  if (user != null)
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Row(
                        children: [
                          _Avatar(
                            iniciales: user.mascotero.iniciales,
                            radio: 20,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.mascotero.nombre} ${user.mascotero.apellido}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  _opcion('/perfil', Icons.person_rounded, 'Mi perfil'),
                  _opcion(
                    '/mascotas/mias',
                    Icons.list_alt_rounded,
                    'Mis publicaciones',
                  ),
                  const PopupMenuDivider(),
                  _opcion(
                    'logout',
                    Icons.logout_rounded,
                    'Cerrar sesión',
                    color: theme.colorScheme.error,
                  ),
                ],
                if (auth.aviso != null)
                  _opcion(
                    'restaurar',
                    Icons.warning_amber_rounded,
                    'Revisar sesión',
                  ),
              ];
            },
          ),
      ],
    ),
  );

  PopupMenuItem<String> _opcion(
    String valor,
    IconData icono,
    String texto, {
    Color? color,
  }) => PopupMenuItem<String>(
    value: valor,
    child: Row(
      children: [
        Icon(icono, size: 20, color: color),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            texto,
            style: color == null ? null : TextStyle(color: color),
          ),
        ),
      ],
    ),
  );
}

/// Círculo verde con las iniciales de la cuenta.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciales, this.radio = 16});
  final String iniciales;
  final double radio;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radio,
    backgroundColor: ColoresApp.verde,
    foregroundColor: Colors.white,
    child: Text(
      iniciales,
      style: TextStyle(
        fontSize: radio * 0.75,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}
