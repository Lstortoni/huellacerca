import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/network/api_exception.dart';
import '../models/permiso_recuperacion.dart';
import '../services/contracts/recuperacion_service.dart';
import '../widgets/contenido_formulario.dart';

enum _Paso { email, codigo, password, completado }

class RecuperarPasswordPage extends StatefulWidget {
  const RecuperarPasswordPage({
    super.key,
    required this.service,
    this.emailInicial = '',
  });
  final RecuperacionService service;
  final String emailInicial;

  @override
  State<RecuperarPasswordPage> createState() => _RecuperarPasswordPageState();
}

class _RecuperarPasswordPageState extends State<RecuperarPasswordPage> {
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  late final _email = TextEditingController(text: widget.emailInicial);
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  _Paso _paso = _Paso.email;
  bool _ocupado = false, _ocultar = true;
  String? _error;
  PermisoRecuperacion? _permiso;
  DateTime? _reenviarDesde;
  Timer? _timer;

  int get _espera {
    final ms = _reenviarDesde?.difference(DateTime.now()).inMilliseconds ?? 0;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _esperar(int segundos) {
    _reenviarDesde = DateTime.now().add(Duration(seconds: segundos));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_espera == 0) _timer?.cancel();
    });
  }

  String _mensaje(Object e) {
    if (e is ApiException && e.statusCode == 429) {
      return 'Hiciste varios intentos. Esperá un minuto antes de volver a intentar.';
    }
    if (e is ApiException && e.statusCode == 503) {
      return 'La recuperación no está disponible en este momento. Intentá más tarde.';
    }
    return mensajeError(e);
  }

  Future<void> _solicitar() async {
    if (_ocupado || _espera > 0) return;
    if (_paso == _Paso.email && !_forms[_paso.index].currentState!.validate()) {
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    // Ante una respuesta perdida el servidor podría haber aceptado el envío.
    _esperar(60);
    try {
      final segundos = await widget.service.solicitarCodigo(_email.text);
      if (!mounted) return;
      _esperar(segundos);
      setState(() {
        _paso = _Paso.codigo;
        _permiso = null;
        _codigo.clear();
        _password.clear();
        _confirmacion.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = _mensaje(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _verificar() async {
    if (_ocupado || !_forms[_paso.index].currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final permiso = await widget.service.verificarCodigo(
        _email.text,
        _codigo.text,
      );
      if (!mounted) return;
      if (permiso.vencido) {
        throw const ApiException(
          'La autorización venció. Solicitá un nuevo código.',
        );
      }
      setState(() {
        _permiso = permiso;
        _codigo.clear();
        _paso = _Paso.password;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _mensaje(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _volverACodigo(String error) {
    _permiso = null;
    _password.clear();
    _confirmacion.clear();
    _paso = _Paso.codigo;
    _error = error;
  }

  Future<void> _guardar() async {
    if (_ocupado || !_forms[_paso.index].currentState!.validate()) return;
    final permiso = _permiso;
    if (permiso == null || permiso.vencido) {
      setState(
        () =>
            _volverACodigo('La autorización venció. Solicitá un nuevo código.'),
      );
      return;
    }
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.service.restablecer(
        permiso.token,
        _password.text,
        _confirmacion.text,
      );
      if (!mounted) return;
      setState(() {
        _permiso = null;
        _password.clear();
        _confirmacion.clear();
        _paso = _Paso.completado;
        _timer?.cancel();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is ApiException && e.statusCode == 400) {
          _volverACodigo(
            'No pudimos usar la autorización. Solicitá un nuevo código.',
          );
        } else {
          _error =
              '${_mensaje(e)} Si perdiste la conexión al guardar, probá ingresar con la nueva contraseña.';
        }
      });
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _codigo.dispose();
    _password.dispose();
    _confirmacion.dispose();
    _permiso = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recuperar contraseña')),
    body: ContenidoFormulario(
      child: Form(
        key: _forms[_paso.index],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_paso != _Paso.completado) ...[
              Text(
                'Paso ${_paso.index + 1} de 3',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
            ],
            if (_paso == _Paso.email) ...[
              const Text(
                'Ingresá el email de tu cuenta para recibir un código de recuperación.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('recuperacion-email'),
                controller: _email,
                enabled: !_ocupado,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != null &&
                        v.trim().length <= 254 &&
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                    ? null
                    : 'Ingresá un email válido.',
                onFieldSubmitted: (_) => _solicitar(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _ocupado || _espera > 0 ? null : _solicitar,
                child: Text(
                  _ocupado
                      ? 'Solicitando…'
                      : _espera > 0
                      ? 'Esperá ${_espera}s'
                      : 'Enviar código',
                ),
              ),
            ],
            if (_paso == _Paso.codigo) ...[
              const Text(
                'Si existe una cuenta activa con ese email, recibirás un código. Revisá también la carpeta de spam.',
              ),
              const SizedBox(height: 8),
              Text(_email.text.trim()),
              const SizedBox(height: 8),
              const Text(
                'El código vence en 10 minutos. Tenés hasta 5 intentos incorrectos.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('recuperacion-codigo'),
                controller: _codigo,
                enabled: !_ocupado,
                keyboardType: TextInputType.number,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch(v ?? '')
                    ? null
                    : 'Ingresá los 6 dígitos.',
                onFieldSubmitted: (_) => _verificar(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _ocupado ? null : _verificar,
                child: Text(_ocupado ? 'Procesando…' : 'Verificar código'),
              ),
              TextButton(
                onPressed: _ocupado || _espera > 0 ? null : _solicitar,
                child: Text(
                  _espera > 0 ? 'Reenviar en ${_espera}s' : 'Reenviar código',
                ),
              ),
              TextButton(
                onPressed: _ocupado
                    ? null
                    : () => setState(() {
                        _paso = _Paso.email;
                        _codigo.clear();
                        _permiso = null;
                        _error = null;
                      }),
                child: const Text('Cambiar email'),
              ),
            ],
            if (_paso == _Paso.password) ...[
              const Text(
                'Elegí una nueva contraseña de entre 8 y 128 caracteres.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('recuperacion-password'),
                controller: _password,
                enabled: !_ocupado,
                obscureText: _ocultar,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _ocultar
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                    icon: Icon(
                      _ocultar ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (v) => v != null && v.length >= 8 && v.length <= 128
                    ? null
                    : 'Usá entre 8 y 128 caracteres.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('recuperacion-confirmacion'),
                controller: _confirmacion,
                enabled: !_ocupado,
                obscureText: _ocultar,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != null && v.isNotEmpty && v == _password.text
                    ? null
                    : 'Las contraseñas no coinciden.',
                onFieldSubmitted: (_) => _guardar(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _ocupado ? null : _guardar,
                child: Text(_ocupado ? 'Guardando…' : 'Guardar contraseña'),
              ),
            ],
            if (_paso == _Paso.completado) ...[
              const Icon(Icons.check_circle_outline, size: 56),
              const SizedBox(height: 16),
              const Text('Tu contraseña se actualizó correctamente.'),
              const SizedBox(height: 8),
              const Text(
                'Ingresá nuevamente con tu email y la nueva contraseña.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Volver a ingresar'),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
