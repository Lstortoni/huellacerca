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

**Sin JWT:** registro, login, ubicación, rubros, catálogo de aspectos, búsqueda y detalle de prestadores.

**Con JWT:** consultar mi perfil, consultar mis recomendaciones, recomendar, modificar aspectos y retirar recomendaciones.

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

Un prestador es el negocio o persona recomendada. Una recomendación significa que un mascotero recomienda esa ficha. No tiene título, comentario libre ni estrellas.

### a) Listar rubros

**GET** `http://localhost:5080/api/rubros`

**JWT en Authorization:** No; seleccionar No Auth. **Body:** ninguno.

Esperado: `200`, lista de rubros con `id` y `nombre`.

### b) Buscar prestadores similares

**GET**, sin JWT y sin body:

```text
http://localhost:5080/api/prestadores/similares?nombre=Veterinaria%20Los%20Tilos&rubroId=10000000-0000-0000-0000-000000000001&localidadId=LOCALIDAD_ID&limite=10
```

Reemplazar LOCALIDAD_ID por una localidad de las consultas de ubicación.
Esperado: `200`, lista de fichas similares, posiblemente vacía. Cada ficha incluye `totalRecomendaciones` y `aspectos` con sus cantidades.

Puede haber varias fichas del mismo negocio real. La búsqueda ayuda a reconocerlo, pero no garantiza detectar duplicados ni bloquea nombres similares.

### c) Consultar un prestador

**GET** `http://localhost:5080/api/prestadores/PRESTADOR_ID`

**JWT:** No. **Body:** ninguno.

Esperado: `200`, nombre, rubro, localidad, contacto, total de personas que recomiendan y aspectos agregados. PRESTADOR_ID es `prestador.id` de 4.a.

### d) Buscar servicios recomendados

**GET**, sin JWT y sin body:

```text
http://localhost:5080/api/prestadores?pagina=1&tamanoPagina=20
http://localhost:5080/api/prestadores?busqueda=Tilos&rubroId=10000000-0000-0000-0000-000000000001&localidadId=LOCALIDAD_ID&pagina=1&tamanoPagina=20
```

Filtros opcionales: `busqueda` (nombre), `rubroId`, `provinciaId`, `localidadId`.
Esperado: `200`, `items`, `total`, `pagina`, `tamanoPagina`.
Una fila por ficha de prestador, ordenadas por cantidad de recomendaciones y nombre.
Solo aparecen fichas con al menos una recomendación. Si se retiran todas, la ficha deja de aparecer en este listado; sigue disponible en similares para volver a recomendarla sin crear otra.

### e) Catálogo de aspectos positivos

**GET** `http://localhost:5080/api/aspectos-recomendacion`

**JWT:** No. **Body:** ninguno.

Esperado: `200`, aspectos activos con `id`, `nombre`, `activo`.
Iniciales: Buena atención, Responsabilidad, Cumplimiento, Buen trato con la mascota, Rapidez y Buena comunicación.
Los usuarios seleccionan estos IDs; no crean textos propios.

### f) Personas que recomiendan un prestador

**GET** `http://localhost:5080/api/prestadores/PRESTADOR_ID/recomendadores?pagina=1&tamanoPagina=20`

**JWT:** No; seleccionar No Auth. **Body:** ninguno.

Esperado: `200`, página con `items: [{ "nombre": "Leo" }]`, `total`, `pagina` y `tamanoPagina`. Incluye a quienes recomendaron sin seleccionar aspectos. Expone únicamente el nombre, sin apellido, email, teléfono ni identificadores de cuenta.
Un prestador inexistente devuelve `404`. Página menor a 1 o tamaño fuera de 1–100 devuelve `400`.

En la app, **Servicios recomendados** utiliza estas consultas públicas y muestra una ficha de solo lectura. Las acciones para recomendar y administrar aspectos se acceden desde **Recomendar un servicio**.

## 4 — RecomendacionesController

