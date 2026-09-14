import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/auth_dto.dart';
import '../models/provincia_dto.dart';
import '../models/localidad_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/selector_localidad.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.auth, required this.ubicacion});
  final AuthService auth;
  final UbicacionService ubicacion;
  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController(), _apellido = TextEditingController();
  final _email = TextEditingController(), _telefono = TextEditingController();
  final _password = TextEditingController(), _confirm = TextEditingController();
  List<ProvinciaDto> _provincias = [];
  ProvinciaDto? _provincia;
  LocalidadDto? _localidad;
  bool _cargando = false, _cargandoProvincias = true;
  String? _error, _errorProvincias;
  @override
  void initState() {
    super.initState();
    _cargarProvincias();
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _apellido,
      _email,
      _telefono,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarProvincias() async {
    setState(() {
      _cargandoProvincias = true;
      _errorProvincias = null;
    });
    try {
      final provincias = await widget.ubicacion.getProvincias();
      if (mounted) setState(() => _provincias = provincias);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorProvincias = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorProvincias = 'No pudimos cargar provincias.');
      }
    } finally {
      if (mounted) setState(() => _cargandoProvincias = false);
    }
  }

  Future<void> _registrar() async {
    if (_cargando || !_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.auth.registrar(
        RegisterRequest(
          nombre: _nombre.text.trim(),
          apellido: _apellido.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          passwordConfirm: _confirm.text,
          telefono: _telefono.text.trim().isEmpty
              ? null
              : _telefono.text.trim(),
          localidadId: _localidad!.id,
        ),
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos crear tu cuenta. Volvé a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _campo(
    TextEditingController controller,
    String label, {
    bool secreto = false,
    bool opcional = false,
    int max = 100,
    TextInputType? teclado,
    String? Function(String?)? validar,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_cargando,
      obscureText: secreto,
      autocorrect: !secreto,
      enableSuggestions: !secreto,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validar ??
          (v) {
            final text = secreto ? (v ?? '') : (v ?? '').trim();
            if (!opcional && text.isEmpty) return 'Completá este campo.';
            if (text.length > max) return 'Usá hasta $max caracteres.';
            if (secreto && text.length < 8) return 'Usá al menos 8 caracteres.';
            return null;
          },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Registrarse'),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sumate a Huella Cerca',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _campo(_nombre, 'Nombre'),
                  _campo(_apellido, 'Apellido'),
                  _campo(
                    _email,
                    'Email',
                    teclado: TextInputType.emailAddress,
                    validar: (v) =>
                        v == null ||
                            v.trim().length > 254 ||
                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(v.trim())
                        ? 'Ingresá un email válido.'
                        : null,
                  ),
                  _campo(
                    _telefono,
                    'Teléfono (opcional)',
                    opcional: true,
                    max: 40,
                    teclado: TextInputType.phone,
                  ),
                  _campo(_password, 'Contraseña', secreto: true, max: 128),
                  _campo(
                    _confirm,
                    'Repetir contraseña',
                    secreto: true,
                    validar: (v) => v == null || v.isEmpty
                        ? 'Repetí tu contraseña.'
                        : v != _password.text
                        ? 'Las contraseñas no coinciden.'
                        : null,
                  ),
                  if (_cargandoProvincias)
                    const LinearProgressIndicator()
                  else if (_errorProvincias != null) ...[
                    Text(_errorProvincias!),
                    TextButton(
                      onPressed: _cargarProvincias,
                      child: const Text('Reintentar provincias'),
                    ),
                  ] else if (_provincias.isEmpty) ...[
                    const Text('Todavía no hay provincias disponibles.'),
                    TextButton(
                      onPressed: _cargarProvincias,
                      child: const Text('Volver a consultar'),
                    ),
                  ] else
                    DropdownButtonFormField<ProvinciaDto>(
                      decoration: const InputDecoration(
                        labelText: 'Provincia',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      initialValue: _provincia,
                      items: _provincias
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.nombre,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _cargando
                          ? null
                          : (p) => setState(() {
                              _provincia = p;
                              _localidad = null;
                            }),
                      validator: (p) =>
                          p == null ? 'Elegí una provincia.' : null,
                    ),
                  const SizedBox(height: 16),
                  FormField<LocalidadDto>(
                    key: ValueKey(_provincia?.id),
                    validator: (_) =>
                        _localidad == null ? 'Elegí una localidad.' : null,
                    builder: (field) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.location_on_outlined),
                          label: Text(_localidad?.nombre ?? 'Elegir localidad'),
                          onPressed: _provincia == null || _cargando
                              ? null
                              : () async {
                                  final localidad =
                                      await showDialog<LocalidadDto>(
                                        context: context,
                                        builder: (_) => SelectorLocalidad(
                                          ubicacion: widget.ubicacion,
                                          provinciaId: _provincia!.id,
                                        ),
                                      );
                                  if (!mounted || localidad == null) return;
                                  setState(() => _localidad = localidad);
                                  field.didChange(localidad);
                                },
                        ),
                        if (field.hasError)
                          Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
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
                    onPressed:
                        _cargando || _cargandoProvincias || _provincias.isEmpty
                        ? null
                        : _registrar,
                    child: Text(_cargando ? 'Creando cuenta…' : 'Crear cuenta'),
                  ),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pushReplacementNamed('/login'),
                    child: const Text('Ya tengo cuenta · Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
