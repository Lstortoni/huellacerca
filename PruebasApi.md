# Pruebas manuales de la API — Huella Cerca

Base local: **http://localhost:5080**

Swagger: **http://localhost:5080/swagger**

Esta guía corresponde a los endpoints implementados actualmente. Los ejemplos son para Postman o Swagger. No se crearon las cuentas ni recomendaciones de estos ejemplos: las vas a crear al ejecutar las llamadas.

## Preparación

Desde la carpeta del proyecto, si la API está detenida:

```powershell
docker compose up -d
```

En Postman:

1. Elegí el método indicado: GET, POST, PUT o DELETE.
2. Pegá la URL completa.
3. Para enviar JSON: **Body → raw → JSON**. Esto agrega `Content-Type: application/json`.
4. En los endpoints públicos elegí **Authorization → No Auth**.
5. Los GET y DELETE de esta guía no llevan cuerpo.

### Datos reales del catálogo local

Consultados el 11/09/2026:

| Dato | ID |
| --- | --- |
| Provincia Buenos Aires | `17e0fcfd-bdf2-4b6a-987d-8c4b3192d3f6` |
| Localidad Lanus | `72d8db28-0357-4141-a29a-5596d92ecf4f` |
| Rubro Veterinaria | `10000000-0000-0000-0000-000000000001` |

Los JSON de esta guía ya usan esos IDs. Si recreás la base desde cero, los IDs de ubicación pueden cambiar: obtenelos nuevamente con las consultas de la sección 2. Reejecutar el importador sobre la misma base conserva los IDs.

### Cuándo hace falta un token

**Sin JWT:** registro, login, ubicación, rubros, búsqueda y detalle de prestadores, búsqueda y detalle de recomendaciones.

**Con JWT:** consultar mi perfil, crear, editar y eliminar recomendaciones.

**Refresh y logout:** no llevan JWT, pero sí el refresh token en el JSON.

Para un endpoint con JWT, en Postman seleccioná **Authorization → Bearer Token** y pegá el valor de `accessToken`, sin comillas. Postman genera:

```http
Authorization: Bearer TU_ACCESS_TOKEN
```

En Swagger, presioná **Authorize** y pegá solo el accessToken. No pegues el refresh token ahí. Aunque Swagger pueda mostrar candados generales, los requisitos efectivos son los que se indican por endpoint en esta guía.

Si todavía no querés probar endpoints con token, podés hacer registro, login y todas las consultas públicas. Las operaciones protegidas quedan identificadas para cuando quieras continuar.

### Orden sugerido

1. Comprobar salud y ubicación: secciones 0 y 2.
2. Registrar e iniciar sesión: sección 1, apartados a y b.
3. Guardar los tokens y probar el perfil: 1.c.
4. Consultar rubros y similares: 3.a y 3.b.
5. Crear una recomendación con prestador nuevo: 4.a.
6. Guardar sus IDs; probar detalle, prestador existente, filtros, edición y permisos.
7. Eliminar únicamente las recomendaciones de prueba.
8. Probar renovación y cierre de sesión **al final**: 1.d y 1.e.

## 0 — Estado de la API

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/health
```

**Esperado:** `200 OK`, texto `Healthy`. Comprueba que la API responde; no verifica por sí solo toda la base.

## 1 — AuthController

### a) Register — crear Usuario y Mascotero

**Método:** POST  
**Token:** No.

```text
http://localhost:5080/api/auth/register
```

**Body → raw → JSON:**

```json
{
  "nombre": "Leo",
  "apellido": "Storton",
  "email": "leo.prueba@com.ar",
  "password": "PruebaLocal2026!",
  "passwordConfirm": "PruebaLocal2026!",
  "telefono": "2214567894",
  "localidadId": "eab3d5f3-4ef6-43f4-8e34-f672c511eefd"
}

