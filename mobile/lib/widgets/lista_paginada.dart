import 'package:flutter/material.dart';

import '../models/pagina_dto.dart';
import 'contenido_formulario.dart';
import 'estado_mensaje.dart';

/// Muestra carga, errores, vacío y navegación sin conocer el servicio concreto.
class ListaPaginada<T> extends StatefulWidget {
  const ListaPaginada({
    super.key,
    required this.cargar,
    required this.itemBuilder,
    this.vacio,
  });
  final Future<PaginaDto<T>> Function(int pagina) cargar;
  final Widget Function(T item, VoidCallback recargar) itemBuilder;

  /// Reemplaza el mensaje genérico de resultados vacíos.
  final Widget? vacio;
  @override
  State<ListaPaginada<T>> createState() => _ListaPaginadaState<T>();
}

class _ListaPaginadaState<T> extends State<ListaPaginada<T>> {
  int _pagina = 1;
  late Future<PaginaDto<T>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.cargar(_pagina);
  }

  void _cargar(int pagina) {
    if (!mounted) return;
    setState(() {
      _pagina = pagina;
      _future = widget.cargar(pagina);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PaginaDto<T>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return EstadoMensaje(
          icono: Icons.cloud_off_rounded,
          mensaje: mensajeError(snapshot.error!),
          accion: 'Reintentar',
          onAccion: () => _cargar(_pagina),
        );
      }
      final page = snapshot.data!;
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              page.total == 1 ? '1 resultado' : '${page.total} resultados',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (page.items.isEmpty)
            widget.vacio ??
                const EstadoMensaje(
                  icono: Icons.search_off_rounded,
                  mensaje: 'No encontramos resultados con esos filtros.',
                ),
          ...page.items.map(
            (item) => widget.itemBuilder(item, () => _cargar(_pagina)),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                onPressed: _pagina > 1 ? () => _cargar(_pagina - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Página $_pagina'),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: page.haySiguiente
                    ? () => _cargar(_pagina + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      );
    },
  );
}
