import 'package:flutter/material.dart';

import '../core/theme/colores_app.dart';
import '../core/theme/tema_servicios.dart';
import '../models/recomendacion_dto.dart';
import '../services/contracts/auth_service.dart';
import '../services/contracts/recomendacion_service.dart';
import '../services/contracts/ubicacion_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/campo_ubicacion.dart';
import '../widgets/contenido_formulario.dart';
import '../widgets/grilla.dart';
import '../widgets/lista_paginada.dart';
import '../widgets/opcion_tipo_aviso.dart';
import '../widgets/tarjeta_prestador.dart';
import 'prestador_detalle_page.dart';

/// Búsqueda pública de servicios recomendados. El rubro se aplica al tocarlo;
/// la ubicación está en un panel que se aplica al cerrarlo.
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
  String? _rubro, _provincia, _localidad, _lugar;
  // Lugar aplicado: el panel puede tener una selección aún sin aplicar.
  String? _lugarAplicado;
  int _revisionUbicacion = 0;
  bool _panelAbierto = false;
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
    _panelAbierto = false;
    _lugarAplicado = _provincia == null ? null : (_lugar ?? 'Ubicación');
    _filtros = {
      if (_texto.text.trim().isNotEmpty) 'busqueda': _texto.text.trim(),
      'rubroId': ?_rubro,
      'provinciaId': ?_provincia,
      'localidadId': ?_localidad,
    };
    _revision++;
  });

  void _quitarUbicacion() {
    setState(() {
      _provincia = _localidad = _lugar = null;
      _revisionUbicacion++;
    });
    _buscar();
  }

  Widget _barraBusqueda() => TextField(
    controller: _texto,
    maxLength: 150,
    textInputAction: TextInputAction.search,
    onSubmitted: (_) => _buscar(),
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      hintText: 'Buscar por nombre…',
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: _texto.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Borrar búsqueda',
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _texto.clear();
                _buscar();
              },
            ),
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(99)),
    ),
  );

  Widget _grillaRubros() => FutureBuilder<List<RubroDto>>(
    future: _rubros,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() {
            _rubros = widget.service.rubros();
          }),
          child: const Text('No pudimos cargar rubros. Reintentar'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      return Grilla(
        columnas: 3,
        children: [
          for (final r in snapshot.data!)
            OpcionIcono(
              icono: iconoRubro(r.nombre),
              texto: r.nombre,
              color: ColoresApp.ambar,
              fondo: ColoresApp.ambarSuave,
              vertical: true,
              seleccionado: _rubro == r.id,
              onTap: () {
                _rubro = _rubro == r.id ? null : r.id;
                _buscar();
              },
            ),
        ],
      );
    },
  );

  Widget _panelUbicacion(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoUbicacion(
              key: ValueKey(_revisionUbicacion),
              service: widget.ubicacion,
              onChanged: (p, l) {
                _provincia = p;
                _localidad = l;
              },
              onDescripcion: (d) => _lugar = d,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _buscar,
              child: const Text('Aplicar ubicación'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => TemaServicios(
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: BarraSuperior(
            auth: widget.auth,
            titulo: 'Servicios recomendados',
          ),
          body: ContenidoFormulario(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _barraBusqueda(),
                const SizedBox(height: 12),
                _grillaRubros(),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _panelAbierto
                      ? _buscar
                      : () => setState(() => _panelAbierto = true),
                  icon: Icon(
                    _panelAbierto
                        ? Icons.expand_less_rounded
                        : Icons.location_on_rounded,
                  ),
                  label: Text('Ubicación: ${_lugarAplicado ?? 'todas'}'),
                ),
                if (!_panelAbierto && _lugarAplicado != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _quitarUbicacion,
                      child: const Text('Quitar ubicación'),
                    ),
                  ),
                Visibility(
                  visible: _panelAbierto,
                  maintainState: true,
                  child: _panelUbicacion(theme),
                ),
                const SizedBox(height: 16),
                ListaPaginada<PrestadorDto>(
                  key: ValueKey(_revision),
                  cargar: (pagina) =>
                      widget.service.buscar(filtros: _filtros, pagina: pagina),
                  itemBuilder: (r, recargar) => TarjetaPrestador(
                    prestador: r,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PrestadorDetallePage(
                            id: r.id,
                            auth: widget.auth,
                            service: widget.service,
                          ),
                        ),
                      );
                      if (mounted) recargar();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
