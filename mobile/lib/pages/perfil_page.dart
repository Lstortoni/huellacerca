import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';

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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Mi perfil'),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.auth,
        builder: (context, _) {
          final user = widget.auth.usuario;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_cargando) const LinearProgressIndicator(),
              if (_error != null) ...[
                Text(_error!),
                TextButton(
                  onPressed: _cargando ? null : _cargar,
                  child: const Text('Reintentar'),
                ),
              ],
              if (user != null) ...[
                const SizedBox(height: 20),
                const Icon(Icons.account_circle, size: 72),
                const SizedBox(height: 20),
                Text(
                  '${user.mascotero.nombre} ${user.mascotero.apellido}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Teléfono'),
                  subtitle: Text(
                    user.mascotero.telefono?.isNotEmpty == true
                        ? user.mascotero.telefono!
                        : 'Sin informar',
                  ),
                ),
                const Text('Estos son los datos de tu cuenta.'),
              ] else if (!_cargando)
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text('Ingresar'),
                ),
            ],
          );
        },
      ),
    ),
  );
}
