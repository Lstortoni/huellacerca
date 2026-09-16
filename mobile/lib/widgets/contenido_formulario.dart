import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../services/contracts/auth_service.dart';

String mensajeError(Object error) => error is ApiException
    ? error.message
    : 'No pudimos completar la operación. Volvé a intentar.';
String? requerido(String? value) =>
    value == null || value.trim().isEmpty ? 'Completá este campo.' : null;
String? descripcionValida(String? value) =>
    (value?.trim().length ?? 0) < 10 ? 'Escribí al menos 10 caracteres.' : null;

class ContenidoFormulario extends StatelessWidget {
  const ContenidoFormulario({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: child,
        ),
      ),
    ),
  );
}

class RequiereSesion extends StatelessWidget {
  const RequiereSesion({super.key, required this.auth, required this.child});
  final AuthService auth;
  final Widget child;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: auth,
    builder: (_, _) {
      if (auth.restaurando) {
        return const Center(child: CircularProgressIndicator());
      }
      if (auth.autenticado) return child;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresá para continuar.'),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      );
    },
  );
}
