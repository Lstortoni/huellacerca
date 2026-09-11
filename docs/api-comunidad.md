# API de identidad y recomendaciones

Base local: http://localhost:5080. Swagger: http://localhost:5080/swagger.

## Entidades y recorrido

- **Usuario**: email normalizado, hash de contraseña, estado y vínculo único a Mascotero.
- **Mascotero**: nombre, apellido, teléfono opcional, localidad y recomendaciones. Tiene navegación Usuario.
- **RefreshToken**: hash de una credencial aleatoria, usuario, sesión, vencimiento y revocación.
- **Rubro**: catálogo inicial cargado por migración.
- **PrestadorServicio**: negocio o persona recomendada, con rubro, ubicación, contacto opcional y mascotero creador.
- **Recomendacion**: experiencia escrita por un mascotero sobre un prestador.

Controllers reciben DTO y pasan la identidad autenticada al servicio. Servicios validan reglas y convierten a DTO. Repositorios consultan/guardan con EF Core. Las propiedades de navegación no se serializan como respuestas.

## Registro

`POST /api/auth/register`, sin autenticación:

```json
{
  "nombre": "Ana",
  "apellido": "Pérez",
  "email": "ana@example.com",
  "password": "UnaClaveLargaDeEjemplo!",
  "passwordConfirm": "UnaClaveLargaDeEjemplo!",
  "telefono": null,
  "localidadId": "REEMPLAZAR_CON_ID_DE_LOCALIDAD"
}
```

Nombre y apellido obligatorios. Contraseña de 8 a 128 caracteres; la confirmación debe coincidir. Elegir una localidad activa desde los endpoints de ubicación. Usuario, Mascotero y sesión se guardan con un único SaveChanges transaccional. Email único en base; un alta repetida devuelve 409, incluidos intentos simultáneos.

Devuelve **201** con `accessToken`, `expiresAtUtc`, `refreshToken`, `refreshExpiresAtUtc` y `usuario`. El perfil está en `usuario.mascotero`. El email comienza sin confirmar; todavía no se envían correos.

## Login y perfil

`POST /api/auth/login` con `email` y `password` devuelve los mismos campos de sesión. Credenciales incorrectas o usuario inactivo: 401.

`GET /api/auth/me` requiere:

```http
Authorization: Bearer ACCESS_TOKEN
```

En Swagger, copiar solo el accessToken al botón **Authorize**. No usar el refresh token en ese campo. Los errores de validación de DTO devuelven 400; errores de negocio usan ProblemDetails.

## Renovación y cierre

`POST /api/auth/refresh`:

```json
{ "refreshToken": "TOKEN_RECIBIDO_AL_INICIAR_SESION" }
```

No necesita un JWT válido. Verifica el hash almacenado, vencimiento, revocación y usuario activo. Devuelve un access token nuevo y un refresh nuevo; el anterior queda revocado. Si se vuelve a usar un refresh revocado, se revoca la sesión completa. Renovaciones simultáneas del mismo token no pueden generar dos renovaciones exitosas.

La sesión vence como máximo a los 30 días de su creación (configurable); renovar no desplaza ese vencimiento. Flutter deberá guardar los nuevos tokens y coordinar un único refresh cuando varias peticiones reciban 401.

`POST /api/auth/logout` recibe el mismo formato y devuelve 204, aunque el token sea desconocido. Quien posee el refresh puede cerrar esa sesión incluso con el JWT vencido. Los access tokens emitidos no se revocan individualmente y duran hasta 15 minutos; si el usuario pasa a inactivo, se bloquea el acceso mediante la validación adicional en la base.

Las contraseñas usan PasswordHasher de ASP.NET Core Identity. Los refresh se generan con un generador criptográfico y solo se guarda SHA-256 del valor; los JWT se firman con HS256 y se validan firma, algoritmo, emisor, audiencia y vencimiento.

## Rubros y prestadores similares

- `GET /api/rubros`: rubros activos.
- `GET /api/prestadores/similares?nombre=Los%20Tilos&rubroId=UUID&localidadId=UUID&limite=10`.
- `GET /api/prestadores/{id}`: datos de una ficha activa.

La búsqueda requiere nombre (2 a 150 caracteres), rubro y localidad activos. Ignora acentos y mayúsculas, combina coincidencia parcial con similitud de texto de PostgreSQL (pg_trgm), y devuelve como máximo 20 fichas ordenadas por similitud. Es una sugerencia, no una deduplicación garantizada.

El catálogo lo carga la comunidad: no es información verificada, no usa Google Places y permite nombres repetidos. Esta versión no expone edición ni eliminación de las fichas compartidas; las correcciones y moderación se definirán posteriormente.

## Crear una recomendación

`POST /api/recomendaciones`, con JWT. Elegir **una** de estas opciones:

### Prestador existente

```json
{
  "prestadorServicioId": "ID_ELEGIDO_EN_LA_BUSQUEDA",
  "titulo": "Buena atención",
  "descripcion": "Llevé a mi perro y explicaron con paciencia los cuidados."
}
```

### Prestador nuevo

```json
{
  "nuevoPrestador": {
    "nombre": "Veterinaria Los Tilos",
    "rubroId": "ID_DEL_RUBRO",
    "localidadId": "ID_DE_LOCALIDAD",
    "direccion": "Referencia o dirección opcional",
    "telefono": null,
    "enlace": "https://example.com"
  },
  "titulo": "Buena atención",
  "descripcion": "Llevé a mi perro y explicaron con paciencia los cuidados."
}
```

No enviar ambos campos. El prestador nuevo y la recomendación se guardan en una transacción. El autor sale del JWT, no del cuerpo de la petición. Título hasta 150 caracteres y experiencia de 10 a 3000. El enlace opcional solo admite HTTP/HTTPS; la API no visita esa URL.

Devuelve **201** y la URL del detalle. Se permiten varias experiencias del mismo mascotero, sin imponer unicidad por prestador.

## Consultar, editar y eliminar

- `GET /api/recomendaciones`: público y paginado.
- Filtros: `busqueda`, `rubroId`, `provinciaId`, `localidadId`, `mascoteroId`, `pagina` y `tamanoPagina`.
- `GET /api/recomendaciones/{id}`: detalle público.
- `PUT /api/recomendaciones/{id}`: solo autor; recibe `titulo` y `descripcion`.
- `DELETE /api/recomendaciones/{id}`: solo autor; elimina la recomendación, conserva el prestador y devuelve 204.

Las búsquedas se ordenan por fecha descendente e ID. Tamaño de página: 1 a 100, por defecto 20. La búsqueda en nombre del prestador ignora acentos; título y descripción ignoran mayúsculas. Otro autor recibe 403 al editar/eliminar; un ID inexistente devuelve 404. Ediciones concurrentes pueden devolver 409 para evitar sobrescribir silenciosamente.

No hay estrellas, comentarios ni me gusta en esta versión.
