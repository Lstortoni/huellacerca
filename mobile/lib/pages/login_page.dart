import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/auth_dto.dart';
import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});
  final AuthService auth;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false, _ocultar = true;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_cargando || !_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.auth.login(LoginRequest(_email.text.trim(), _password.text));
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos ingresar. Volvé a intentar.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Ingresar'),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Qué bueno verte de nuevo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ingresá para recomendar servicios y participar en la comunidad.',
              ),
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        enabled: !_cargando,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) =>
                            v == null ||
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v.trim())
                            ? 'Ingresá un email válido.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_cargando,
                        obscureText: _ocultar,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _ocultar
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _ocultar = !_ocultar),
                            icon: Icon(
                              _ocultar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _ingresar(),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Ingresá tu contraseña.'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: _cargando ? null : _ingresar,
                        child: Text(_cargando ? 'Ingresando…' : 'Ingresar'),
                      ),
                      TextButton(
                        onPressed: _cargando
                            ? null
                            : () =>
                                  Navigator.of(context)
                                      .pushReplacementNamed('/registro'),
                        child: const Text('No tengo cuenta · Registrarme'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
