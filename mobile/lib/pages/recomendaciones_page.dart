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

  @override
  Widget build(BuildContext context) => TemaServicios(
    child: Builder(
      builder: (context) {
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
                // Se aplica al elegir; la ✕ del campo quita el filtro.
                CampoUbicacion(
                  service: widget.ubicacion,
                  permitirProvincia: true,
                  etiqueta: 'Localidad o provincia',
                  localidadPerfilId: widget.auth.usuario?.mascotero.localidadId,
                  onChanged: (p, l) {
                    _provincia = p;
                    _localidad = l;
                    _buscar();
                  },
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