En todos los endpoints de esta sección: **Authorization → Bearer Token → accessToken** obtenido del registro/login. No enviar el refreshToken.
En POST/PUT: **Body → raw → JSON**.

### a) Crear un prestador y recomendarlo

**POST** `http://localhost:5080/api/recomendaciones`

```json
{
  "nuevoPrestador": {
    "nombre": "Veterinaria Los Tilos",
    "rubroId": "10000000-0000-0000-0000-000000000001",
    "localidadId": "REEMPLAZAR_CON_LOCALIDAD_ID",
    "direccion": "Calle 12 entre 50 y 51",
    "telefono": "2215551234",
    "enlace": "https://example.com"
  }
}
```

Dirección, teléfono y enlace son opcionales. El enlace debe ser HTTP/HTTPS.
Esperado: `201 Created`. Prestador y recomendación se guardan juntos. La recomendación **ya es válida sin aspectos**.

Guardar:
- `id` → RECOMENDACION_ID.
- `prestador.id` → PRESTADOR_ID.

La respuesta incluye `aspectos: []` y `prestador.totalRecomendaciones: 1`.
No enviar `titulo` ni `descripcion`: esos campos antiguos devuelven `400`.

### b) Recomendar un prestador existente

**POST** `http://localhost:5080/api/recomendaciones`

```json
{
  "prestadorServicioId": "REEMPLAZAR_CON_PRESTADOR_ID"
}
```

- Si ese mascotero aún no recomienda la ficha: `201`.
- Si ya la recomienda: `200`, devuelve la misma recomendación y conserva sus aspectos.
- Nunca suma dos votos del mismo mascotero para el mismo PRESTADOR_ID.
- Enviar solo `prestadorServicioId` o `nuevoPrestador`; ambos o ninguno → `400`.

Crear otra ficha con otro ID y nombre similar sigue permitido.

### c) Consultar mis recomendaciones

**GET**, sin body:

```text
http://localhost:5080/api/recomendaciones/mias?pagina=1&tamanoPagina=20
http://localhost:5080/api/recomendaciones/mias?prestadorServicioId=PRESTADOR_ID
```

Esperado: `200`, página de recomendaciones del mascotero identificado por el JWT.
La segunda consulta devuelve cero o una, y permite mostrar “Ya lo recomendás”.
No se puede elegir otro autor mediante `mascoteroId`.

La búsqueda pública se realiza con `GET /api/prestadores`; el antiguo `GET /api/recomendaciones` ya no se usa.

### d) Consultar mi recomendación por ID

**GET** `http://localhost:5080/api/recomendaciones/RECOMENDACION_ID`

**Body:** ninguno. Esperado: `200`, recomendación con prestador y aspectos seleccionados.
Otro autor → `403`; inexistente → `404`; sin JWT → `401`.
La ficha pública sigue disponible en `GET /api/prestadores/PRESTADOR_ID`.

### e) Guardar o modificar aspectos

**PUT** `http://localhost:5080/api/recomendaciones/RECOMENDACION_ID/aspectos`

```json
{
  "aspectoIds": [
    "20000000-0000-0000-0000-000000000001",
    "20000000-0000-0000-0000-000000000002"
  ]
}
```

Esperado: `200`, recomendación actualizada.
La lista **reemplaza** la selección anterior; IDs repetidos cuentan una sola vez.
IDs inexistentes o inactivos no seleccionados previamente → `400`.
Un aspecto desactivado ya elegido puede conservarse o quitarse.
Otro autor → `403`; cambios simultáneos en conflicto → `409`, volver a consultar.

Para quitar todos los aspectos y **conservar el voto**:

```json
{
  "aspectoIds": []
}
```

No enviar `null`. El antiguo PUT con título y descripción no se usa.

### f) Retirar mi recomendación

**DELETE** `http://localhost:5080/api/recomendaciones/RECOMENDACION_ID`

**Body:** ninguno. Esperado: `204 No Content`.
Elimina esa recomendación y sus aspectos. Recalcula los totales; no elimina el prestador ni votos ajenos.

