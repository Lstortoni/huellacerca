import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/publicacion_service.dart';

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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      Text(
        widget.publicacion.tipoPublicacion == 4
            ? 'Características que busca'
            : 'Características de la mascota',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      FutureBuilder<List<CaracteristicaMascotaDto>>(
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final campo in snapshot.data!)
                if (valores.containsKey(campo.campo))
                  Text(
                    '${campo.nombre}: ${campo.opciones.where((o) => o.id == valores[campo.campo]).firstOrNull?.nombre ?? 'Opción no disponible'}',
                  ),
            ],
          );
        },
      ),
    ],
  );
}
