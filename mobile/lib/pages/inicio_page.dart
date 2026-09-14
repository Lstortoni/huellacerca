import 'package:flutter/material.dart';

import '../services/contracts/auth_service.dart';
import '../widgets/barra_superior.dart';
import '../widgets/tarjeta_inicio.dart';

/// Inicio público. Escucha la sesión para agregar las acciones de participación.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key, required this.auth});
  final AuthService auth;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BarraSuperior(auth: auth),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final theme = Theme.of(context);
          final conSesion = auth.autenticado && !auth.restaurando;
          final nombre = auth.usuario?.mascotero.nombre.trim() ?? '';
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.pets,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      conSesion
                          ? (nombre.isEmpty ? 'Hola' : 'Hola, $nombre')
                          : 'Más cerca de quienes nos necesitan.',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      conSesion ? '¿Qué querés hacer hoy?' : 'Una comunidad para ayudar a las mascotas y compartir buenas experiencias.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TarjetaInicio(
                      titulo: 'Buscar mascotas',
                      descripcion: 'Mascotas perdidas y encontradas.',
                      icono: Icons.pets_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/mascotas'),
                    ),
                    TarjetaInicio(
                      titulo: 'Servicios recomendados',
                      descripcion:
                          'Veterinarias, peluquerías, paseadores y más.',
                      icono: Icons.storefront_outlined,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/servicios'),
                    ),
                    const SizedBox(height: 16),
                    if (auth.restaurando) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Recuperando tu sesión…'),
                    ] else if (conSesion) ...[
                      Semantics(
                        header: true,
                        child: Text(
                          'Participá en la comunidad',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TarjetaInicio(
                        titulo: 'Publicar mascota',
                        descripcion:
                            'Avisá si perdiste o encontraste una mascota.',
                        icono: Icons.campaign_outlined,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed('/mascotas/publicar'),
                      ),
                      TarjetaInicio(
                        titulo: 'Recomendar un servicio',
                        descripcion:
                            'Compartí una buena experiencia con la comunidad.',
                        icono: Icons.rate_review_outlined,
                        onTap: () =>
                            Navigator.of(context)
                                .pushNamed('/servicios/recomendar'),
                      ),
                    ] else ...[
                      Text(
                        'Sumate a la comunidad',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresá o registrate para publicar y compartir recomendaciones.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/login'),
                            child: const Text('Ingresar'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/registro'),
                            child: const Text('Registrarse'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
