import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/publicacion_service.dart';
import 'grilla.dart';
import 'muestra_color.dart';
import 'seccion_formulario.dart';

/// Traduce los valores del aviso usando las etiquetas públicas de la API.
class CaracteristicasPublicacion extends StatefulWidget {
  const CaracteristicasPublicacion({
    super.key,
    required this.publicacion,
    required this.service,
  });
  final PublicacionDto publicacion;
  final PublicacionService service;
  @override
  State<CaracteristicasPublicacion> createState() =>
      _CaracteristicasPublicacionState();
}

class _CaracteristicasPublicacionState
    extends State<CaracteristicasPublicacion> {
  late Future<List<CaracteristicaMascotaDto>> _opciones;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _opciones = widget.service.caracteristicas(widget.publicacion.tipoMascota);
    _opciones.ignore();
  }

  Widget _dato(
    ThemeData theme,
    String campo,
    String etiqueta,
    int valor,
    String texto,
  ) => Container(
    key: ValueKey('caracteristica:$etiqueta'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (campo == 'colorPredominante') ...[
              MuestraColor(id: valor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                texto,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SeccionFormulario(
      titulo: widget.publicacion.tipoPublicacion == 4
          ? 'Características que busca'
          : 'Características de la mascota',
      child: FutureBuilder<List<CaracteristicaMascotaDto>>(
        future: _opciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return TextButton(
              onPressed: () => setState(_cargar),
              child: const Text(
                'No pudimos cargar las características. Reintentar',
              ),
            );
          }
          final valores = widget.publicacion.caracteristicas;
          return Grilla(
            columnas: 2,
            children: [
              for (final campo in snapshot.data!)
                if (valores[campo.campo] case final valor?)
                  _dato(
                    theme,
                    campo.campo,
                    campo.nombre,
                    valor,
                    campo.opciones
                            .where((o) => o.id == valor)
                            .firstOrNull
                            ?.nombre ??
                        'Opción no disponible',
                  ),
            ],
          );
        },
      ),
    );
  }
}