### g) Prueba de conteos y permisos

1. Con Ana, crear un prestador (4.a): total 1, sin aspectos.
2. Repetir 4.b con Ana: `200`, mismo ID, total sigue en 1.
3. Guardar Buena atención y Responsabilidad (4.e).
4. Registrar/iniciar sesión con otra cuenta (Bruno); guardar su accessToken.
5. Con Bruno, consultar o editar la recomendación de Ana → `403`; eliminarla → `403`.
6. Con Bruno, recomendar el mismo PRESTADOR_ID (4.b) → `201`, total 2 aunque Bruno no seleccione aspectos.
7. Consultar la ficha pública (3.c): total 2; Buena atención 1 y Responsabilidad 1.
8. Bruno selecciona Buena atención: ese aspecto sube a 2.
9. Ana envía `aspectoIds: []`: total de personas sigue en 2; Buena atención baja a 1.
10. Retirar únicamente los votos de prueba con el token de cada autor (4.f).

## 5 - PublicacionesController

Base: `http://localhost:5080/api/publicaciones`.

Valores numéricos: `tipoPublicacion`: 1 Perdida, 2 Encontrada, 3 Doy en adopción, 4 Busco adoptar. `tipoMascota`: 1 Perro, 2 Gato, 3 Otro. `estado`: 1 Activa, 2 Resuelta.

### a) Crear una publicación sin fotos

Los nuevos campos `tamano`, `raza`, `pelaje`, `colorPredominante` y `colorOjos` son opcionales. Omitirlos o enviar `null` significa **No sé / Sin indicar**. No usar `0`.

Consultá primero las opciones (GET público, No Auth, sin body):

```text
http://localhost:5080/api/publicaciones/caracteristicas?tipoMascota=1
```

`tipoMascota`: 1 perro, 2 gato, 3 otro; por defecto 1. Responde una lista con `campo`, `nombre` y `opciones` (`id`, `nombre`). Para perros/gatos devuelve cinco campos; para Otro, solo tamaño y color predominante. Tipo inexistente devuelve 400.

| Campo | Valores |
|---|---|
| tamano | 1 Chico, 2 Mediano, 3 Grande |
| raza | 1 De raza, 2 Mestizo |
| pelaje | 1 Corto, 2 Medio, 3 Largo |
| colorPredominante | 1 Negro, 2 Blanco, 3 Marrón, 4 Gris, 5 Beige, 6 Naranja, 7 Mixto/Otro |
| colorOjos | 1 Oscuros, 2 Claros, 3 Diferentes |

Ejemplo completo con características: **POST** `http://localhost:5080/api/publicaciones`, **Bearer accessToken**, body raw JSON. Reemplazar LOCALIDAD_ID por un ID real:

```json
{
  "tipoPublicacion": 1,
  "tipoMascota": 1,
  "descripcion": "Perro mediano de pelaje corto, marrón, con collar azul.",
  "fechaSuceso": "2026-09-19",
  "localidadId": "REEMPLAZAR_CON_LOCALIDAD_ID",
  "zona": "Cerca de la plaza",
  "informacionContacto": "2215551234",
  "tamano": 2,
  "raza": 2,
  "pelaje": 1,
  "colorPredominante": 3,
  "colorOjos": null
}
```

Esperado: 201. Detalle, listado y resolución devuelven también estos cinco campos. Probar sin ellos y con null: ambos válidos. Valores fuera del catálogo (por ejemplo `raza: 3`) devuelven 400. Con `tipoMascota: 3`, raza/pelaje/colorOjos deben omitirse o ser null; enviarlos devuelve 400. Flutter ya permite seleccionarlos en el formulario de los cuatro tipos de aviso. El detalle Flutter muestra sus etiquetas y la búsqueda permite filtrarlas.

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

