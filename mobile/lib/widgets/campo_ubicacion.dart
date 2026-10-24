import 'dart:async';

import 'package:flutter/material.dart';

import '../models/localidad_dto.dart';
import '../services/contracts/ubicacion_service.dart';
import 'selector_ubicacion.dart';

/// Un solo campo de ubicación para formularios y filtros. Al tocarlo abre el
/// buscador nacional; la localidad elegida queda en "Recientes".
class CampoUbicacion extends StatefulWidget {
  const CampoUbicacion({
    super.key,
    required this.service,
    required this.onChanged,
    this.obligatorio = false,
    this.enabled = true,
    this.onDescripcion,
    this.localidadInicial,
    this.localidadPerfilId,
    this.precargarPerfil = false,
    this.permitirProvincia = false,
    this.etiqueta = 'Localidad',
  });
  final UbicacionService service;

  /// Provincia y localidad elegidas (localidad null: provincia entera o nada).
  final void Function(String? provinciaId, String? localidadId) onChanged;

  /// Texto visible de la selección, o null si se quitó.
  final ValueChanged<String?>? onDescripcion;

  /// Formularios: exige una localidad concreta.
  final bool obligatorio, enabled;

  /// Selección precargada, por ejemplo al editar un aviso.
  final LocalidadDto? localidadInicial;

  /// Localidad del perfil: se sugiere en el buscador y, con [precargarPerfil],
  /// se elige de entrada si no hay [localidadInicial].
  final String? localidadPerfilId;
  final bool precargarPerfil;

  /// Filtros: permite elegir una provincia entera.
  final bool permitirProvincia;
  final String etiqueta;

  @override
  State<CampoUbicacion> createState() => _CampoUbicacionState();
}

class _CampoUbicacionState extends State<CampoUbicacion> {
  final _field = GlobalKey<FormFieldState<UbicacionElegida>>();
  UbicacionElegida? _valor;

  @override
  void initState() {
    super.initState();
    if (widget.localidadInicial case final inicial?) {
      _valor = UbicacionElegida.localidad(inicial);
    } else if (widget.precargarPerfil && widget.localidadPerfilId != null) {
      widget.service.getLocalidad(widget.localidadPerfilId!).then((l) {
        // Si mientras tanto la persona eligió otra, se respeta su elección.
        if (mounted && _valor == null) _asignar(UbicacionElegida.localidad(l));
      }, onError: (Object _) {});
    }
  }

  void _asignar(UbicacionElegida? valor) {
    setState(() => _valor = valor);
    _field.currentState?.didChange(valor);
    widget.onChanged(valor?.idProvincia, valor?.localidad?.id);
    widget.onDescripcion?.call(valor?.etiqueta);
  }

  Future<void> _elegir() async {
    final elegida = await SelectorUbicacion.mostrar(
      context,
      ubicacion: widget.service,
      permitirProvincia: widget.permitirProvincia,
      localidadPerfilId: widget.localidadPerfilId,
    );
    if (!mounted || elegida == null) return;
    _asignar(elegida);
    // Se guarda aparte: un almacenamiento lento no demora el formulario.
    if (elegida.localidad case final l?) unawaited(widget.service.recordar(l));
  }

  @override
  Widget build(BuildContext context) => FormField<UbicacionElegida>(
    key: _field,
    initialValue: _valor,
    validator: (_) => widget.obligatorio && _valor?.localidad == null
        ? 'Elegí una localidad.'
        : null,
    builder: (field) => InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.enabled ? _elegir : null,
      child: InputDecorator(
        isEmpty: _valor == null,
        decoration: InputDecoration(
          labelText: widget.etiqueta,
          hintText: widget.obligatorio
              ? 'Buscá tu localidad'
              : 'Todas las localidades',
          prefixIcon: const Icon(Icons.location_on_rounded),
          suffixIcon: !widget.obligatorio && _valor != null && widget.enabled
              ? IconButton(
                  tooltip: 'Quitar ubicación',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _asignar(null),
                )
              : const Icon(Icons.search_rounded),
          errorText: field.errorText,
          enabled: widget.enabled,
        ),
        child: _valor == null ? null : Text(_valor!.etiqueta),
      ),
    ),
  );
}
