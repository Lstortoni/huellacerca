import 'package:flutter/material.dart';

import '../services/auth_service.dart';

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
            icon: Icon(
              auth.autenticado ? Icons.account_circle : Icons.person_outline,
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
                if (auth.aviso != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(auth.aviso!)));
                }
              } else if (value == 'restaurar') {
                await auth.restaurar();
              } else if (ModalRoute.of(context)?.settings.name != value) {
                Navigator.of(context).pushNamed(value);
              }
            },
            itemBuilder: (_) => [
              if (!auth.autenticado) ...[
                const PopupMenuItem(value: '/login', child: Text('Ingresar')),
                const PopupMenuItem(
                  value: '/registro',
                  child: Text('Registrarse'),
                ),
              ] else ...[
                const PopupMenuItem(value: '/perfil', child: Text('Mi perfil')),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión'),
                ),
              ],
              if (auth.aviso != null)
                const PopupMenuItem(
                  value: 'restaurar',
                  child: Text('Revisar sesión'),
                ),
            ],
          ),
      ],
    ),
  );
}
