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
          nombreMascota: _nombre.text.trim().isEmpty
              ? null
              : _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          fechaSuceso: _fecha!,
          localidadId: _localidad!,
          zona: _zona.text.trim(),
          informacionContacto: _contacto.text.trim(),
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
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Publicar mascota'),
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
                  labelText: '¿Perdiste o encontraste una mascota?',
                ),
                items: tiposPublicacion.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: _ocupado ? null : (v) => setState(() => _tipo = v!),
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
                onChanged: _ocupado
                    ? null
                    : (v) => setState(() => _mascota = v!),
              ),
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
                validator: requerido,
                decoration: const InputDecoration(labelText: 'Zona aproximada'),
              ),
              TextFormField(
                controller: _contacto,
                enabled: !_ocupado,
                maxLength: 500,
                validator: requerido,
                decoration: const InputDecoration(
                  labelText: 'Información de contacto',
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
