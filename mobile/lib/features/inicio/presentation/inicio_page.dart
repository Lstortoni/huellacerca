import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../ubicacion/models/provincia_dto.dart';
import '../../ubicacion/services/ubicacion_service.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key, required this.api, required this.ubicacion});
  final ApiClient api;
  final UbicacionService ubicacion;

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  bool _cargando = true;
  String? _error;
  List<ProvinciaDto> _provincias = [];
  ProvinciaDto? _seleccionada;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final health = await widget.api.getText('health');
      if (health.trim() != 'Healthy') {
        throw const ApiException(
          'El servicio no está disponible en este momento.',
        );
      }
      final provincias = await widget.ubicacion.getProvincias();
      if (!mounted) {
        return; // La petición puede terminar después de cerrar la pantalla.
      }
      setState(() {
        _provincias = provincias;
        _seleccionada = null;
        _cargando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar la información. Volvé a intentar.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huella Cerca'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CircleAvatar(
                radius: 34,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.pets,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Más cerca de quienes\nnos necesitan.',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Una comunidad para ayudar a las mascotas y compartir buenas experiencias.',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empecemos por tu provincia',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Elegí dónde estás. Más adelante usaremos esta información para tu registro.',
                    ),
                    const SizedBox(height: 20),
                    if (_cargando) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Cargando provincias…'),
                    ] else if (_error != null) ...[
                      Text(_error!, semanticsLabel: _error),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _cargar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ] else if (_provincias.isEmpty) ...[
                      const Text('Todavía no hay provincias disponibles.'),
                      TextButton(
                        onPressed: _cargar,
                        child: const Text('Volver a consultar'),
                      ),
                    ] else ...[
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Provincia',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ProvinciaDto>(
                            isExpanded: true,
                            value: _seleccionada,
                            hint: const Text('Seleccioná una provincia'),
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
                            onChanged: (value) =>
                                setState(() => _seleccionada = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_provincias.length} provincias disponibles',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (_seleccionada != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Elegiste ${_seleccionada!.nombre}.',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
