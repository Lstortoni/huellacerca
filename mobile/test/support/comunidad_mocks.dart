import 'package:huella_cerca/models/pagina_dto.dart';
import 'package:huella_cerca/models/foto_seleccionada.dart';
import 'package:huella_cerca/models/publicacion_dto.dart';
import 'package:huella_cerca/models/recomendacion_dto.dart';
import 'package:huella_cerca/services/contracts/publicacion_service.dart';
import 'package:huella_cerca/services/contracts/recomendacion_service.dart';

Map<String, dynamic> publicacionJson({
  int estado = 1,
  String autorId = 'mascotero-1',
}) => {
  'id': 'publicacion-1',
  'mascoteroId': autorId,
  'autor': 'Ana',
  'tipoPublicacion': 1,
  'tipoMascota': 1,
  'nombreMascota': 'Toby',
  'descripcion': 'Perro marrón con collar azul.',
  'fechaSuceso': '2026-09-15',
  'fechaCreacion': '2026-09-15T15:00:00Z',
  'localidad': 'La Plata',
  'provincia': 'Buenos Aires',
  'zona': 'Plaza',
  'informacionContacto': '2215550000',
  'estado': estado,
  'fotografias': [],
};
Map<String, dynamic> prestadorJson() => {
  'id': 'prestador-1',
  'nombre': 'Veterinaria del barrio',
  'rubro': 'Veterinaria',
  'localidad': 'La Plata',
  'direccion': 'Calle 1',
  'telefono': null,
  'enlace': null,
  'totalRecomendaciones': 0,
  'aspectos': [],
};
Map<String, dynamic> recomendacionJson() => {
  'id': 'recomendacion-1',
  'aspectos': [],
  'prestador': prestadorJson(),
};

class PublicacionServiceMock implements PublicacionService {
  @override
  Future<FotoSeleccionada?> elegirFoto() async => null;
  @override
  Future<FotoSeleccionada?> recuperarFoto() async => null;
  @override
  Future<void> subirFoto(String id, FotoSeleccionada foto) async {}
  @override
  Future<void> eliminarFoto(String id) async {}
  @override
  String urlFoto(String path) => 'http://localhost/$path';
  @override
  Future<PaginaDto<CoincidenciaPublicacionDto>> coincidencias(
    String id, {
    int pagina = 1,
    int tamanoPagina = 10,
  }) async => PaginaDto([], 0, pagina, tamanoPagina);
  bool falloCaracteristicas = false;
  @override
  Future<List<CaracteristicaMascotaDto>> caracteristicas(
    int tipoMascota,
  ) async {
    if (falloCaracteristicas) throw Exception('Sin conexión');
    return caracteristicasJson(tipoMascota)
        .map(CaracteristicaMascotaDto.fromJson)
        .toList();
  }

  int estado = 1, resoluciones = 0, consultas = 0;
  String autorId = 'mascotero-1';
  CrearPublicacionRequest? creada;
  Map<String, String> filtros = {};
  @override
  Future<PaginaDto<PublicacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async {
    consultas++;
    this.filtros = filtros;
    return PaginaDto([await detalle('publicacion-1')], 1, pagina, 20);
  }

  @override
  Future<PublicacionDto> detalle(String id) async => PublicacionDto.fromJson(
    publicacionJson(estado: estado, autorId: autorId),
  );
  @override
  Future<PublicacionDto> crear(CrearPublicacionRequest request) async {
    creada = request;
    return detalle('publicacion-1');
  }

  @override
  Future<PublicacionDto> resolver(String id) async {
    resoluciones++;
    estado = 2;
    return detalle(id);
  }
}