{
  "nombre": "Santino",
  "apellido": "stortoni",
  "email": "san.prueba@com.ar",
  "password": "PruebaLocal2026!",
  "passwordConfirm": "PruebaLocal2026!",
  "telefono": "2216188446",
  "localidadId": "eab3d5f3-4ef6-43f4-8e34-f672c511eefd"
}
{
  "nombre": "Cintia",
  "apellido": "Ornani",
  "email": "cin.prueba@com.ar",
  "password": "PruebaLocal2026!",
  "passwordConfirm": "PruebaLocal2026!",
  "telefono": "2216188446",
  "localidadId": "eab3d5f3-4ef6-43f4-8e34-f672c511eefd"
}
```

**Esperado:** `201 Created`. Se crean Usuario, Mascotero y sesión en una misma transacción.

Guardá estos valores de la respuesta:

| Campo de respuesta | Uso |
| --- | --- |
| `accessToken` | Llamadas protegidas. |
| `expiresAtUtc` | Vencimiento del JWT. |
| `refreshToken` | Renovar o cerrar esa sesión. |
| `refreshExpiresAtUtc` | Vencimiento máximo de esa sesión. |
| `usuario.id` | ID de Usuario. |
| `usuario.mascotero.id` | ID de Mascotero; es distinto del Usuario. |

El teléfono es opcional: puede enviarse como `null` u omitirse. El email comienza sin confirmar; todavía no enviamos correos.

**Pruebas de error:**

- Repetir el mismo registro: `409 Conflict`, email ya registrado.
- Cambiar solo `passwordConfirm` para que no coincida: `400 Bad Request`.
- Usar contraseña menor a 8 caracteres: `400 Bad Request`.
- Usar una localidad inexistente con **otro email**: `400 Bad Request`; no debe crearse la cuenta.

### b) Login — iniciar sesión

**Método:** POST  
**Token:** No.

```text
http://localhost:5080/api/auth/login
```

```json
{
  "email": "ana.prueba@example.invalid",
  "password": "PruebaLocal2026!"
}
```

**Esperado:** `200 OK`, con los mismos campos de sesión que devuelve el registro.

Usá el accessToken y el refreshToken de esta respuesta como pareja. Cada login crea una sesión independiente; no mezcles tokens de respuestas diferentes.

**Contraseña incorrecta:**

```json
{
  "email": "ana.prueba@example.invalid",
  "password": "UnaClaveIncorrecta"
}
```

**Esperado:** `401 Unauthorized`. Un usuario inactivo también recibe 401.

### c) Me — consultar mi perfil

**Método:** GET  
**Token:** **Sí, accessToken en Bearer Token.**  
**JSON:** No lleva.

```text
http://localhost:5080/api/auth/me
```

**Esperado:** `200 OK`, datos del Usuario y su Mascotero. Nunca devuelve PasswordHash.

**Sin token, con token vencido o inválido:** `401 Unauthorized`.

### d) Refresh — renovar sesión

**Método:** POST  
**JWT en Authorization:** No; seleccionar No Auth.  
**Credencial necesaria:** refreshToken vigente dentro del JSON.

```text
http://localhost:5080/api/auth/refresh
```

```json
{
  "refreshToken": "PEGAR_AQUI_EL_REFRESH_TOKEN_VIGENTE"
}
```

**Esperado:** `200 OK`, con un accessToken nuevo y un refreshToken nuevo.

**Reemplazá ambos tokens guardados por los de esta respuesta.** El refresh anterior ya no sirve. La fecha máxima de vencimiento de la sesión no se extiende al renovar.

Después podés repetir `GET /api/auth/me` con el nuevo accessToken.

**Prueba opcional de reutilización:** enviar de nuevo el refresh anterior devuelve `401` y revoca las renovaciones de esa sesión, incluido el refresh nuevo. Si hacés esta prueba, volvé a iniciar sesión para continuar.

No hace falta esperar a que venza el JWT para probar este endpoint.

### e) Logout — cerrar sesión

**Método:** POST  
**JWT en Authorization:** No; seleccionar No Auth.  
**Credencial necesaria:** refreshToken de la sesión que querés cerrar.

```text
http://localhost:5080/api/auth/logout
```

```json
{
  "refreshToken": "PEGAR_AQUI_EL_ULTIMO_REFRESH_TOKEN"
}
```

**Esperado:** `204 No Content`, sin cuerpo.

Si después intentás renovar con ese refresh, recibirás `401`. Un logout con un token desconocido que cumple el formato también devuelve 204.

**El JWT ya emitido puede seguir funcionando hasta su vencimiento.** Logout revoca la renovación; no elimina de inmediato ese JWT. La app deberá borrar ambos tokens al cerrar sesión.

## 2 — UbicacionController

### a) Países

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/paises
```

