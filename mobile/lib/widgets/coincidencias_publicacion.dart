import 'package:flutter/material.dart';

import '../models/pagina_dto.dart';
import '../models/publicacion_dto.dart';
import '../pages/publicacion_detalle_page.dart';
import '../pages/coincidencias_page.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';

/// Consulta independiente: un fallo no impide leer el aviso ni su contacto.
class CoincidenciasPublicacion extends StatefulWidget {
  const CoincidenciasPublicacion({super.key, required this.publicacion,
    required this.auth, required this.service, this.paginada = false});
  final PublicacionDto publicacion;
  final AuthService auth;
  final PublicacionService service;
  final bool paginada;

  @override
  State<CoincidenciasPublicacion> createState() => _CoincidenciasPublicacionState();
}

class _CoincidenciasPublicacionState extends State<CoincidenciasPublicacion> {
  late Future<PaginaDto<CoincidenciaPublicacionDto>> _future;
  int _pagina = 1;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  void _consultar() {
    _future = widget.service.coincidencias(widget.publicacion.id,
      pagina: _pagina, tamanoPagina: widget.paginada ? 10 : 5);
    _future.ignore();
  }

  void _cargar(int pagina) => setState(() {
    _pagina = pagina;
    _consultar();
  });

  Future<void> _abrir(String id) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      PublicacionDetallePage(id: id, auth: widget.auth, service: widget.service)));
    if (mounted) _cargar(1);
  }

  Future<void> _verMas() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      CoincidenciasPage(publicacion: widget.publicacion, auth: widget.auth, service: widget.service)));
    if (mounted) _cargar(1);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Text('Posibles coincidencias', style: Theme.of(context).textTheme.titleLarge),
      const Text('Estos avisos podrían coincidir. No significa que se trate de la misma mascota.'),
      if (widget.publicacion.caracteristicas.isEmpty)
        const Text('Tu aviso no tiene características para comparar. Podés usar la búsqueda manual.'),
      FutureBuilder<PaginaDto<CoincidenciaPublicacionDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(children: [
              const Text('No pudimos consultar las coincidencias. Tu publicación sigue disponible.'),
              TextButton(onPressed: () => _cargar(_pagina), child: const Text('Reintentar coincidencias')),
            ]);
          }
          final resultado = snapshot.data!;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (resultado.items.isEmpty)
              Text(_pagina == 1 ? 'Por ahora no encontramos posibles coincidencias.' : 'No hay más resultados en esta página.'),
            for (final candidato in resultado.items)
              Card(child: ListTile(
                leading: const Icon(Icons.pets_outlined),
                title: Text(candidato.publicacion.titulo),
                subtitle: Text('${etiquetasPublicacion[candidato.publicacion.tipoPublicacion]} · ${candidato.publicacion.localidad}\n'
                  '${fechaVisible(candidato.publicacion.fechaReferencia)}\n'
                  'Coincide en: ${candidato.coincideEn.join(', ')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrir(candidato.publicacion.id),
              )),
            if (!widget.paginada && resultado.haySiguiente)
              TextButton(onPressed: _verMas, child: Text('Ver más coincidencias (${resultado.total})')),
            if (widget.paginada)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(tooltip: 'Página anterior', onPressed: _pagina > 1 ? () => _cargar(_pagina - 1) : null,
                  icon: const Icon(Icons.chevron_left)),
                Text('Página $_pagina · ${resultado.total} candidatos'),
                IconButton(tooltip: 'Página siguiente', onPressed: resultado.haySiguiente ? () => _cargar(_pagina + 1) : null,
                  icon: const Icon(Icons.chevron_right)),
              ]),
            TextButton(onPressed: () => _cargar(1), child: const Text('Actualizar coincidencias')),
          ]);
        },
      ),
    ],
  );
}