List<Map<String, dynamic>> caracteristicasJson(int tipoMascota) => [
  {
    'campo': 'tamano',
    'nombre': 'Tamaño',
    'opciones': [
      {'id': 1, 'nombre': 'Chico'},
      {'id': 2, 'nombre': 'Mediano'},
      {'id': 3, 'nombre': 'Grande'},
    ],
  },
  if (tipoMascota != 3) ...[
    {
      'campo': 'raza',
      'nombre': 'Raza',
      'opciones': [
        {'id': 1, 'nombre': 'De raza'},
        {'id': 2, 'nombre': 'Mestizo'},
      ],
    },
    {
      'campo': 'pelaje',
      'nombre': 'Pelaje',
      'opciones': [
        {'id': 1, 'nombre': 'Corto'},
        {'id': 2, 'nombre': 'Medio'},
        {'id': 3, 'nombre': 'Largo'},
      ],
    },
    {
      'campo': 'colorOjos',
      'nombre': 'Color de ojos',
      'opciones': [
        {'id': 1, 'nombre': 'Oscuros'},
        {'id': 2, 'nombre': 'Claros'},
        {'id': 3, 'nombre': 'Diferentes'},
      ],
    },
  ],
  {
    'campo': 'colorPredominante',
    'nombre': 'Color predominante',
    'opciones': [
      {'id': 1, 'nombre': 'Negro'},
      {'id': 7, 'nombre': 'Mixto/Otro'},
    ],
  },
];

class RecomendacionServiceMock implements RecomendacionService {
  CrearRecomendacionRequest? creada;
  RecomendacionDto? mia;
  int creaciones = 0, retiros = 0;
  List<String> guardados = [];
  bool falloConsulta = false, falloCatalogo = false;
  int consultasPropias = 0;
  @override
  Future<PaginaDto<MascoteroRecomiendaDto>> recomendadores(
    String prestadorId, {
    int pagina = 1,
  }) async => PaginaDto(
    [
      MascoteroRecomiendaDto.fromJson({'nombre': 'Ana'}),
    ],
    1,
    pagina,
    20,
  );
  @override
  Future<List<RubroDto>> rubros() async => [
    RubroDto.fromJson({'id': 'rubro-1', 'nombre': 'Veterinaria'}),
  ];
  @override
  Future<List<AspectoDto>> aspectos() async {
    if (falloCatalogo) throw Exception('Catálogo no disponible');
    return [
      AspectoDto.fromJson({
        'id': 'a1',
        'nombre': 'Buena atención',
        'activo': true,
      }),
      AspectoDto.fromJson({
        'id': 'a2',
        'nombre': 'Responsabilidad',
        'activo': true,
      }),
    ];
  }

  @override
  Future<PaginaDto<PrestadorDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async => PaginaDto([await detalle('prestador-1')], 1, pagina, 20);
  @override
  Future<PrestadorDto> detalle(String id) async => PrestadorDto.fromJson({
    ...prestadorJson(),
    'totalRecomendaciones': mia == null ? 0 : 1,
    'aspectos': [
      for (final a in mia?.aspectos ?? <AspectoDto>[])
        {'id': a.id, 'nombre': a.nombre, 'cantidad': 1},
    ],
  });
  @override
  Future<RecomendacionDto?> miRecomendacion(String prestadorId) async {
    consultasPropias++;
    if (falloConsulta) throw Exception('Consulta no disponible');
    return mia;
  }

  @override
  Future<List<PrestadorDto>> similares({
    required String nombre,
    required String rubroId,
    required String localidadId,
  }) async => [await detalle('prestador-1')];
  @override
  Future<RecomendacionDto> crear(CrearRecomendacionRequest request) async {
    creada = request;
    creaciones++;
    return mia ??= RecomendacionDto.fromJson(recomendacionJson());
  }

  @override
  Future<RecomendacionDto> guardarAspectos(
    String id,
    List<String> aspectoIds,
  ) async {
    guardados = aspectoIds;
    mia = RecomendacionDto.fromJson({
      ...recomendacionJson(),
      'aspectos': [
        for (final a in await aspectos())
          if (aspectoIds.contains(a.id))
            {'id': a.id, 'nombre': a.nombre, 'activo': a.activo},
      ],
    });
    return mia!;
  }

  @override
  Future<void> retirar(String id) async {
    retiros++;
    mia = null;
  }
}