**Esperado:** `200 OK`, lista de países activos; actualmente Argentina, código `AR`.

### b) Provincias de Argentina

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/provincias?paisCodigo=AR
```

**Esperado:** `200 OK`, 24 jurisdicciones. Guardá el `id` de la provincia elegida. Si omitís paisCodigo, usa AR.

### c) Localidades de una provincia

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/localidades?provinciaId=17e0fcfd-bdf2-4b6a-987d-8c4b3192d3f6&pagina=1&tamanoPagina=20
```

**Esperado:** `200 OK`, objeto con `items`, `total`, `pagina` y `tamanoPagina`.

### d) Buscar Lanus

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/localidades?provinciaId=17e0fcfd-bdf2-4b6a-987d-8c4b3192d3f6&busqueda=lanus&pagina=1&tamanoPagina=20
```

**Esperado:** `200 OK`, con Lanus entre los resultados. La búsqueda ignora mayúsculas y acentos. Para el registro, copiar el `id` del elemento de `items`, no el provinciaId.

### e) Errores de consulta

Todos son **GET sin token ni cuerpo**:

| URL completa | Esperado |
| --- | --- |
| http://localhost:5080/api/localidades | 400: falta provinciaId. |
| http://localhost:5080/api/localidades?provinciaId=no-es-un-guid | 400: formato inválido. |
| http://localhost:5080/api/localidades?provinciaId=ffffffff-ffff-ffff-ffff-ffffffffffff | 404: provincia inexistente. |
| http://localhost:5080/api/localidades?provinciaId=17e0fcfd-bdf2-4b6a-987d-8c4b3192d3f6&tamanoPagina=101 | 400: máximo 100. |

Una búsqueda válida sin coincidencias devuelve **200 con lista vacía**, no 404.

## 3 — PrestadoresController

Prestador significa el negocio o persona recomendada. La recomendación es la experiencia que publica el mascotero sobre ese prestador.

### a) Rubros

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/rubros
```

**Esperado:** `200 OK`, los rubros activos. Veterinaria tiene ID `10000000-0000-0000-0000-000000000001`.

### b) Buscar prestadores similares

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/prestadores/similares?nombre=Veterinaria%20Los%20Tilos&rubroId=10000000-0000-0000-0000-000000000001&localidadId=72d8db28-0357-4141-a29a-5596d92ecf4f&limite=10
```

**Esperado:** `200 OK`, lista de fichas similares. Puede estar vacía si todavía nadie cargó ese lugar. El usuario puede elegir una ficha o crear otra al publicar su recomendación.

Nombre, rubro y localidad son necesarios; límite entre 1 y 20. Rubro/localidad inválidos o inactivos: 400.

Después de crear la recomendación de 4.a, repetí esta búsqueda para encontrar el prestador nuevo.

### c) Consultar un prestador

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/prestadores/PRESTADOR_ID
```

**Reemplazar PRESTADOR_ID** por el `id` de una ficha obtenida en similares o por `prestador.id` de una recomendación.

**Esperado:** `200 OK`, nombre, rubro, localidad y contacto. Un GUID inexistente devuelve 404.

No hay un POST separado para crear prestadores: se crean junto con una recomendación, como se muestra abajo.

