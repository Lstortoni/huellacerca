import 'package:flutter/material.dart';

import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/gestion_recomendacion.dart';
import '../widgets/lista_paginada.dart';

class PrestadorDetallePage extends StatefulWidget {
  const PrestadorDetallePage({
    super.key,
    required this.id,
    required this.auth,
    required this.service,
    this.permitirGestion = false,
  });
  final String id;
  final AuthService auth;
  final RecomendacionService service;

  /// Solo se habilita al entrar desde «Recomendar un servicio».
  final bool permitirGestion;
  @override
  State<PrestadorDetallePage> createState() => _PrestadorDetallePageState();
}

class _PrestadorDetallePageState extends State<PrestadorDetallePage> {
  PrestadorDto? _prestador;
  String? _error;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final p = await widget.service.detalle(widget.id);
      if (mounted) {
        setState(() {
          _prestador = p;
          _error = null;
          _revision++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = mensajeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _prestador;
    return Scaffold(
      appBar: BarraSuperior(auth: widget.auth, titulo: 'Servicio recomendado'),
      body: ContenidoFormulario(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _cargar, child: const Text('Reintentar')),
            ],
            if (p == null && _error == null)
              const Center(child: CircularProgressIndicator()),
            if (p != null) ...[
              const Icon(Icons.storefront_outlined, size: 56),
              Text(p.nombre, style: Theme.of(context).textTheme.headlineMedium),
              Text('${p.rubro} · ${p.localidad}'),
              if (p.direccion?.isNotEmpty == true)
                SelectableText('Dirección: ${p.direccion}'),
              if (p.telefono?.isNotEmpty == true)
                SelectableText('Teléfono: ${p.telefono}'),
              if (p.enlace?.isNotEmpty == true) SelectableText(p.enlace!),
              const Divider(height: 32),
              Text(
                p.textoRecomendaciones,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (p.aspectos.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Lo que más destaca la comunidad:'),
                for (final a in p.aspectos) Text('${a.nombre}: ${a.cantidad}'),
              ],
              if (widget.permitirGestion) ...[
                const Divider(height: 32),
                GestionRecomendacion(
                  prestadorId: p.id,
                  auth: widget.auth,
                  service: widget.service,
                  onChanged: _cargar,
                ),
              ],
              if (p.totalRecomendaciones > 0) ...[
                const Divider(height: 32),
                Text(
                  'Personas que lo recomiendan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListaPaginada<MascoteroRecomiendaDto>(
                  key: ValueKey(_revision),
                  cargar: (pagina) =>
                      widget.service.recomendadores(p.id, pagina: pagina),
                  itemBuilder: (persona, _) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(persona.nombre),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
