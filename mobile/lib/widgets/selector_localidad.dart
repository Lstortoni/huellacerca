import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/localidad_dto.dart';
import '../services/contracts/ubicacion_service.dart';

/// Diálogo reutilizable con búsqueda y páginas; no descarga todo el catálogo.
class SelectorLocalidad extends StatefulWidget {
  const SelectorLocalidad({
    super.key,
    required this.ubicacion,
    required this.provinciaId,
  });
  final UbicacionService ubicacion;
  final String provinciaId;
  @override
  State<SelectorLocalidad> createState() => _SelectorLocalidadState();
}

class _SelectorLocalidadState extends State<SelectorLocalidad> {
  final _texto = TextEditingController();
  List<LocalidadDto> _items = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  int _pagina = 1, _total = 0, _solicitud = 0;
  @override
  void initState() {
    super.initState();
    _cargar(1);
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar(int pagina) async {
    final solicitud = ++_solicitud;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final result = await widget.ubicacion.getLocalidades(
        widget.provinciaId,
        busqueda: _busqueda,
        pagina: pagina,
      );
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _items = result.items;
        _total = result.total;
        _pagina = pagina;
      });
    } on ApiException catch (e) {
      if (mounted && solicitud == _solicitud) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted && solicitud == _solicitud) {
        setState(() => _error = 'No pudimos buscar localidades.');
      }
    } finally {
      if (mounted && solicitud == _solicitud) setState(() => _cargando = false);
    }
  }

  void _buscar() {
    _busqueda = _texto.text.trim();
    _cargar(1);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Elegí tu localidad'),
    content: SizedBox(
      width: 420,
      height: 400,
      child: Column(
        children: [
          TextField(
            controller: _texto,
            decoration: InputDecoration(
              labelText: 'Buscar por nombre',
              suffixIcon: IconButton(
                tooltip: 'Buscar',
                onPressed: _buscar,
                icon: const Icon(Icons.search),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: () => _cargar(_pagina),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                ? const Center(
                    child: Text('No encontramos localidades con ese nombre.'),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(_items[i].nombre),
                      onTap: () => Navigator.of(context).pop(_items[i]),
                    ),
                  ),
          ),
          if (!_cargando && _error == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: _pagina > 1 ? () => _cargar(_pagina - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Página $_pagina'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: _pagina * 20 < _total
                      ? () => _cargar(_pagina + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
    ],
  );
}