## 4 — RecomendacionesController

### a) Crear recomendación con prestador nuevo

**Método:** POST  
**Token:** **Sí, accessToken en Bearer Token.**

```text
http://localhost:5080/api/recomendaciones
```

```json
{
  "nuevoPrestador": {
    "nombre": "Veterinaria Los Tilos - Prueba manual",
    "rubroId": "10000000-0000-0000-0000-000000000001",
    "localidadId": "72d8db28-0357-4141-a29a-5596d92ecf4f",
    "direccion": "Direccion de ejemplo, Lanus",
    "telefono": "1100000000",
    "enlace": "https://example.com"
  },
  "titulo": "Muy buena atencion - Prueba manual",
  "descripcion": "Lleve a mi perro y me explicaron con paciencia los cuidados. Esta es una recomendacion de prueba."
}
```

**Esperado:** `201 Created`. Crea el prestador y la recomendación juntos.

Guardá:

- `id` de la respuesta → **RECOMENDACION_ID**.
- `prestador.id` → **PRESTADOR_ID**.
- `mascoteroId` → autor, obtenido por la API desde la sesión.

No enviar UsuarioId ni MascoteroId en el JSON: el autor se determina por el token.

### b) Crear recomendación de un prestador existente

**Método:** POST  
**Token:** **Sí, accessToken en Bearer Token.**

```text
http://localhost:5080/api/recomendaciones
```

```json
{
  "prestadorServicioId": "REEMPLAZAR_CON_PRESTADOR_ID",
  "titulo": "Otra experiencia en el mismo lugar",
  "descripcion": "Volvi a consultar y la atencion fue muy buena. Esta es otra experiencia de prueba."
}
```

**Esperado:** `201 Created`, con otro ID de recomendación pero el mismo `prestador.id`.

**Enviar solo una opción:** `prestadorServicioId` o `nuevoPrestador`. Enviar ambos, o ninguno, devuelve 400. Crear un prestador con nombre parecido está permitido; no se bloquea por duplicado.

### c) Listar recomendaciones

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/recomendaciones?pagina=1&tamanoPagina=20
```

**Esperado:** `200 OK`, resultado paginado con recomendaciones más recientes primero.

### d) Buscar por texto, rubro y localidad

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/recomendaciones?busqueda=Tilos&rubroId=10000000-0000-0000-0000-000000000001&localidadId=72d8db28-0357-4141-a29a-5596d92ecf4f&pagina=1&tamanoPagina=20
```

**Esperado:** `200 OK`, recomendaciones que cumplan todos los filtros enviados.

También podés filtrar por provincia:

```text
http://localhost:5080/api/recomendaciones?provinciaId=17e0fcfd-bdf2-4b6a-987d-8c4b3192d3f6&pagina=1&tamanoPagina=20
```

O por autor, reemplazando **MASCOTERO_ID** por `usuario.mascotero.id` del registro/login:

```text
http://localhost:5080/api/recomendaciones?mascoteroId=MASCOTERO_ID&pagina=1&tamanoPagina=20
```

Estas consultas siguen siendo públicas. Filtrar por autor no exige su token.

### e) Detalle de una recomendación

**Método:** GET  
**Token:** No.  
**JSON:** No lleva.

```text
http://localhost:5080/api/recomendaciones/RECOMENDACION_ID
```

Reemplazá **RECOMENDACION_ID** por el ID de la recomendación, no por el del prestador.

**Esperado:** `200 OK`, experiencia, autor y ficha del prestador. Si no existe: 404.

### f) Editar mi recomendación

**Método:** PUT  
**Token:** **Sí, accessToken del autor.**

```text
http://localhost:5080/api/recomendaciones/RECOMENDACION_ID
```

```json
{
  "titulo": "Actualizo mi experiencia - Prueba manual",
  "descripcion": "La atencion fue buena y agrego mas detalles de mi visita. Este texto reemplaza la descripcion anterior."
}
```

