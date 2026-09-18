# Publicaciones de mascotas: modelo inicial

Implementados: entidades, mapeo de EF Core, DTO, interfaces, repositorio, servicio y controller. Flutter ya incluye búsqueda, detalle, creación sin fotos y resolución exclusiva del autor. La carga de archivos queda para el siguiente bloque.

## Relaciones

- Un Mascotero crea muchas PublicacionesMascotas. Identifica al autor del aviso, no necesariamente al dueño del animal.
- Una PublicacionMascota tiene muchas Fotografias.
- La publicación tiene su propia Localidad; su provincia se obtiene mediante Localidad.Provincia. No duplica ProvinciaId ni utiliza obligatoriamente la localidad del perfil.

## Datos del aviso

PublicacionMascota guarda tipo Perdida/Encontrada/Adopcion/BuscoAdoptar, tipo de mascota Perro/Gato/Otro, nombre opcional, descripción, fecha del suceso, localidad, zona aproximada, información de contacto, fecha de creación UTC y estado Activa/Resuelta. Para ambos tipos de adopción se usa FechaCreacion, y Resuelta indica que el caso finalizó. Los avisos existentes de tipo 3 conservan su tipo; no se convierten automáticamente a BuscoAdoptar.

FechaSuceso es DateOnly? (PostgreSQL date nullable) porque describe el día indicado por la persona, sin hora ni conversión de zona horaria. Los enums se guardan como enteros explícitos con restricciones de valores en PostgreSQL.

FotoPublicacion guarda PublicacionMascotaId, RutaArchivo y Orden. Solo representa la referencia al archivo; no carga fotos ni elimina archivos físicos. El almacenamiento, validación de formato/tamaño y autorización se implementarán con el flujo de publicación.

## Persistencia

Tablas publicaciones_mascotas y fotos_publicaciones, incorporadas en la migración PublicacionesMascotas. EF configura claves foráneas, longitudes máximas e índices de localidad/estado/fecha y autor. No permite borrar una localidad o mascotero con publicaciones asociadas. El borrado físico de una publicación eliminaría sus filas de fotografías en cascada; marcarla Resuelta no borra nada.

El orden de fotografías no puede ser negativo ni repetirse dentro del mismo aviso. Las fotos son opcionales: una publicación puede tener cero fotografías, representadas como una colección vacía, no null. La creación actual no recibe archivos ni rutas y devuelve fotografias: [].

## Flujo de la API

PublicacionesController recibe el DTO y obtiene MascoteroId del JWT para crear o resolver. IPublicacionService se resuelve como PublicacionService en Program.cs. El servicio valida y utiliza IPublicacionRepository (PublicacionRepository), que persiste con AppDbContext/EF. El servicio transforma entidades en PublicacionDto y el controller devuelve JSON.

- POST /api/publicaciones: JWT, devuelve 201 y Location del detalle. Crea Activa, nombre opcional, descripción entre 10 y 3000 caracteres (sin contar espacios externos), contacto obligatorio y localidad activa. Zona opcional solo para BuscoAdoptar. Fecha del suceso obligatoria y no futura para tipos 1/2; para 3/4 se guarda null. Tipo 4 ignora el nombre del animal.
- GET /api/publicaciones: público, filtros opcionales por tipo de publicación, tipo de mascota, provincia, localidad, mascotero, zona (texto parcial sin distinguir mayúsculas), estado y fechas inclusivas: día del suceso para tipos 1/2 y día de publicación en Argentina para 3/4. Sin estado incluye activas y resueltas. Paginación: 20 por defecto, máximo 100; orden fecha de creación descendente e ID para desempatar.
- GET /api/publicaciones/{id}: público, incluye el contacto que el autor ingresó para el aviso; no expone email de la cuenta ni rutas internas de archivos. Inexistente: 404.
- PATCH /api/publicaciones/{id}/resolver: JWT, sin cuerpo. Solo el autor (otro mascotero recibe 403). Devuelve 200 con estado Resuelta. Repetir como autor conserva el resultado y no borra el aviso.

Valores JSON numéricos: tipoPublicacion 1=Perdida, 2=Encontrada, 3=Adopcion (Doy en adopción), 4=BuscoAdoptar; tipoMascota 1=Perro, 2=Gato, 3=Otro; estado 1=Activa, 2=Resuelta.

La migración 20260917230913_PublicacionesAdopcion, generada con EF en Docker, amplía la restricción de PostgreSQL para permitir el valor 3, conservando los anteriores. Reemplaza la versión manual pendiente y solo modifica esa restricción. Aplicar desde la raíz: `docker compose up -d --build huellacerca_api`. Compose reconstruye y ejecuta el servicio de migraciones antes de iniciar la API. Para revertir a la restricción anterior no pueden quedar filas de tipo 3.

Pruebas: docker compose run --rm --no-deps huellacerca_tests python /tests/test_publicaciones.py. Crea dos cuentas y cuatro avisos de prueba identificados por hc-pets-test-*; al terminar deja los avisos resueltos, sin borrar datos existentes. Ejemplos manuales en PruebasApi.md.

## Próximo bloque

Implementar almacenamiento y carga/consulta de imágenes opcionales, con validación de formato/tamaño y permisos. Edición, eliminación y reapertura de avisos no están incluidas en este bloque.

La migración BuscoAdoptarFechaOpcional habilita el tipo 4 y FechaSuceso nullable. Fue generada con EF y aplicada mediante Docker Compose; API reconstruida. Pruebas HTTP de los cuatro tipos aprobadas.
