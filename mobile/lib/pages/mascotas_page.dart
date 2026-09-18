import 'package:flutter/material.dart';

import '../models/publicacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/publicacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/lista_paginada.dart';
import 'publicacion_detalle_page.dart';

class MascotasPage extends StatefulWidget {
  const MascotasPage({
    super.key,
    required this.auth,
    required this.service,
    required this.ubicacion,
    this.soloMias = false,
  });
  final AuthService auth;
  final PublicacionService service;
  final UbicacionService ubicacion;
  final bool soloMias;
  @override
  State<MascotasPage> createState() => _MascotasPageState();
}

class _MascotasPageState extends State<MascotasPage> {
  final _zona = TextEditingController();
  int? _tipo, _mascota;
  int? _estado = 1;
  String? _provincia, _localidad;
  DateTime? _desde, _hasta;
  bool _mias = false;
  String? _error;
  int _revision = 0;
  Map<String, String> _filtros = {'estado': '1'};
  @override
  void initState() {
    super.initState();
    if (widget.soloMias) {
      _mias = true;
      _estado = null;
      _filtros = {'mascoteroId': widget.auth.usuario!.mascotero.id};
    }
  }

  @override
  void dispose() {
    _zona.dispose();
    super.dispose();
  }

  void _buscar() {
    if (_desde != null && _hasta != null && _desde!.isAfter(_hasta!)) {
      setState(
        () => _error = 'La fecha desde no puede superar la fecha hasta.',
      );
      return;
    }
    setState(() {
      _error = null;
      _filtros = {
        if (_tipo != null) 'tipoPublicacion': '$_tipo',
        if (_mascota != null) 'tipoMascota': '$_mascota',
        if (_estado != null) 'estado': '$_estado',
        'provinciaId': ?_provincia,
        'localidadId': ?_localidad,
        if (_zona.text.trim().isNotEmpty) 'zona': _zona.text.trim(),
        if (_desde != null) 'fechaDesde': fechaApi(_desde!),
        if (_hasta != null) 'fechaHasta': fechaApi(_hasta!),
        if (_mias && widget.auth.autenticado)
          'mascoteroId': widget.auth.usuario!.mascotero.id,
      };
      _revision++;
    });
  }

  Widget _selector(
    String label,
    Map<int, String> values,
    int? value,
    ValueChanged<int?> changed,
  ) => DropdownButtonFormField<int>(
    isExpanded: true,
    itemHeight: null,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem(value: 0, child: Text('Todas')),
      ...values.entries.map(
        (x) => DropdownMenuItem(value: x.key, child: Text(x.value)),
      ),
    ],
    onChanged: (v) => setState(() => changed(v == 0 ? null : v)),
  );
  Future<void> _fecha(bool desde) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (desde ? _desde : _hasta) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (mounted && value != null) {
      setState(() {
        if (desde) {
          _desde = value;
        } else {
          _hasta = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(
      auth: widget.auth,
      titulo: widget.soloMias ? 'Mis publicaciones' : 'Buscar mascotas',
    ),
    body: ContenidoFormulario(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.soloMias)
            const Text(
              'Tus avisos de mascotas, incluidos los activos y los resueltos.',
            ),
          _selector(
            '¿Qué avisos querés ver?',
            tiposPublicacionBusqueda,
            _tipo,
            (v) => _tipo = v,
          ),
          if (_tipo != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(explicacionesPublicacion[_tipo]!),
            ),
          _selector(
            'Tipo de mascota',
            tiposMascota,
            _mascota,
            (v) => _mascota = v,
          ),
          _selector('Estado', estadosPublicacion, _estado, (v) => _estado = v),
          CampoUbicacion(
            service: widget.ubicacion,
            onChanged: (p, l) {
              _provincia = p;
              _localidad = l;
            },
          ),
          TextField(
            controller: _zona,
            maxLength: 250,
            decoration: const InputDecoration(labelText: 'Zona'),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _fecha(true),
                child: Text(
                  _desde == null
                      ? 'Fecha desde'
                      : 'Desde: ${fechaVisible(_desde!)}',
                ),
              ),
              TextButton(
                onPressed: () => _fecha(false),
                child: Text(
                  _hasta == null
                      ? 'Fecha hasta'
                      : 'Hasta: ${fechaVisible(_hasta!)}',
                ),
              ),
              if (_desde != null || _hasta != null)
                TextButton(
                  onPressed: () => setState(() {
                    _desde = null;
                    _hasta = null;
                  }),
                  child: const Text('Quitar fechas'),
                ),
            ],
          ),
          if (!widget.soloMias)
            ListenableBuilder(
              listenable: widget.auth,
              builder: (_, _) => widget.auth.autenticado
                  ? CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo mis publicaciones'),
                      value: _mias,
                      onChanged: (v) => setState(() => _mias = v!),
                    )
                  : const SizedBox.shrink(),
            ),
          if (_error != null) Text(_error!),
          FilledButton(onPressed: _buscar, child: const Text('Buscar')),
          const SizedBox(height: 20),
          ListaPaginada<PublicacionDto>(
            key: ValueKey(_revision),
            cargar: (pagina) =>
                widget.service.buscar(filtros: _filtros, pagina: pagina),
            itemBuilder: (p, recargar) => Card(
              child: ListTile(
                leading: const Icon(Icons.pets_outlined),
                title: Text(
                  '${p.titulo} · ${etiquetasPublicacion[p.tipoPublicacion]}',
                ),
                subtitle: Text(
                  '${p.localidad}, ${p.provincia}\n${fechaVisible(p.fechaReferencia)} · ${estadosPublicacion[p.estado]}',
                ),
                isThreeLine: true,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PublicacionDetallePage(
                        id: p.id,
                        auth: widget.auth,
                        service: widget.service,
                      ),
                    ),
                  );
                  recargar();
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