**Esperado:** `200 OK`, recomendación actualizada y `fechaActualizacion` informada.

Solo cambia título y descripción. No modifica el prestador compartido ni el autor.

- Sin JWT: 401.
- Con JWT de otro mascotero: 403.
- Recomendación inexistente: 404.
- Si otra operación la modificó durante la actualización, puede devolver 409: volver a consultar.

### g) Eliminar mi recomendación

**Método:** DELETE  
**Token:** **Sí, accessToken del autor.**  
**JSON:** No lleva.

```text
http://localhost:5080/api/recomendaciones/RECOMENDACION_ID
```

**Esperado:** `204 No Content`, sin cuerpo.

Probar únicamente con el ID de tu recomendación de ejemplo. Después, consultar su detalle devuelve 404. El prestador permanece en el catálogo y las recomendaciones de otros no se eliminan.

### h) Probar permisos con otro usuario

Primero registrar una segunda cuenta en `POST http://localhost:5080/api/auth/register`, sin token:

```json
{
  "nombre": "Bruno",
  "apellido": "Gomez",
  "email": "bruno.prueba@example.invalid",
  "password": "PruebaLocal2026!",
  "passwordConfirm": "PruebaLocal2026!",
  "telefono": null,
  "localidadId": "72d8db28-0357-4141-a29a-5596d92ecf4f"
}
```

**Esperado:** 201. Si ya existe, iniciar sesión con ese email y contraseña usando 1.b.

Con el accessToken de Bruno:

1. Consultar una recomendación de Ana: GET de 4.e → **200**, es pública.
2. Intentar editarla: PUT de 4.f con su JSON → **403**.
3. Intentar eliminarla: DELETE de 4.g → **403**.
4. Crear otra recomendación para el mismo prestador: POST de 4.b → **201**, pertenece a Bruno.

Hacé esta prueba antes de eliminar la recomendación de Ana. Para editar o eliminar después, volvé a seleccionar el token del autor correspondiente.

## 5 - PublicacionesController

Base: `http://localhost:5080/api/publicaciones`.

Valores numéricos: `tipoPublicacion`: 1 Perdida, 2 Encontrada, 3 Doy en adopción, 4 Busco adoptar. `tipoMascota`: 1 Perro, 2 Gato, 3 Otro. `estado`: 1 Activa, 2 Resuelta.

### a) Crear una publicación sin fotos

**POST** `http://localhost:5080/api/publicaciones`

**Authorization:** Bearer Token, pegar el **accessToken** de login/registro (no el refreshToken).

Body → raw → JSON:

```json
{
  "tipoPublicacion": 1,
  "tipoMascota": 1,
  "nombreMascota": "Toby",
  "descripcion": "Perro marrón mediano con collar azul. Se perdió cerca de la plaza.",
  "fechaSuceso": "2026-09-15",
  "localidadId": "LOCALIDAD_ID",
  "zona": "Alrededores de la plaza principal",
  "informacionContacto": "Contactar por teléfono al 2215550000"
}
```

Reemplazá LOCALIDAD_ID por un ID obtenido en la consulta de localidades. FechaSuceso usa `AAAA-MM-DD` y no puede ser futura. NombreMascota puede ser null u omitirse. Las fotos son opcionales; todavía no se envían archivos en este endpoint.

**Esperado:** 201, encabezado Location con el detalle y JSON de la publicación. Guardá su `id` como PUBLICACION_ID. Devuelve `estado: 1`, `fotografias: []`, autor y nombres de localidad/provincia. No se envían MascoteroId, Estado ni FechaCreacion: los determina la API. El contacto ingresado será visible en las consultas públicas.

Para un aviso de mascota encontrada usar `tipoPublicacion: 2`.
Para dar en adopción usar `tipoPublicacion: 3`; para buscar adoptar, `4`. En ambos casos se omite `fechaSuceso`: la API devuelve null y se usa `fechaCreacion`. Buscar con `?tipoPublicacion=3` o `?tipoPublicacion=4`. Requiere la migración BuscoAdoptarFechaOpcional.