**Esperado:** 201, encabezado Location con el detalle y JSON de la publicación. Guardá su `id` como PUBLICACION_ID. Devuelve `estado: 1`, `foto: null`, autor y nombres de localidad/provincia. No se envían MascoteroId, Estado ni FechaCreacion: los determina la API. El contacto ingresado será visible en las consultas públicas.

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

Filtros opcionales nuevos: `tamano`, `raza`, `pelaje`, `colorPredominante`, `colorOjos`, con los mismos IDs que en creación. GET público, sin JWT ni body:

```text
http://localhost:5080/api/publicaciones?tipoMascota=1&tamano=2&raza=2&estado=1&pagina=1&tamanoPagina=20
```

Devuelve perros medianos y mestizos activos. Los filtros se combinan entre sí y con ubicación, fechas y tipo de publicación. Un aviso con tamaño null no satisface `tamano=2`. Sin filtros de características, los avisos sin esos datos siguen incluidos. Para quitarlos, omitir el parámetro, no enviar cero. `raza=99` o `tipoMascota=3&raza=1` devuelven 400. Esto es búsqueda exacta, no detección de posibles coincidencias.

### Posibles coincidencias de un aviso propio

`GET http://localhost:5080/api/publicaciones/{{publicacionId}}/coincidencias?pagina=1&tamanoPagina=5`

Authorization: Bearer Token con el accessToken del autor. Sin body. Devuelve 200 con `items` (cada uno tiene `publicacion` y `coincideEn`), `total`, `pagina`, `tamanoPagina`. Sin JWT: 401; otro autor: 403. Máximo 20 resultados por página.

Prueba adopción: crear un aviso tipo 4 (BuscoAdoptar) y otro tipo 3 (Adopcion) con `tipoMascota: 1`, la misma `localidadId`, `raza: 2` y `colorPredominante: 1`. No necesitan `fechaSuceso`. Consultar coincidencias de cualquiera con su autor: el otro debe aparecer. Una sola característica coincidente alcanza, aunque otra difiera. Tipos 1/2 no aparecen en este cruce. Al resolver un candidato deja de aparecer.

Para tipos 1/2 se conserva el cruce extraviada/encontrada y el margen de fechas del hallazgo (-3 a +30 días respecto del extravío). Ambos cruces exigen misma especie/localidad y candidatos activos.

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

## Fotos de publicaciones (R2)

Configuración del bucket y variables: [docs/fotos-r2.md](docs/fotos-r2.md).

**Subir o reemplazar:** `PUT http://localhost:5080/api/publicaciones/PUBLICACION_ID/foto`

Authorization → Bearer Token → accessToken del autor. Body → form-data → clave `archivo`, cambiar su tipo de Text a File y elegir una sola imagen JPEG, PNG o WebP (hasta 10 MiB). No usar raw JSON ni fijar Content-Type manualmente: Postman agrega el boundary multipart.

Esperado: 200 con `{ "id": "ID_FOTO", "url": "api/publicaciones/PUBLICACION_ID/foto?v=ID_FOTO" }`. Repetir reemplaza la foto, no agrega una segunda. La API la optimiza a WebP de hasta 250 KiB. Sin R2 configurado devuelve 503; el aviso sigue creado y puede reintentarse este PUT.

**Ver:** `GET http://localhost:5080/api/publicaciones/PUBLICACION_ID/foto`. No Auth, sin body. Devuelve bytes image/webp; se puede abrir en un navegador. Sin foto devuelve 404. El GET del detalle/listado ahora incluye `foto: null` o el objeto anterior, en lugar de `fotografias: []`.

**Eliminar:** `DELETE http://localhost:5080/api/publicaciones/PUBLICACION_ID/foto`. Bearer del autor, sin body, devuelve 204. Solo elimina la foto, conserva el aviso. El archivo R2 se limpia en segundo plano.

Validar: sin JWT al modificar → 401; otro autor → 403; formato corrupto/no admitido → 400; archivo >10 MiB → 413; reemplazos simultáneos → uno puede devolver 409 y se debe recargar el detalle; límite de subidas → 429 (15 por minuto por usuario).

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
