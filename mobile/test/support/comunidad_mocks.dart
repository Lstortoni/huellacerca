import 'package:huella_cerca/models/pagina_dto.dart';
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
};
Map<String, dynamic> recomendacionJson() => {
  'id': 'recomendacion-1',
  'autor': 'Ana',
  'titulo': 'Buena atención',
  'descripcion': 'Nos atendieron con mucha paciencia.',
  'prestador': prestadorJson(),
};

class PublicacionServiceMock implements PublicacionService {
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

class RecomendacionServiceMock implements RecomendacionService {
  CrearRecomendacionRequest? creada;
  @override
  Future<List<RubroDto>> rubros() async => [
    RubroDto.fromJson({'id': 'rubro-1', 'nombre': 'Veterinaria'}),
  ];
  @override
  Future<PaginaDto<RecomendacionDto>> buscar({
    Map<String, String> filtros = const {},
    int pagina = 1,
  }) async => PaginaDto([await detalle('recomendacion-1')], 1, pagina, 20);
  @override
  Future<RecomendacionDto> detalle(String id) async =>
      RecomendacionDto.fromJson(recomendacionJson());
  @override
  Future<List<PrestadorDto>> similares({
    required String nombre,
    required String rubroId,
    required String localidadId,
  }) async => [PrestadorDto.fromJson(prestadorJson())];
  @override
  Future<RecomendacionDto> crear(CrearRecomendacionRequest request) async {
    creada = request;
    return detalle('recomendacion-1');
  }
}