Ejemplo de Busco adoptar, con JWT y un LOCALIDAD_ID válido:

```json
{
  "tipoPublicacion": 4,
  "tipoMascota": 2,
  "descripcion": "Buscamos adoptar un gatito y darle un hogar.",
  "localidadId": "LOCALIDAD_ID",
  "informacionContacto": "Escribime a ana@example.com"
}
```

Para tipo 4, nombre y fecha no se utilizan; zona es opcional. El contacto sigue siendo obligatorio y público. Para tipos 1 y 2 se sigue exigiendo fecha no futura. Los filtros de fechas usan el día de publicación en Argentina para ambos tipos de adopción, y el día del suceso para perdidas/encontradas.

### b) Buscar publicaciones

**GET** `http://localhost:5080/api/publicaciones`

**Authorization:** No Auth. **Body:** ninguno.

Ejemplo de filtros (reemplazar LOCALIDAD_ID):

```text
http://localhost:5080/api/publicaciones?tipoPublicacion=1&tipoMascota=1&estado=1&localidadId=LOCALIDAD_ID&zona=plaza&fechaDesde=2026-09-01&fechaHasta=2026-09-16&pagina=1&tamanoPagina=20
```

Todos los filtros son opcionales. También acepta `provinciaId` y `mascoteroId`. Las fechas filtran el día del suceso, incluyendo ambos límites. Zona busca texto parcial sin distinguir mayúsculas. Sin filtro de estado devuelve activas y resueltas. Orden: creación más reciente primero. Tamaño máximo de página: 100.

**Esperado:** 200 con `items`, `total`, `pagina` y `tamanoPagina`. Sin coincidencias: `items: []` y `total: 0`.

### c) Consultar el detalle

**GET** `http://localhost:5080/api/publicaciones/PUBLICACION_ID`

**Authorization:** No Auth. **Body:** ninguno.

**Esperado:** 200 con la publicación, incluyendo su contacto. ID inexistente: 404.

### d) Marcar como resuelta

**PATCH** `http://localhost:5080/api/publicaciones/PUBLICACION_ID/resolver`

**Authorization:** Bearer Token con el accessToken del autor. **Body:** ninguno.

**Esperado:** 200 con `estado: 2`. No elimina la publicación. Repetir como autor devuelve 200 y conserva Resuelta.

### e) Validaciones y permisos

- Crear o resolver sin token: **401**.
- Resolver usando el token de otro mascotero: **403**, sin modificar el aviso.
- Resolver un ID inexistente con token válido: **404**.
- Crear con fecha futura, localidad inexistente, descripción menor a 10 caracteres útiles, zona/contacto vacíos o tipos fuera de los valores indicados: **400**.
- Buscar con `pagina=0`, `tamanoPagina=101` o fechaDesde posterior a fechaHasta: **400**.

## Resumen de respuestas

| Código | Significado en estas pruebas |
| --- | --- |
| 200 | Consulta u operación correcta con respuesta. |
| 201 | Registro, recomendación o publicación creados. |
| 204 | Operación correcta sin cuerpo: logout o eliminación. |
| 400 | JSON, parámetros o datos inválidos. |
| 401 | Credenciales/token inválidos, vencidos o ausentes; refresh no renovable. |
| 403 | Usuario autenticado que no es el autor del contenido que intenta modificar. |
| 404 | Recurso inexistente o no disponible. |
| 409 | Email repetido o conflicto de actualización. |
| 429 | Límite de autenticación: esperar; actualmente 60 solicitudes por minuto por IP. |

Los nombres en MAYÚSCULAS como PRESTADOR_ID son marcadores para reemplazar. Los tokens son personales: no se incluyen tokens reales en este archivo. Si vence el JWT durante las pruebas (15 minutos), renová como en 1.d o volvé a iniciar sesión.
