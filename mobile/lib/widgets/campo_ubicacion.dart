import 'package:flutter/material.dart';

import '../models/localidad_dto.dart';
import '../models/provincia_dto.dart';
import '../services/contracts/ubicacion_service.dart';
import 'selector_localidad.dart';
import 'contenido_formulario.dart';

/// Comparte la selección provincia/localidad entre filtros y formularios.
class CampoUbicacion extends StatefulWidget {
  const CampoUbicacion({
    super.key,
    required this.service,
    required this.onChanged,
    this.obligatorio = false,
    this.enabled = true,
    this.onDescripcion,
  });
  final UbicacionService service;
  final void Function(String? provinciaId, String? localidadId) onChanged;

  /// Nombre visible de la selección (localidad o provincia), o null si no hay.
  final ValueChanged<String?>? onDescripcion;
  final bool obligatorio, enabled;
  @override
  State<CampoUbicacion> createState() => _CampoUbicacionState();
}

class _CampoUbicacionState extends State<CampoUbicacion> {
  late Future<List<ProvinciaDto>> _future;
  String? _provincia;
  String? _nombreProvincia;
  LocalidadDto? _localidad;
  final _field = GlobalKey<FormFieldState<LocalidadDto>>();
  @override
  void initState() {
    super.initState();
    _future = widget.service.getProvincias();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FutureBuilder<List<ProvinciaDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(mensajeError(snapshot.error!)),
                TextButton(
                  onPressed: () =>
                      setState(() => _future = widget.service.getProvincias()),
                  child: const Text('Reintentar provincias'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          return DropdownButtonFormField<String>(
            initialValue: _provincia,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Provincia'),
            items: [
              if (!widget.obligatorio)
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todas las provincias'),
                ),
              ...snapshot.data!.map(
                (p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)),
              ),
            ],
            onChanged: !widget.enabled
                ? null
                : (value) {
                    setState(() {
                      _provincia = value == '' ? null : value;
                      _nombreProvincia = snapshot.data!
                          .where((p) => p.id == _provincia)
                          .firstOrNull
                          ?.nombre;
                      _localidad = null;
                    });
                    _field.currentState?.didChange(null);
                    widget.onChanged(_provincia, null);
                    widget.onDescripcion?.call(_nombreProvincia);
                  },
          );
        },
      ),
      FormField<LocalidadDto>(
        key: _field,
        validator: (_) => widget.obligatorio && _localidad == null
            ? 'Elegí una localidad.'
            : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(_localidad?.nombre ?? 'Elegir localidad'),
                  onPressed: _provincia == null || !widget.enabled
                      ? null
                      : () async {
                          final provincia = _provincia!;
                          final selected = await showDialog<LocalidadDto>(
                            context: context,
                            builder: (_) => SelectorLocalidad(
                              ubicacion: widget.service,
                              provinciaId: provincia,
                            ),
                          );
                          if (!mounted ||
                              selected == null ||
                              provincia != _provincia) {
                            return;
                          }
                          setState(() => _localidad = selected);
                          field.didChange(selected);
                          widget.onChanged(_provincia, selected.id);
                          widget.onDescripcion?.call(selected.nombre);
                        },
                ),
                if (!widget.obligatorio && _localidad != null)
                  TextButton(
                    onPressed: !widget.enabled
                        ? null
                        : () {
                            setState(() => _localidad = null);
                            field.didChange(null);
                            widget.onChanged(_provincia, null);
                            widget.onDescripcion?.call(_nombreProvincia);
                          },
                    child: const Text('Todas las localidades'),
                  ),
              ],
            ),
            if (field.hasError)
              Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ],
  );
}
