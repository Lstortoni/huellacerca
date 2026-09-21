import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import 'publicacion_detalle_page.dart';

class PublicarMascotaPage extends StatefulWidget {
  const PublicarMascotaPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
  });
  final AuthService auth;
  final PublicacionService service;
  final UbicacionService ubicacion;
  @override
  State<PublicarMascotaPage> createState() => _PublicarMascotaPageState();
}

class _PublicarMascotaPageState extends State<PublicarMascotaPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController(),
      _descripcion = TextEditingController(),
      _zona = TextEditingController(),
      _contacto = TextEditingController();
  int _tipo = 1, _mascota = 1;
  String? _localidad, _error;
  DateTime? _fecha;
  bool _ocupado = false;
  late Future<List<CaracteristicaMascotaDto>> _opciones;
  final Map<String, int> _caracteristicas = {};
  int _revisionCaracteristicas = 0;
  @override
  void initState() {
    super.initState();
    _opciones = _cargarOpciones();
  }

  Future<List<CaracteristicaMascotaDto>> _cargarOpciones() {
    final future = widget.service.caracteristicas(_mascota);
    // FutureBuilder muestra el error; observarlo también antes del próximo frame.
    future.ignore();
    return future;
  }

  void _cambiarMascota(int tipo) {
    setState(() {
      _mascota = tipo;
      _caracteristicas.clear();
      _revisionCaracteristicas++;
      _opciones = _cargarOpciones();
    });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _zona, _contacto]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_ocupado || !_form.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final p = await widget.service.crear(
        CrearPublicacionRequest(
          tipoPublicacion: _tipo,
          tipoMascota: _mascota,
          nombreMascota: _tipo == 4 || _nombre.text.trim().isEmpty
              ? null
              : _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          fechaSuceso: _tipo <= 2 ? _fecha : null,
          localidadId: _localidad!,
          zona: _zona.text.trim(),
          informacionContacto: _contacto.text.trim(),
          tamano: _caracteristicas['tamano'],
          raza: _caracteristicas['raza'],
          pelaje: _caracteristicas['pelaje'],
          colorPredominante: _caracteristicas['colorPredominante'],
          colorOjos: _caracteristicas['colorOjos'],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PublicacionDetallePage(
            id: p.id,
            auth: widget.auth,
            service: widget.service,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Publicar un aviso'),
    body: RequiereSesion(
      auth: widget.auth,
      child: ContenidoFormulario(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: '¿Qué querés publicar?',
                ),
                items: tiposPublicacion.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: _ocupado
                    ? null
                    : (v) => setState(() {
                        _tipo = v!;
                        _caracteristicas.clear();
                        _revisionCaracteristicas++;
                      }),
              ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _mascota,
                decoration: const InputDecoration(labelText: 'Tipo de mascota'),
                items: tiposMascota.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: _ocupado ? null : (v) => _cambiarMascota(v!),
              ),
              const SizedBox(height: 16),
              Text(
                _tipo == 4
                    ? 'Características que buscás (opcionales)'
                    : 'Características de la mascota (opcionales)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _tipo == 4
                    ? 'Dejá sin indicar lo que te resulte indistinto.'
                    : 'Si no conocés algún dato, dejalo sin indicar.',
              ),
              FutureBuilder<List<CaracteristicaMascotaDto>>(
                future: _opciones,
                builder: (context, snapshot) {
                  // No mostrar opciones del animal anterior mientras llega la nueva consulta.
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text(
                          'No pudimos cargar las características. Podés publicar sin completarlas.',
                        ),
                        TextButton(
                          onPressed: _ocupado
                              ? null
                              : () => setState(() {
                                  _opciones = _cargarOpciones();
                                }),
                          child: const Text('Reintentar características'),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (final campo in snapshot.data!)
                        DropdownButtonFormField<int>(
                          key: ValueKey(
                            '$_revisionCaracteristicas:${campo.campo}',
                          ),
                          initialValue: _caracteristicas[campo.campo] ?? 0,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: campo.nombre),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('Sin indicar'),
                            ),
                            ...campo.opciones.map(
                              (o) => DropdownMenuItem(
                                value: o.id,
                                child: Text(o.nombre),
                              ),
                            ),
                          ],
                          onChanged: _ocupado
                              ? null
                              : (v) => setState(() {
                                  // 0 es solo la opción visual; nunca se envía a la API.
                                  if (v == null || v == 0) {
                                    _caracteristicas.remove(campo.campo);
                                  } else {
                                    _caracteristicas[campo.campo] = v;
                                  }
                                }),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_tipo != 4)
                TextFormField(
                  controller: _nombre,
                  enabled: !_ocupado,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Nombre (opcional)',
                  ),
                ),
              TextFormField(
                controller: _descripcion,
                enabled: !_ocupado,
                maxLength: 3000,
                minLines: 3,
                maxLines: 6,
                validator: descripcionValida,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              if (_tipo <= 2)
                FormField<DateTime>(
                  validator: (_) =>
                      _fecha == null ? 'Elegí la fecha del suceso.' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: _ocupado
                            ? null
                            : () async {
                                final value = await showDatePicker(
                                  context: context,
                                  initialDate: _fecha ?? DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (!mounted || value == null) return;
                                setState(() => _fecha = value);
                                field.didChange(value);
                              },
                        child: Text(
                          _fecha == null
                              ? 'Elegir fecha del suceso'
                              : fechaVisible(_fecha!),
                        ),
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
              CampoUbicacion(
                service: widget.ubicacion,
                obligatorio: true,
                enabled: !_ocupado,
                onChanged: (_, l) => _localidad = l,
              ),
              TextFormField(
                controller: _zona,
                enabled: !_ocupado,
                maxLength: 250,
                validator: _tipo == 4 ? null : requerido,
                decoration: InputDecoration(
                  labelText: _tipo == 4
                      ? 'Zona aproximada (opcional)'
                      : 'Zona aproximada',
                ),
              ),
              TextFormField(
                controller: _contacto,
                enabled: !_ocupado,
                maxLength: 500,
                validator: requerido,
                decoration: const InputDecoration(
                  labelText: 'Información de contacto',
                  hintText: 'Teléfono, WhatsApp o email',
                ),
              ),
              const Text(
                'El contacto que ingreses será visible para quienes consulten el aviso.',
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _ocupado ? null : _publicar,
                child: Text(_ocupado ? 'Publicando…' : 'Publicar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
