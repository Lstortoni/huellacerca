import 'package:flutter/material.dart';

import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/lista_paginada.dart';
import 'recomendacion_detalle_page.dart';

class RecomendacionesPage extends StatefulWidget {
  const RecomendacionesPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
  });
  final AuthService auth;
  final RecomendacionService service;
  final UbicacionService ubicacion;
  @override
  State<RecomendacionesPage> createState() => _RecomendacionesPageState();
}

class _RecomendacionesPageState extends State<RecomendacionesPage> {
  final _texto = TextEditingController();
  late Future<List<RubroDto>> _rubros;
  String? _rubro, _provincia, _localidad;
  Map<String, String> _filtros = {};
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _rubros = widget.service.rubros();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _buscar() => setState(() {
    _filtros = {
      if (_texto.text.trim().isNotEmpty) 'busqueda': _texto.text.trim(),
      'rubroId': ?_rubro,
      'provinciaId': ?_provincia,
      'localidadId': ?_localidad,
    };
    _revision++;
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: widget.auth, titulo: 'Servicios recomendados'),
    body: ContenidoFormulario(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Experiencias compartidas por la comunidad.'),
          TextField(
            controller: _texto,
            maxLength: 150,
            decoration: const InputDecoration(
              labelText: 'Buscar servicio o recomendación',
            ),
            onSubmitted: (_) => _buscar(),
          ),
          FutureBuilder<List<RubroDto>>(
            future: _rubros,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () =>
                      setState(() => _rubros = widget.service.rubros()),
                  child: const Text('No pudimos cargar rubros. Reintentar'),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return DropdownButtonFormField<String>(
                initialValue: _rubro,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rubro'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todos los rubros'),
                  ),
                  ...snapshot.data!.map(
                    (r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)),
                  ),
                ],
                onChanged: (v) => setState(() => _rubro = v == '' ? null : v),
              );
            },
          ),
          CampoUbicacion(
            service: widget.ubicacion,
            onChanged: (p, l) {
              _provincia = p;
              _localidad = l;
            },
          ),
          FilledButton(onPressed: _buscar, child: const Text('Buscar')),
          const SizedBox(height: 20),
          ListaPaginada<RecomendacionDto>(
            key: ValueKey(_revision),
            cargar: (pagina) =>
                widget.service.buscar(filtros: _filtros, pagina: pagina),
            itemBuilder: (r, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(r.prestador.nombre),
                subtitle: Text(
                  '${r.prestador.rubro} · ${r.prestador.localidad}\n${r.titulo} — ${r.autor}',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RecomendacionDetallePage(
                      id: r.id,
                      auth: widget.auth,
                      service: widget.service,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
